#if !defined INCLUDE_SKY_END_PLANET
#define INCLUDE_SKY_END_PLANET

#include "/include/sky/end_sky_common.glsl"

/*
--------------------------------------------------------------------------------

  include/sky/end_planet:
  A colossal planet hanging in the End sky.

  Independent of the black hole in every sense: it has its own toggle, its own
  orbit, its own speeds and its own light source (Photon's End sun). It
  compiles and draws with the black hole disabled, and the black hole compiles
  and draws with the planet disabled. The only thing they share are the
  helpers in end_sky_common.glsl.

  The planet is on a wide orbit around the End's main island rather than
  parked at a fixed spot in the sky. It is placed at a real world-space
  position, and the direction it is seen in is computed from the camera, so
  the orbit stays coherent in space: fly across the island and the planet
  keeps its place in the world instead of following the player around. Over
  an orbit it rises on one side, arcs across the sky, passes the black hole,
  and sets on the other side, so the composition keeps changing on its own.

  It is not gravitationally lensed: it sits in front of the warped spacetime,
  not behind it, so it is sampled along the camera's raw ray direction and
  composited on top of everything else (disc, glow, stars, sun) wherever it
  covers the screen - like a real body eclipsing the sky behind it.

  Same technique Photon already uses for the sun and stars: an analytic
  angular disc shaded as a sphere, evaluated directly from the ray direction
  with no raymarch, so it only costs anything on the pixels it actually
  covers.

--------------------------------------------------------------------------------
*/

// Angular radius (radians) at PLANET_SIZE = 1.0: huge - a body filling this
// much of the sky reads as something the camera is close to - while still
// leaving the rest of the sky (and the black hole) visible beside it. Kept
// safely below pi/2 so the projection below never breaks down.
const float EP_RADIUS = 0.42;
// Orbital rate (radians/second) and surface rotation, at speed multiplier
// 1.0. Deliberately slow: one lap takes about ten minutes, so the planet
// visibly changes place over a session without ever looking like it is
// racing. The sliders go far above 1.0 so the motion can be sped up to
// confirm it works, then dialled back down.
// Exactly six laps per hour (was 0.0105, 0.3% faster): frameTimeCounter
// wraps every hour, and a whole number of laps keeps the planet from jumping
// ~6 degrees at the wrap - which would also jump an eclipse in progress.
const float EP_ORBIT_BASE_RATE = 6.0 * 6.28318531 / 3600.0;
const float EP_SPIN_BASE_SPEED = 0.008;

#if defined CONCEPT_BH_LIGHT
// Planet lit by the black hole (Environmental Light).
//
// Surface: the same continents and relief, in a dusty red-brown of its own,
// so under the black hole's neutral light it reads as a planet and not as a
// grey moon (under the End sun's orange light it looked like this already).
const vec3 EP_BH_SURFACE_TINT = vec3(1.00, 0.70, 0.52);
// Air: the atmosphere only shows where the black hole's light scatters in it,
// in the sky style's own tint (cool in Cinematic Void, Photon's purple in
// Photon Original), at luminance 1. It never glows by itself.
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
const vec3 EP_BH_AIR_TINT = vec3(1.085, 0.879, 2.016);
#else
const vec3 EP_BH_AIR_TINT = vec3(0.835, 1.026, 1.432);
#endif
// How much air lit from the camera's side (front) or from behind the planet
// (back, forward scattering: Henyey-Greenstein, normalised to 1 at the limb
// with the black hole right behind) shows at the limb; how fast the air
// thins out beyond the limb; its opacity there; and the night side's trace of
// ambient
const float EP_BH_AIR_FRONT = 0.20;
const float EP_BH_AIR_BACK = 1.5;
const float EP_BH_AIR_G = 0.75;
const float EP_BH_AIR_BACK_NORM = 1.0 / 0.41;
const float EP_BH_AIR_FALLOFF = 40.0;
const float EP_BH_AIR_OPACITY = 0.3;
const float EP_BH_NIGHT_AMBIENT = 0.02;
// Half the length of the line of sight through that air where it grazes the
// limb, relative to the planet's radius (thickness 1 / EP_BH_AIR_FALLOFF)
const float EP_BH_AIR_CHORD = sqrt(2.0 / EP_BH_AIR_FALLOFF);

// How much of the air seen at this point of the limb is lit on the camera's
// side (the "front" of ep_bh_air()). The line of sight grazes the limb: half
// of it lies on the camera's side of the point where it touches the air's
// floor, half beyond. Lit from the side, only the lit limb shows (fading
// towards the terminator, as before). Lit from the camera's side (towards
// full phase), the near half is lit all round the disc even though the ground
// at the limb sits on the terminator - so the air no longer vanishes at full
// phase - while the night side's limb stays dark at gibbous phases. Lit from
// behind the planet, the near half is in its shadow and the lit far half is
// the forward scattering in ep_bh_air(): unchanged.
//   limb:         direction of this point from the disc centre, across the face
//   light_facing: dot(light_dir, planet direction), -1 = light behind the camera
float ep_bh_air_lit(vec3 limb, vec3 light_dir, float light_facing) {
    float cos_limb = dot(limb, light_dir);
    float along = max(-light_facing, 0.0);
    float lit_share = smoothstep(0.0, 1.0,
        0.5 + 0.5 * cos_limb / max(EP_BH_AIR_CHORD * along, 0.16));
    float taper = clamp01(cos_limb / sqrt(max(1.0 - along * along, 1e-4)));
    return lit_share * mix(taper, 1.0, along);
}

// Light scattered towards the camera by the planet's air at the limb, per unit
// of air (the edge profile is applied by the caller): the lit limb seen from
// the lit side, plus forward scattering when the black hole is behind the
// planet, strongest on the side nearest it
vec3 ep_bh_air(vec3 ray_dir, vec3 light_dir, vec3 light_color, float front) {
    float back = min(
        henyey_greenstein_phase(dot(ray_dir, light_dir), EP_BH_AIR_G)
            * EP_BH_AIR_BACK_NORM,
        3.0
    );
    return light_color * EP_BH_AIR_TINT
        * (EP_BH_AIR_FRONT * front + EP_BH_AIR_BACK * back);
}

// The air just beyond the limb, as colour + opacity for sky.glsl's mix():
// adds exactly air * band over the sky behind, which the thin air dims a
// little (at most EP_BH_AIR_OPACITY, and only where it is lit)
vec4 ep_bh_air_halo(vec3 ray_dir, vec3 light_dir, vec3 light_color, vec3 p, float r, float light_facing) {
    float front = ep_bh_air_lit(p / max(r, 1e-4), light_dir, light_facing);
    float band = exp(-max(r - 1.0, 0.0) * EP_BH_AIR_FALLOFF);
    vec3 glow = ep_bh_air(ray_dir, light_dir, light_color, front) * band;
    float alpha = band * EP_BH_AIR_OPACITY
        * clamp01(dot(glow, vec3(0.2627, 0.6780, 0.0593)) * 20.0);
    return vec4(glow / max(alpha, 1e-4), alpha);
}
#endif

// Centre of the orbit: the End's main island, at the world origin. The
// height is roughly the island's surface, which only matters when the camera
// is near it - at orbital distance it is a rounding error.
const vec3 EP_ORBIT_CENTER = vec3(0.0, 64.0, 0.0);

// Atmosphere tint, and the colour of the light the End sun casts on it (the
// same warm tone Photon's own End sun is drawn in, so the planet reads as
// being lit by the sky it is in rather than by a neutral studio lamp)
const vec3 EP_ATMOSPHERE_COLOR = vec3(0.42, 0.34, 0.78);
const vec3 EP_SUNLIGHT_COLOR = vec3(1.00, 0.62, 0.36);

// World-space position of the planet on its orbit around the island.
//
// The orbit is a circle of radius END_PLANET_ORBIT_RADIUS around the island,
// in a plane tilted by END_PLANET_ORBIT_INCLINATION. It crosses the horizon
// at END_PLANET_ORBIT_AZIMUTH (where the planet rises and sets) and reaches
// its highest point a quarter of a lap later.
//
// Orbit through Black Hole: the same circle (radius, inclination, speed), only
// turned about the vertical axis so that it passes exactly through the
// direction the black hole is drawn in, as seen from the island. The planet
// then crosses in front of the black hole once per lap, gradually. Needs an
// inclination at least as high as the black hole's elevation; a lower one is
// raised to it (the orbit then peaks right at the black hole). Without a
// black hole in this world, or with the option off, the Orbit Azimuth option
// orients the orbit as before.
//
// Orbit Phase: where the planet is on its orbit when the game starts, in
// degrees along the orbit. With Orbit through Black Hole, 0 = centred in front
// of the black hole (negative: still approaching it); otherwise 0 = the point
// where it rises.
vec3 end_planet_position() {
    float theta = frameTimeCounter * END_PLANET_ORBIT_SPEED * EP_ORBIT_BASE_RATE
        + radians(float(END_PLANET_ORBIT_PHASE));
    float inclination = radians(float(END_PLANET_ORBIT_INCLINATION));
    float azimuth = float(END_PLANET_ORBIT_AZIMUTH);

#ifdef END_PLANET_ORBIT_THROUGH_BLACK_HOLE
#if defined SKY_BLACK_HOLE
    // On the orbit, the elevation is asin(sin(inclination) * sin(theta)) and
    // the compass direction turns atan(cos(inclination) * tan(theta)) away
    // from the rising point: solve both for the black hole's direction
    float hole_elevation = radians(float(END_BLACK_HOLE_ELEVATION));
    inclination = max(inclination, abs(hole_elevation));
    float sin_theta_hole = inclination > 1e-3
        ? clamp(sin(hole_elevation) / sin(inclination), -1.0, 1.0)
        : 0.0;
    float theta_hole = asin(sin_theta_hole);
    azimuth = float(END_BLACK_HOLE_AZIMUTH)
        - degrees(atan(cos(inclination) * sin_theta_hole, cos(theta_hole)));
    theta += theta_hole;
#endif
#endif

    // Horizontal direction the planet rises in, and the one a quarter lap on
    vec3 rise = end_sky_direction(azimuth, 0.0);
    vec3 quarter = end_sky_direction(azimuth + 90.0, 0.0);

    // Tilting the second axis up out of the horizontal plane is what turns a
    // flat ring around the island into an arc that climbs across the sky
    vec3 high = quarter * cos(inclination) + vec3(0.0, 1.0, 0.0) * sin(inclination);

    return EP_ORBIT_CENTER
        + END_PLANET_ORBIT_RADIUS * (rise * cos(theta) + high * sin(theta));
}

// Direction the planet is seen in from where the camera actually is
vec3 end_planet_direction() {
    return normalize(end_planet_position() - cameraPosition);
}

// Returns rgb + coverage (0..1).
//   ray_dir:   the camera's RAW ray direction (never a lensed one - the
//              planet is in front, so its light isn't bent)
//   light_dir: direction of the light source lighting it (Photon's End sun)
//   light_color: colour and intensity of that light. The End passes the
//              fixed EP_SUNLIGHT_COLOR (see the two-argument overload below);
//              the Overworld passes Photon's own sun_color, so the planet is
//              lit by the same sunlight as the terrain around it.
//   center:    the direction it is seen in, radius: its angular radius
//              (v0.9.0: given, so the Overworld can draw it as the moon)
vec4 draw_end_planet_at(
    vec3 ray_dir,
    vec3 center,
    float radius,
    vec3 light_dir,
    vec3 light_color
) {
    float cos_a = dot(ray_dir, center);

    // Reject everything outside the disc plus its atmosphere margin
    if (cos_a < cos(radius) * 0.97) return vec4(0.0);

    // Offset from the disc centre, 1.0 at the limb (same projection Photon
    // uses for the sun, at a much larger angular radius)
    vec3 p = (ray_dir - center * cos_a) / sin(radius);
    float r2 = dot(p, p);
    float r = sqrt(r2);

    // Direction of the light across the planet's face, so the terminator runs
    // the right way whatever the sun and the planet are doing
    vec3 up, right;
    end_sky_basis(center, up, right);
    vec2 light_2d = vec2(dot(light_dir, right), dot(light_dir, up));
    // Same offset, in that 2d basis, so the halo below can tell lit limb from
    // dark limb
    vec2 p_2d = vec2(dot(p, right), dot(p, up));
    float light_2d_length = length(light_2d);
    light_2d = light_2d_length > 1e-4 ? light_2d / light_2d_length : vec2(1.0, 0.0);
    // How much the light comes from behind the planet (-1) or from the
    // camera's side (+1): this is what turns the lit face into a crescent
    float light_facing = dot(light_dir, center);

    // Atmosphere halo beyond the limb. Concentrated on the lit limb and
    // faded out around the dark one: a halo of even thickness all the way
    // round reads as an outline drawn around the planet, not as air catching
    // the light.
    if (r >= 1.0) {
#if defined CONCEPT_BH_LIGHT
        return ep_bh_air_halo(ray_dir, light_dir, light_color, p, r, light_facing);
#endif
        float lit_side = clamp01(dot(normalize(p_2d), light_2d));
        lit_side *= lit_side;
        float halo = exp(-(r - 1.0) * 30.0);
        float strength = 0.02 + 0.85 * lit_side * clamp01(0.5 - light_facing);
        return vec4(EP_ATMOSPHERE_COLOR, halo * strength);
    }

    float facing = sqrt(max(1.0 - r2, 0.0));
    // Surface normal of the sphere at this pixel, in world space
    vec3 normal = normalize(p * 1.0 - center * facing);

    float diffuse = max(dot(normal, light_dir), 0.0);

    // Surface: low-frequency continents with a little finer relief on top.
    // The sample position turns about the planet's own axis so the pattern
    // rotates with it instead of scrolling across a fixed sphere.
    float spin = frameTimeCounter * END_PLANET_ROTATION_SPEED * EP_SPIN_BASE_SPEED;
    float spin_cos = cos(spin);
    float spin_sin = sin(spin);
    vec3 surface_pos = vec3(
        normal.x * spin_cos - normal.z * spin_sin,
        normal.y,
        normal.x * spin_sin + normal.z * spin_cos
    );

    float continents = end_sky_fbm(surface_pos * 1.7 + 11.0, vec3(0.0));
    float relief = end_sky_fbm(surface_pos * 6.0 + 4.0, vec3(0.0));

    // Dark basalt lowlands against paler, dustier highlands. Kept dark
    // overall: a body this size should read as a silhouette with one lit
    // flank, not as a bright ball pasted on the sky.
    const vec3 lowland = vec3(0.030, 0.027, 0.042);
    const vec3 highland = vec3(0.260, 0.215, 0.200);
    vec3 albedo = mix(lowland, highland, smoothstep(0.38, 0.68, continents));
    albedo *= 0.55 + 0.9 * relief * relief;
#if defined CONCEPT_BH_LIGHT
    albedo *= EP_BH_SURFACE_TINT;
#endif

    // Lambert with a soft terminator, plus a trace of ambient so the night
    // side is a silhouette rather than a hole in the sky
    float terminator = smoothstep(-0.10, 0.22, dot(normal, light_dir));
#if defined CONCEPT_BH_LIGHT
    vec3 lit = albedo * light_color * (1.7 * diffuse * terminator)
        + albedo * EP_BH_AIR_TINT * EP_BH_NIGHT_AMBIENT;

    // The air over the disc near the limb: its path through the atmosphere
    // grows towards the edge, where it meets the halo beyond the limb with
    // the same value (one continuous glow, no outline). Added over the night
    // side too, so a planet in front of the black hole reads as a dark body
    // edged by light instead of merging with the black hole's shadow.
    // Lit like the air beyond the limb (same value at the edge), and seen
    // through: the ground behind it is dimmed by the same opacity the air
    // beyond the limb dims the sky with, so the surface fades into its
    // atmosphere at the edge instead of being cut out against the sky
    float air_path = pow(1.0 - facing, 3.0);
    vec3 air = ep_bh_air(ray_dir, light_dir, light_color,
        ep_bh_air_lit(p / max(r, 1e-4), light_dir, light_facing));
    float air_opacity = EP_BH_AIR_OPACITY * air_path
        * clamp01(dot(air, vec3(0.2627, 0.6780, 0.0593)) * 20.0);
    lit = lit * (1.0 - air_opacity) + air * air_path;

    // Antialiased edge: what the planet leaves uncovered shows the air beyond
    // the limb, not the sky (which drew a dark line between the two)
    float coverage = 1.0 - smoothstep(0.988, 1.0, r);
    vec4 edge_air = ep_bh_air_halo(ray_dir, light_dir, light_color, p, r, light_facing);
    float edge_alpha = coverage + edge_air.a * (1.0 - coverage);
    vec3 edge_rgb = lit * coverage + edge_air.rgb * edge_air.a * (1.0 - coverage);
    return vec4(edge_rgb / max(edge_alpha, 1e-4), edge_alpha);
#else
    vec3 lit = albedo * light_color * (1.7 * diffuse * terminator)
        + albedo * EP_ATMOSPHERE_COLOR * 0.06;

    // Atmosphere on the lit limb: thicker towards the edge of the disc, and
    // only where the light actually reaches it
    float rim = pow(1.0 - facing, 3.0);
    lit += EP_ATMOSPHERE_COLOR * rim * 0.9 * diffuse * terminator;

    float coverage = 1.0 - smoothstep(0.988, 1.0, r);
    return vec4(lit, coverage);
#endif
}

// On its orbit, at its own size
vec4 draw_end_planet(vec3 ray_dir, vec3 light_dir, vec3 light_color) {
    return draw_end_planet_at(
        ray_dir,
        end_planet_direction(),
        clamp(EP_RADIUS * END_PLANET_SIZE, 0.05, 1.45),
        light_dir,
        light_color
    );
}

// The End's planet, lit by the End sun's warm light exactly as in V2.4
vec4 draw_end_planet(vec3 ray_dir, vec3 light_dir) {
    return draw_end_planet(ray_dir, light_dir, EP_SUNLIGHT_COLOR);
}

#endif // INCLUDE_SKY_END_PLANET
