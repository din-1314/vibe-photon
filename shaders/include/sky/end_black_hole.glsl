// Where the black hole is (documented, not assumed):
//
// The black hole sits at the compass direction / elevation chosen in the
// options (END_BLACK_HOLE_AZIMUTH / END_BLACK_HOLE_ELEVATION), see
// end_black_hole_direction() below. Photon's End sun is the light source that
// gets lensed into the bright ring around it, so sky.glsl draws the sun (and
// the Mie glow around it) at that same direction instead of at `sun_dir`,
// which the Iris/OptiFine `sunPosition` uniform pins near the zenith in the
// End (the End has a fixed time of day). Lighting on the terrain is not
// affected: it keeps using `sun_dir` / `light_dir` like the rest of the pack.

#if !defined INCLUDE_SKY_END_BLACK_HOLE
#define INCLUDE_SKY_END_BLACK_HOLE

// Self-contained include. Everything this file calls is pulled in explicitly
// instead of relying on whichever program happens to include it:
//   - get_rotation_matrix() (rotation.glsl) is normally only reached
//     transitively via pcss.glsl in program/d4_deferred_shading.fsh, and
//     program/d0_sky_map.fsh (which also compiles this file's WORLD_END branch
//     of draw_sky(), even though it never calls draw_end_black_hole() at
//     runtime) does not include it anywhere else.
//   - hash1() (random.glsl) is used by the disc noise.
//   - blackbody() (color.glsl) is used for the disc colours.
// All of these have include guards, so repeating them is free.
#include "/include/sky/end_sky_common.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/rotation.glsl"

// Photon's own star field primitives (stable_star_field()); see
// bh_draw_lensed_stars() below
#include "/include/sky/stars.glsl"

/*
--------------------------------------------------------------------------------

  include/sky/end_black_hole:
  Black hole with accretion disc, drawn in place of the vanilla End sky
  background.

  Ported and adapted from IterationT's "BlackHole_AccretionDisc_Stars" effect
  (shaders/Lib/IndividualFounctions/EndSky.glsl) to Photon's own pipeline and
  math utilities (blackbody(), get_rotation_matrix(), hash1(), ...) instead of
  copying IterationT's systems wholesale.

  IterationT's "PlanetEnd2" ringed-planet effect is deliberately NOT ported.
  The optional planet (include/sky/end_planet.glsl) is a small original
  procedural one, written for this pipeline.

  Usage: call draw_end_black_hole() with the camera ray direction and the
  light direction. It gravitationally lenses `ray_dir` in place (so the
  caller can sample stars/sun using the bent direction) and returns how much
  the accretion disc occludes the background plus the disc's own emitted
  light, so the caller stays in full control of how the background
  (Photon's existing star field and sun) is combined with the black hole -
  no separate/duplicate star system is introduced.

--------------------------------------------------------------------------------
*/

float bh_pcurve(float x) {
    float x2 = x * x;
    return 12.207 * x2 * x2 * (1.0 - x);
}

// ---------------------------------------------------------------------------
// V2 geometry
//
// Everything below is expressed in "black hole local units", the same units
// the V1 disc shading was tuned in (disc peak ~ r = 1.9, inner edge r = 0.5).
// SIZE never changes those units. It moves the camera (and scales gravity with
// it), so making the black hole bigger looks like getting closer to the same
// object rather than blowing up its brightness.
// ---------------------------------------------------------------------------

// How large SIZE = 1.0 looks compared to V1's SIZE = 1.0 (angular scale).
const float BH_PRESENCE = 1.75;
// SIZE is applied as SIZE^BH_SIZE_EXPONENT: slightly below linear so the top of
// the slider approaches the black hole gradually instead of instantly
// swallowing the whole sky.
const float BH_SIZE_EXPONENT = 0.8;
// V1's camera distance at SIZE = 1.0. Camera distance = this / apparent scale.
const float BH_CAMERA_DISTANCE = 8.0;
// The camera never gets closer than this, so it can't end up inside the disc.
const float BH_MIN_CAMERA_DISTANCE = 2.0;
// Gravitational pull per unit length at apparent scale 1.0. This is what V1
// effectively used (0.06 per 0.2 long step) at SIZE = 1.0.
const float BH_GRAVITY = 0.3;
// Event horizon radius: light that gets closer than this never comes back.
const float BH_HORIZON = 0.42;
// Rays are only marched inside this radius (the accretion disc has faded to
// nothing well before it); the bending outside is added analytically. Rays that
// never enter it skip the march entirely.
const float BH_BOUND = 6.0;
// V1 divided the accumulated glow by the step count (rcp_steps = 1/40 at the
// default quality). The glow is now integrated per unit length instead, so
// this constant reproduces V1's brightness at the default quality while
// making it independent of STEPS and SIZE.
const float BH_GLOW_NORMALIZATION = 0.025;
// HDR emission of the accretion disc (v0.3).
//
// Against the near-black Cinematic Void the V2 disc read as a pale cyan ring
// with no glow: its brightest texels peaked at a luminance of ~5, below
// tonemap_lottes' white point (8) in every channel but blue, so nothing
// reached white and Photon's bloom had little energy to spread. Photon's
// bloom has no threshold, so the halo it draws is directly proportional to
// the HDR light it receives: the disc's emission is raised here, and the
// existing bloom and tonemap turn it into a white-hot core with a glow around
// it. (Peak ~55 at the default settings; Disc Brightness still scales it.)
// This only changes the light the disc emits: its shape, opacity, the lensing
// and the event horizon are untouched. (v0.3.1: 6 -> 8)
const float BH_DISC_EMISSION_GAIN = 8.0;
// Hottest colour temperature the disc is drawn with. The disc's temperature
// follows its brightness (2700 K + 50 K per unit of glow strength), which put
// its inner edge near 27000 K: a saturated cyan-blue that, even with more
// energy, would make a blue ring and a blue halo. Capping it keeps the whole
// orange-to-white gradient of the outer disc and makes the innermost, hottest
// matter white with a slight cool tint. (v0.3.1: 10000 K -> 8000 K, so the
// white core and the glow around it read as white rather than blue.)
const float BH_DISC_MAX_TEMPERATURE = 8000.0;
// Glow of the hot inner flow spreading into the space around the hole
// (v0.3.1).
//
// Raising the disc's emission alone cannot make its light spill into the
// surrounding space: Photon's bloom has a fixed spatial footprint, so more
// energy makes it brighter but not wider, and because the shadow is ringed by
// the disc on every side the extra bloom mostly piles up inside the shadow.
// IterationT's black hole gets its blinding look from light that exists in the
// sky itself: a soft volumetric glow around the hole ("bloomDisc"), falling off
// with the 3.5th power of the distance, integrated along the ray. It is ported
// here as part of the same raymarch (same stratified sample, same
// transmittance), so it is lensed, hidden behind the thick disc and occluded
// by the planet exactly like the disc, and costs a few ALU per step.
//
// One deliberate difference: the glow is only kept on rays that escape
// (multiplied by the horizon visibility). The glow lying in front of the
// shadow would otherwise fill the whole shadow with a flat grey; this way the
// shadow is only lit by Photon's bloom, as an eye or a camera would see it,
// and stays clearly darker than the emission around it.
const float BH_HALO_INTENSITY = 0.15; // per unit length, relative to glow units
// Broad halo: weak light spreading several black hole radii into the
// surrounding space (v0.3.3).
//
// The near halo above falls off with the 3.5th power of the distance, so it
// ends about one shadow radius away, and Photon's bloom has a fixed spatial
// footprint: neither makes the light reach far into the sky. Measured on the
// references, IterationT's sky stays lit several hundred pixels away from its
// black hole (display values 52/41/27/18 at 250/300/400/500 px against 32/21/
// 12/8 for v0.3.2), in a nearly neutral grey.
//
// This component is analytic: it only depends on how far the view ray passes
// from the black hole, measured as the angle between the ray and the black
// hole's direction converted to black hole local units (cam_dist * angle), so
// it follows the Size option and costs a handful of ALU per pixel, with no
// extra raymarch. Its falloff, 1 / (1 + (b / R)^2)^4, is fitted to the
// reference profile at the Concept's own black hole size: strong right around
// the disc, then a long soft tail that is gone before the sky turns into fog.
// It does not depend on the raymarch step count or on the per-frame dither,
// so it is identical at every Quality and perfectly still in time.
//
// It is not drawn over the shadow (see broad_visibility), and it is not
// scaled by Disc Brightness: END_BLACK_HOLE_BROAD_HALO is its own control.
const float BH_BROAD_HALO_INTENSITY = 0.16;
const float BH_BROAD_HALO_RADIUS = 3.5; // black hole local units (shadow edge ~1.1)
// Nearly neutral, slightly cool grey (linear Rec. 709, unit luminance),
// instead of blackbody(): Photon's three-wavelength blackbody reads cyan on
// screen at these temperatures (8000 K displays as ~0.37 0.76 1.00).
const vec3 BH_BROAD_HALO_COLOR
    = (vec3(0.85, 0.90, 1.00) / 0.8966) * rec709_to_working_color;
// Rays that end inside the opaque disc cannot tell by themselves whether they
// would have fallen into the hole. For the broad halo they are classified by
// their straight continuation from the exit point: a closest approach below
// this radius counts as falling in. Deterministic (it does not flip with the
// dither like the capture flag does) and fitted to the geometric shadow the
// same rays have with the disc removed.
const float BH_BROAD_HALO_SHADOW_CUTOFF = 2.0 * BH_HORIZON;
// Stars in strongly lensed parts of the sky are magnified: this many times more
// of Photon's star field becomes visible there (at full lensing strength), and
// they get brighter with the magnification.
const float BH_LENSED_STAR_DENSITY = 9.0;
const float BH_LENSED_STAR_BRIGHTNESS = 0.5;
// Lensing stretches point sources into arcs running around the black hole.
// Half-length of those arcs (radians) at full lensing strength, and how many
// samples are used to draw them.
const float BH_LENSED_STAR_ARC = 0.012;
const int BH_LENSED_STAR_ARC_SAMPLES = 6;
// Radius of the circle the disc noise is wrapped around in the azimuthal
// direction: larger = finer streaks around the disc, smaller = longer ones.
const float BH_DISC_SWIRL_RADIUS = 0.6;
// Roll of the accretion disc around the line of sight (radians), so it
// doesn't sit perfectly level with the horizon
const float BH_DISC_ROLL = -0.14;
// V1 marched with steps of this length at SIZE = 1.0; per-step opacity and
// bloom were tuned for it.
const float BH_REFERENCE_STEP = 0.2;

// Direction of the black hole in the sky, from the compass direction and
// elevation options
vec3 end_black_hole_direction() {
    return end_sky_direction(
        float(END_BLACK_HOLE_AZIMUTH),
        float(END_BLACK_HOLE_ELEVATION)
    );
}

// Gravitational bending accumulated by a straight ray travelling along `d`
// from position `p0` to position `p1` (closed-form integral of the 1/r^2
// pull). `p1_at_infinity` integrates all the way out instead.
void bh_bend_segment(inout vec3 d, vec3 p0, vec3 p1, bool p1_at_infinity, float gravity) {
    float s0 = dot(p0, d); // signed distance past the closest approach
    vec3 impact = p0 - d * s0;
    float b2 = dot(impact, impact);
    if (b2 < 1e-6) return;

    float f0 = s0 * inversesqrt(b2 + s0 * s0);
    float s1 = dot(p1, d);
    float f1 = p1_at_infinity ? 1.0 : s1 * inversesqrt(b2 + s1 * s1);
    d = normalize(d - impact * (gravity * (f1 - f0) / b2));
}

// Remaining bending for a straight ray that continues from `p` along `d` out
// to infinity
void bh_bend_tail(inout vec3 d, vec3 p, float gravity) {
    bh_bend_segment(d, p, p, true, gravity);
}

// Raymarches the gravitational field and accretion disc of the End black
// hole.
//
// ray_dir (inout): camera ray direction in; final gravitationally-lensed
//                   direction out. The caller should use the returned
//                   direction to sample the background (stars/sun) so that
//                   the lensing bends the existing background instead of
//                   introducing a second star field.
// background_transmittance (out): how much the black hole (event horizon and
//                   accretion disc) occludes whatever lies behind it: multiply
//                   the background (sky/stars/sun) by this before adding it.
//                   It is exactly 0 for rays that fall into the horizon.
// disc_glow (out):  the accretion disc's own emitted light (additive).
// lens_magnification (out): how much the lensing magnifies the background
//                   along this ray (>= 1). Used to reveal/brighten stars.
// lens_strength (out): 0..1, how strongly this ray was bent. 0 far from the
//                   black hole, so the star field is left untouched there.
void draw_end_black_hole(
    inout vec3 ray_dir,
    out float background_transmittance,
    out vec3 disc_glow,
    out float lens_magnification,
    out float lens_strength,
    vec3 light_dir,
    float dither
) {
    const int steps = END_BLACK_HOLE_STEPS;

    const float disc_radius = 2.25;
    const float disc_width = 3.5;
    const float disc_inner = disc_radius - disc_width * 0.5;

    float apparent_scale
        = pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE;
    float cam_dist
        = max(BH_CAMERA_DISTANCE / apparent_scale, BH_MIN_CAMERA_DISTANCE);
    float zoom = BH_CAMERA_DISTANCE / cam_dist;
    float gravity = BH_GRAVITY * zoom * END_BLACK_HOLE_WARP_STRENGTH;
    float bound = BH_BOUND;

    // Orientation of the accretion disc plane. Instead of a tilt fixed to the
    // world axes (V1, which made the look depend on where the black hole was
    // in the sky) it is defined relative to the line of sight: the camera sits
    // END_BLACK_HOLE_INCLINATION degrees above the disc plane, so 0 shows the
    // disc edge-on and 90 shows it from above, wherever the black hole is.
    float inclination = radians(float(END_BLACK_HOLE_INCLINATION));
    vec3 screen_up, screen_right;
    end_sky_basis(light_dir, screen_up, screen_right);
    vec3 rolled_up = screen_up * cos(BH_DISC_ROLL) + screen_right * sin(BH_DISC_ROLL);

    vec3 disc_normal = rolled_up * cos(inclination) - light_dir * sin(inclination);
    vec3 disc_x = normalize(cross(rolled_up, light_dir));
    vec3 disc_z = cross(disc_x, disc_normal);
    mat3 rotation = transpose(mat3(disc_x, disc_normal, disc_z));

    vec3 ray_pos = -light_dir * cam_dist;
    vec3 observed_dir = ray_dir;
    vec3 d = ray_dir;

    // Rays that can't touch the marched region don't need the march: from
    // outside it, a ray that misses it (or points away) is just bent by the
    // closed-form amount; one that hits it starts at the entry point, with the
    // bending up to there added analytically. This is what keeps most of the
    // sky (everything far from the black hole) nearly free.
    bool skip_march = false;
    if (cam_dist > bound) {
        float s_cam = dot(ray_pos, d);
        float b2 = dot(ray_pos, ray_pos) - s_cam * s_cam;

        if (s_cam > 0.0 || b2 > bound * bound) {
            skip_march = true;
        } else {
            vec3 entry = ray_pos + d * (-s_cam - sqrt(bound * bound - b2));
            bh_bend_segment(d, ray_pos, entry, false, gravity);
            ray_pos = entry;
        }
    }


    vec3 result = vec3(0.0);
    float halo = 0.0; // BH_HALO_INTENSITY: glow integrated along the ray
    float transmittance = 1.0;
    float closest_approach = 1e6;
    bool captured = false;

    // Animation clocks. Everything that moves in the disc is derived from
    // this one base clock, so Animation Speed = 0 freezes the disc completely
    // (every term below is time * speed, nothing is added to a running
    // frameTimeCounter), 1.0 is the tuned look, and higher values speed the
    // whole flow up coherently. They are separate variables because the disc
    // has three genuinely different motions, not because they need separate
    // sliders:
    //   orbit_time      - matter going round the hole (Keplerian: the inner
    //                     disc laps the outer one)
    //   turbulence_time - the turbulence evolving in place, so the pattern
    //                     boils instead of being a rigid texture dragged
    //                     around by the orbit
    //   shear_time      - fine streaks being stretched along the flow
    float base_time = frameTimeCounter * END_BLACK_HOLE_SPEED;
    float orbit_time = base_time * 0.9;
    float turbulence_time = base_time * 0.30;
    float shear_time = base_time * 0.12;
    float hot_spot_time = base_time * 0.45;

    // 1.0 at the default 40 steps; larger when using fewer steps
    float step_budget_scale = clamp(40.0 / float(steps), 0.5, 3.0);

    for (int i = 0; i < steps && !skip_march; ++i) {
        float dist = length(ray_pos);
        closest_approach = min(closest_approach, dist);

        if (dist < BH_HORIZON) {
            captured = true;
            break;
        }

        if (dist > bound && dot(ray_pos, d) > 0.0) break;

        // Step length: proportional to the distance from the singularity
        // (the light bends the most, and small details live, close to it) and
        // shortened when the ray is about to cross the thin disc plane so the
        // disc doesn't alias.
        // The step lengths are tuned for the default step count; with a
        // smaller budget they grow so the ray still reaches the horizon (or
        // gets out) instead of running out of steps halfway.
        float dt = clamp(0.12 * step_budget_scale * dist, 0.02, 1.2 * step_budget_scale);
        if (dist < BH_BOUND) {
            vec3 plane_pos = rotation * ray_pos;
            float plane_speed = abs((rotation * d).y);
            float dt_plane
                = (0.35 * abs(plane_pos.y) + 0.025) * step_budget_scale
                / max(plane_speed, 0.1);
            dt = min(dt, dt_plane);
        }
        dt = max(dt, 0.012 * step_budget_scale);

        // Gravitational lensing: pull the ray towards the singularity
        d = normalize(d - ray_pos * (gravity * dt / (dist * dist * dist)));

        // Closest distance to the singularity along this segment, so the
        // horizon edge doesn't depend on where the (dithered) samples land
        float along = clamp(-dot(ray_pos, d), 0.0, dt);
        closest_approach = min(closest_approach, length(ray_pos + d * along));

        ray_pos += d * dt;

        // Stratified sampling: the disc is sampled at a random point inside
        // the step that was just taken (the dither is different every frame),
        // so temporal accumulation converges to the true integral whatever the
        // step count and the disc's thin sheet doesn't alias into a pattern
        vec3 disc_pos = rotation * (ray_pos - d * (dt * dither));

        float r = length(disc_pos);
        float h = disc_pos.y;

        float radial_gradient = 1.0 - clamp01((r - disc_inner) / disc_width * 0.5);
        // Slightly flatter than before: reads more like a sheet of matter
        // caught in the gravity well and less like a puffy torus.
        float disc_thickness = 0.075 * radial_gradient;

        float fr = abs(r - disc_inner) + 0.4;
        fr *= fr;
        float fade = fr * fr * 0.04;
        float bloom_factor = 1.0 / (h * h * 40.0 + fade + 0.00002);
        bloom_factor *= clamp01(2.0 - abs(h) / disc_thickness);
        bloom_factor *= bloom_factor;

        float dr = bh_pcurve(radial_gradient);
        float density = dr;
        density *= clamp01(1.0 - abs(h) / disc_thickness);
        density = clamp01(density * 0.7);
        density = clamp01(density + bloom_factor * 0.1);

        float step_scale = dt / BH_REFERENCE_STEP;

        // Glow around the hole (see BH_HALO_INTENSITY), with IterationT's
        // distance function, integrated per unit length at the same
        // stratified sample as the disc and seen through the disc in front
        // of it. Nothing inside the disc's inner edge.
        float halo_r = length(disc_pos - vec3(0.0, 0.05, 0.0));
        float halo_k = length(vec2(halo_r - 1.0, halo_r - 0.01));
        halo += transmittance * dt * step(disc_inner, r)
            / (halo_k * halo_k * halo_k * sqrt(halo_k) + 0.001);

        if (density > 0.0001) {
            float phi = atan(-disc_pos.x, -disc_pos.z);

            // V1 sampled the noise with the radius only, which made the disc
            // look like concentric bands. Also use the angle (through a circle
            // so there is no seam) and rotate it differentially, the inner
            // disc orbiting faster, so the dust streaks and shears like a real
            // accretion flow. The radial frequency is unchanged.
            float swirl = phi + orbit_time / (r * sqrt(r) + 0.5);
            vec3 disc_coord = vec3(
                r * 3.5,
                cos(swirl) * BH_DISC_SWIRL_RADIUS,
                sin(swirl) * BH_DISC_SWIRL_RADIUS + h * 0.35
            );
            // Advance the noise field itself along a fourth axis (packed into
            // the radial coordinate, which the noise is not periodic in): the
            // turbulence is then evolving in the orbiting frame rather than
            // rigidly co-rotating with it, which is the difference between
            // matter churning and a texture being spun.
            disc_coord.x += turbulence_time;
            float fbm = end_sky_fbm(disc_coord, shear_time * vec3(1.0, 1.7, 0.0));
            fbm *= fbm;
            fbm *= fbm;

            density *= fbm * dr;

            float gr = 1.0 - radial_gradient;
            gr *= gr;
            float glow_strength = 1.0 / (gr * gr * 400.0 + 0.002);

            // Hot spots: clumps of matter that are brighter than the flow
            // around them, carried along by the orbit and fading in and out
            // as they go. Without them the disc's brightness only depends on
            // the radius, so the emission is a fixed pattern no matter how
            // fast the matter moves through it - the eye reads that as a
            // texture turning. A single octave of the noise already used for
            // the dust is enough, and it is the cheapest term in the loop.
            vec3 spot_coord = vec3(
                r * 1.25 + hot_spot_time,
                cos(swirl) * 0.85,
                sin(swirl) * 0.85
            );
            float spots = end_sky_value_noise(spot_coord * 2.2);
            glow_strength *= 0.55 + 1.45 * spots * spots;

            vec3 glow = blackbody(
                min(2700.0 + glow_strength * 50.0, BH_DISC_MAX_TEMPERATURE)
            ) * glow_strength;

            // Brightness asymmetry standing in for the disc's Doppler beaming
            glow *= sin(phi - 1.07) * 0.75 + 1.0;

            float step_transmittance = exp2(-density * 7.0 * step_scale);
            float integral = 1.0 - step_transmittance;
            transmittance *= step_transmittance;

            result += integral * transmittance * glow;
        }

        if (transmittance < 0.0001) break;
    }

    // Ran out of steps while still falling towards the singularity: it will
    // not make it back out, so treat it as swallowed instead of letting the
    // background show through (which drew a hard-edged patch)
    if (!captured && length(ray_pos) < 3.0 && dot(ray_pos, d) < 0.0
        && closest_approach < 3.0) {
        captured = true;
    }

    // Anti-aliased event horizon: rays whose closest approach is inside the
    // horizon radius are swallowed
    float horizon_visibility = captured
        ? 0.0
        : smoothstep(BH_HORIZON, BH_HORIZON * 1.03, closest_approach);

    // Where the broad halo is visible: everywhere except on rays that fall
    // into the hole. horizon_visibility is right for every ray except those
    // that stopped inside the opaque disc: the capture test above marks most
    // of those as swallowed (harmless for the disc, which hides the
    // background anyway), which would cut the broad halo out along the whole
    // front of the disc, beyond the shadow, as a dark noisy band.
    float broad_visibility = horizon_visibility;
    if (transmittance < 0.0001) {
        float s_exit = max(-dot(ray_pos, d), 0.0);
        float p_exit = length(ray_pos + d * s_exit);
        broad_visibility = smoothstep(
            BH_BROAD_HALO_SHADOW_CUTOFF * 0.75,
            BH_BROAD_HALO_SHADOW_CUTOFF * 1.25,
            p_exit
        );
    }

    lens_magnification = 1.0;
    lens_strength = 0.0;

    if (!captured) {
        bh_bend_tail(d, ray_pos, gravity);
        ray_dir = d;

        // How far the ray was bent, as a 0..1 strength
        float bend_angle = fast_acos(clamp(dot(observed_dir, d), -1.0, 1.0));
        lens_strength = smoothstep(0.02, 0.5, bend_angle);

        // Magnification of the background, estimated with the point lens
        // model: a ray seen at angle theta from the black hole arrives from
        // beta = theta - theta_E^2 / theta. Its tangential stretch is
        // theta / beta and its radial stretch 1 / (1 + theta_E^2 / theta^2),
        // where theta_E is derived from the bending this ray actually got.
        float cos_theta = dot(observed_dir, light_dir);
        vec3 radial = observed_dir - light_dir * cos_theta;
        float sin_theta = length(radial);
        if (sin_theta > 1e-4) {
            float theta = atan(sin_theta, cos_theta);
            float beta = atan(dot(d, radial) / sin_theta, dot(d, light_dir));
            float q = beta / max(theta, 1e-4);
            lens_magnification
                = clamp(1.0 / max(abs(q * (2.0 - q)), 1e-3), 1.0, 16.0);
        }
    }

    background_transmittance = transmittance * horizon_visibility;
    // The glow is kept on escaping rays only (see BH_HALO_INTENSITY), in the
    // colour of the hottest matter
    vec3 halo_glow = blackbody(BH_DISC_MAX_TEMPERATURE)
        * (halo * horizon_visibility * BH_HALO_INTENSITY);

    // Broad halo (see BH_BROAD_HALO_INTENSITY): how far the view ray passes
    // from the black hole, in local units, through the soft falloff
    float broad_b = cam_dist
        * fast_acos(clamp(dot(observed_dir, light_dir), -1.0, 1.0));
    float broad_falloff
        = rcp(1.0 + sqr(broad_b * (1.0 / BH_BROAD_HALO_RADIUS)));
    broad_falloff *= broad_falloff;
    broad_falloff *= broad_falloff;
    vec3 broad_glow = BH_BROAD_HALO_COLOR
        * (BH_BROAD_HALO_INTENSITY * END_BLACK_HOLE_BROAD_HALO * broad_falloff
           * broad_visibility);
#if defined BH_BROAD_HALO_OCCLUSION
    // The broad halo is the black hole's light spreading around it: when the
    // planet hides the black hole, it fades with the share of light still
    // getting past (include/sky/sky.glsl). Everything else here is drawn per
    // pixel, and the planet covers it where it is in front
    broad_glow *= BH_BROAD_HALO_OCCLUSION;
#endif

    disc_glow = (result * (BH_GLOW_NORMALIZATION * BH_DISC_EMISSION_GAIN)
        + halo_glow) * END_BLACK_HOLE_DISC_BRIGHTNESS
        + broad_glow;

    // Colour options (Photon Cinematic Concept v0.7.6, v0.7.7): its light's
    // red, green and blue (in rec709)
    disc_glow = max((disc_glow * working_to_display_color) * end_sky_hole_tint, vec3(0.0))
        * rec709_to_working_color;
}

// The black hole's lens alone (Photon Cinematic Concept v0.7.6): where a view
// ray ends up looking, without drawing the disc. The same path as
// draw_end_black_hole() - the same steps, the same bending - with none of
// the disc's shading on the way (its noise, its glow, its halo), which is
// most of the work. For what only needs the lensed direction: the nebula's
// lower-resolution pass (include/sky/end_nebula_buffer.glsl).
//   ray_dir (inout): view direction in, lensed direction out
//   seen (out): 0 where the ray falls into the black hole, 1 elsewhere (the
//               disc's own opacity is not in it)
void bh_lens(inout vec3 ray_dir, out float seen, vec3 light_dir) {
    const int steps = END_BLACK_HOLE_STEPS;

    float apparent_scale
        = pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE;
    float cam_dist
        = max(BH_CAMERA_DISTANCE / apparent_scale, BH_MIN_CAMERA_DISTANCE);
    float zoom = BH_CAMERA_DISTANCE / cam_dist;
    float gravity = BH_GRAVITY * zoom * END_BLACK_HOLE_WARP_STRENGTH;
    float bound = BH_BOUND;

    // (the disc's plane: the steps shorten near it, as in the full march)
    float inclination = radians(float(END_BLACK_HOLE_INCLINATION));
    vec3 screen_up, screen_right;
    end_sky_basis(light_dir, screen_up, screen_right);
    vec3 rolled_up = screen_up * cos(BH_DISC_ROLL) + screen_right * sin(BH_DISC_ROLL);
    vec3 disc_normal = rolled_up * cos(inclination) - light_dir * sin(inclination);

    vec3 ray_pos = -light_dir * cam_dist;
    vec3 d = ray_dir;

    bool skip_march = false;
    if (cam_dist > bound) {
        float s_cam = dot(ray_pos, d);
        float b2 = dot(ray_pos, ray_pos) - s_cam * s_cam;

        if (s_cam > 0.0 || b2 > bound * bound) {
            skip_march = true;
        } else {
            vec3 entry = ray_pos + d * (-s_cam - sqrt(bound * bound - b2));
            bh_bend_segment(d, ray_pos, entry, false, gravity);
            ray_pos = entry;
        }
    }

    float closest_approach = 1e6;
    bool captured = false;
    float step_budget_scale = clamp(40.0 / float(steps), 0.5, 3.0);

    for (int i = 0; i < steps && !skip_march; ++i) {
        float dist = length(ray_pos);
        closest_approach = min(closest_approach, dist);

        if (dist < BH_HORIZON) {
            captured = true;
            break;
        }

        if (dist > bound && dot(ray_pos, d) > 0.0) break;

        float dt = clamp(0.12 * step_budget_scale * dist, 0.02, 1.2 * step_budget_scale);
        if (dist < BH_BOUND) {
            float dt_plane
                = (0.35 * abs(dot(disc_normal, ray_pos)) + 0.025) * step_budget_scale
                / max(abs(dot(disc_normal, d)), 0.1);
            dt = min(dt, dt_plane);
        }
        dt = max(dt, 0.012 * step_budget_scale);

        d = normalize(d - ray_pos * (gravity * dt / (dist * dist * dist)));

        float along = clamp(-dot(ray_pos, d), 0.0, dt);
        closest_approach = min(closest_approach, length(ray_pos + d * along));

        ray_pos += d * dt;
    }

    if (!captured && length(ray_pos) < 3.0 && dot(ray_pos, d) < 0.0
        && closest_approach < 3.0) {
        captured = true;
    }

    seen = captured ? 0.0 : 1.0;
    if (!captured) {
        bh_bend_tail(d, ray_pos, gravity);
        ray_dir = d;
    }
}

#if defined CONCEPT_END_STARS // only the Enhanced Star Field uses it
// Lensing parameters for a star field sampled along background_dir: the
// direction arcs run in (around the black hole), their half-length in
// radians, and how much brighter the magnified stars get. Exactly the model
// bh_draw_lensed_stars() below uses, exposed on its own so the Enhanced Star
// Field (end_stars(), include/sky/end_stars.glsl) stretches and brightens its
// stars the same way. Vanishes far from the black hole (lens_strength = 0: arc 0, gain 1).
void bh_star_lens(
    vec3 background_dir,
    vec3 light_dir,
    float lens_magnification,
    float lens_strength,
    out vec3 tangent,
    out float arc,
    out float gain
) {
    gain = 1.0
        + BH_LENSED_STAR_BRIGHTNESS * lens_strength * (sqrt(lens_magnification) - 1.0);

    tangent = cross(light_dir, background_dir);
    float tangent_length = length(tangent);
    float arc_amount = lens_strength * lens_strength
        * (0.3 + 0.7 * clamp01((lens_magnification - 1.0) / 7.0));
    arc = BH_LENSED_STAR_ARC * arc_amount * smoothstep(0.0, 0.05, tangent_length);
    tangent /= max(tangent_length, 1e-4);
}

// How far a view ray passes from the black hole, in black hole local units
// (the shadow edge is at ~1.1): the angle between the ray and the black hole's
// direction times the distance of draw_end_black_hole()'s camera, exactly as
// the broad halo measures it. Follows the Size option.
float bh_impact(vec3 ray_dir) {
    float apparent_scale
        = pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE;
    float cam_dist
        = max(BH_CAMERA_DISTANCE / apparent_scale, BH_MIN_CAMERA_DISTANCE);
    return cam_dist * fast_acos(
        clamp(dot(ray_dir, end_black_hole_direction()), -1.0, 1.0)
    );
}
#endif

// Photon's own End star field, sampled along a lensed direction.
//
// The stars themselves are Photon's (same projection and star function as
// draw_stars() in stars.glsl, which uses the same coverage in the End), so no
// second star system is added. The only differences are a consequence of the
// lensing, and both vanish far from the black hole (lens_strength = 0, where
// this is exactly draw_stars()):
//   - magnification: formerly too faint stars become visible and brighter, and
//   - stretching: point sources are smeared into arcs around the black hole,
//     which is what makes gravitational lensing readable in a sparse field.
vec3 bh_draw_lensed_stars(
    vec3 background_dir,
    vec3 light_dir,
    float lens_magnification,
    float lens_strength
) {
    float density = 1.0 + BH_LENSED_STAR_DENSITY * lens_strength * lens_strength;
    float star_threshold = max(1.0 - 0.008 * STARS_COVERAGE * density, 0.5);

    float brightness = 1.0
        + BH_LENSED_STAR_BRIGHTNESS * lens_strength * (sqrt(lens_magnification) - 1.0);

    // Arcs run around the black hole: perpendicular to both the axis towards
    // it and the (lensed) direction being looked up
    vec3 tangent = cross(light_dir, background_dir);
    float tangent_length = length(tangent);
    // Arcs are longest where the magnification is highest (near the Einstein
    // ring) and fade out gradually with distance from the black hole
    float arc_amount = lens_strength * lens_strength
        * (0.3 + 0.7 * clamp01((lens_magnification - 1.0) / 7.0));
    float arc = BH_LENSED_STAR_ARC * arc_amount * smoothstep(0.0, 0.05, tangent_length);
    tangent /= max(tangent_length, 1e-4);

    vec3 stars = vec3(0.0);

    // Arcs shorter than a fraction of a pixel are just points: one sample
    int samples = arc > 1.5e-3 ? BH_LENSED_STAR_ARC_SAMPLES : 1;

    for (int i = 0; i < samples; ++i) {
        float offset = samples > 1
            ? (float(i) / float(samples - 1) - 0.5) * 2.0 * arc
            : 0.0;
        vec3 dir = normalize(background_dir + tangent * offset);

        // Project ray direction onto the plane (identical to draw_stars())
        vec2 coord = dir.xy * rcp(abs(dir.z) + length(dir.xy)) + 41.21 * sign(dir.z);
        coord *= 600.0;

        stars = max(stars, stable_star_field(coord, star_threshold));

    }

    return stars * brightness;
}

#endif // INCLUDE_SKY_END_BLACK_HOLE
