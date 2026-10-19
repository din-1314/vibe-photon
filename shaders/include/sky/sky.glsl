#if !defined INCLUDE_SKY_SKYsky
#define INCLUDE_SKY_SKY

#include "/include/utility/color.glsl"
#include "/include/utility/dithering.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/random.glsl"

// Which of the optional sky objects (black hole, planet) this world draws.
// Decided entirely by the preprocessor: in a world that doesn't draw them,
// none of their code is even compiled in. The Nether never qualifies.
//
// Each object has its own world scope (END_BLACK_HOLE_WORLD /
// END_PLANET_WORLD in settings.glsl), so neither depends on the other.
#if defined WORLD_END && (END_BLACK_HOLE_WORLD == CONCEPT_WORLD_END || END_BLACK_HOLE_WORLD == CONCEPT_WORLD_BOTH)
#define BLACK_HOLE_WORLD_ALLOWED
#endif

#if defined WORLD_OVERWORLD && (END_BLACK_HOLE_WORLD == CONCEPT_WORLD_OVERWORLD || END_BLACK_HOLE_WORLD == CONCEPT_WORLD_BOTH)
#define BLACK_HOLE_WORLD_ALLOWED
#endif

#if defined WORLD_END && (END_PLANET_WORLD == CONCEPT_WORLD_END || END_PLANET_WORLD == CONCEPT_WORLD_BOTH)
#define PLANET_WORLD_ALLOWED
#endif

// (v0.9.1: in the Overworld the planet is the moon - see below - not on
// its End orbit)
#if defined WORLD_OVERWORLD && (END_PLANET_WORLD == CONCEPT_WORLD_OVERWORLD || END_PLANET_WORLD == CONCEPT_WORLD_BOTH)
#define PLANET_MOON_WORLD_ALLOWED
#endif

// Each object's own Enabled switch. Written as plain #ifdef on purpose: Iris
// (like OptiFine) only lists a boolean #define in the options menu when some
// shader tests it with #ifdef/#ifndef, so a combined "#if defined A &&
// defined B" would silently hide the Enabled toggle from the menu.
// Photon Cinematic Concept (v0.9.0 - v0.9.3, by its World option): the black
// hole in the Overworld has the End's place and size and is gone by day
// (draw_sky() below)
#if defined WORLD_OVERWORLD && defined BLACK_HOLE_WORLD_ALLOWED
#define CONCEPT_OVERWORLD_BLACK_HOLE
#endif

#ifdef END_BLACK_HOLE
#if defined BLACK_HOLE_WORLD_ALLOWED
#define SKY_BLACK_HOLE
#endif
#endif

#ifdef END_PLANET
#if defined PLANET_WORLD_ALLOWED
#define SKY_PLANET
#endif
#endif

//----------------------------------------------------------------------------//
#if defined WORLD_OVERWORLD

#include "/include/lighting/bsdf.glsl"
#include "/include/lighting/colors/light_color.glsl"
#include "/include/lighting/colors/weather_color.glsl"
#include "/include/misc/lightning_flash.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/projection.glsl"
#include "/include/sky/rainbow.glsl"
#include "/include/sky/stars.glsl"
#include "/include/utility/geometry.glsl"

// Photon Cinematic Concept (v0.9.0): the End's shooting stars in the Overworld's
// night sky (v0.9.1: by the Shooting Stars' World option; plain #ifdef for
// the menu)
#ifdef END_SHOOTING_STARS
#if defined PROGRAM_DEFERRED4 && (END_SHOOTING_STARS_WORLD == CONCEPT_WORLD_OVERWORLD || END_SHOOTING_STARS_WORLD == CONCEPT_WORLD_BOTH)
#define CONCEPT_OVERWORLD_SHOOTING_STARS
#include "/include/sky/end_shooting_stars.glsl"
#endif
#endif

// Photon Cinematic Concept (v0.9.4): the Enhanced Star Field (its World
// option) and the Milky Way (plain #ifdef for the menu) in the Overworld's
// night sky; the stars before the black hole, which bends them
#if defined PROGRAM_DEFERRED4
#include "/include/sky/end_stars.glsl"
#ifdef MILKY_WAY
#define CONCEPT_MILKY_WAY
#include "/include/sky/overworld_milky_way.glsl"
#endif
#endif

// Black hole and planet (Overworld + End mode), final sky pass only
#if defined PROGRAM_DEFERRED4 && defined SKY_BLACK_HOLE
#include "/include/sky/end_black_hole.glsl"
#endif
#if defined PROGRAM_DEFERRED4 && defined SKY_PLANET
#include "/include/sky/end_planet.glsl"
#endif

// Photon Cinematic Concept (v0.9.0): Planet as Moon - our planet takes the
// moon's place in the Overworld's sky: where the moon is, with the moon's
// phases (the light turns round it with moonPhase, as on Photon's moon),
// Size times the moon's. Photon's shader moon only (not with Vanilla Moon).
// (v0.9.1: by the planet's World option and its Enabled switch, plain
// #ifdef for the menu)
#ifdef END_PLANET
#if defined PROGRAM_DEFERRED4 && !defined VANILLA_MOON && defined PLANET_MOON_WORLD_ALLOWED
#define CONCEPT_PLANET_MOON
#include "/include/sky/end_planet.glsl"
#endif
#endif

#if defined PROGRAM_DEFERRED0
#include "/include/sky/clouds.glsl"

#if defined CREPUSCULAR_RAYS && !defined BLOCKY_CLOUDS
#include "/include/sky/crepuscular_rays.glsl"
#endif
#endif

const float sun_luminance = rcp(
    cone_angle_to_solid_angle(sun_angular_radius)
); // luminance of sun disk
const float moon_luminance = 10.0; // luminance of moon disk

vec3 draw_sun(vec3 ray_dir) {
    float nu = dot(ray_dir, sun_dir);

    // Limb darkening model from
    // http://www.physics.hmc.edu/faculty/esin/a101/limbdarkening.pdf
    const vec3 alpha = vec3(0.429, 0.522, 0.614);
    float center_to_edge = max0(sun_angular_radius - fast_acos(nu));
    vec3 limb_darkening
        = pow(vec3(1.0 - sqr(1.0 - center_to_edge)), 0.5 * alpha);

    return sun_luminance * sun_color * step(0.0, center_to_edge)
        * limb_darkening;
}

vec4 draw_moon(vec3 ray_dir) {
    const float angle = 0.7;
    const mat2 rot = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));

    const vec3 lit_color
        = vec3(MOON_R, MOON_G <= 0.03 ? 0.0 : MOON_G - 0.03, MOON_B);
    const vec3 glow_color
        = vec3(MOON_R <= 0.05 ? 0.0 : MOON_R - 0.05, MOON_G, MOON_B);

    // Cut out the moon disc.
    float MoV = dot(ray_dir, moon_dir);
    if (MoV < cos(moon_angular_radius)) {
        return vec4(0.0);
    }

    // Find distance from center to edge.
    float dist = clamp01(fast_acos(MoV) / moon_angular_radius);

    // Transform the coordinate space such that z is parallel to moon_dir
    vec3 tangent = moon_dir.y == 1.0
        ? vec3(1.0, 0.0, 0.0)
        : normalize(cross(vec3(0.0, 1.0, 0.0), moon_dir));
    vec3 bitangent = normalize(cross(tangent, moon_dir));
    mat3 tbn = mat3(tangent, bitangent, moon_dir);

    // Vector from ray dir to moon dir.
    vec2 offset = ((ray_dir - sun_dir) * tbn).xy;
    offset = fract(offset + 0.5);

    vec3 noise = texture(noisetex, 2.0 * offset).xyz;
    float moon_texture
        = pow1d5(noise.x) * 0.75 + 0.6 * cube(noise.y) - 0.1 * noise.z;

    // Find the distance to the moon if it were 1 unit away, and its normal.
    float moon_dist
        = intersect_sphere(-moon_dir, ray_dir, moon_angular_radius).x;
    vec3 moon_normal = normalize(ray_dir * moon_dist - moon_dir);

    // Get light direction which orbits around moon
    float light_angle = 0.125 * tau * float(moonPhase);
    vec3 left_dir = normalize(cross(vec3(0.0, 1.0, 0.0), ray_dir));
    vec3 light_dir = cos(light_angle) * -ray_dir + sin(light_angle) * left_dir;
    float moon_shadow = dampen(max0(dot(moon_normal, light_dir)));

    float edge_glow = sqr(sqr(sqr(dist)));

    vec3 color = max(moon_shadow * lit_color * (1.0 + 4.0 * edge_glow),
                     0.5 * glow_color * (0.1 + 0.1 * edge_glow))
        * (0.2 + 0.8 * moon_texture);
    color = moon_luminance * sqr(color);
    return vec4(color, 1.0);
}

#ifdef GALAXY
vec3 draw_galaxy(vec3 ray_dir, out float galaxy_luminance) {
    const vec3 galaxy_tint = vec3(0.75, 0.66, 1.0) * GALAXY_INTENSITY;

    float galaxy_intensity = 0.05 + 1.0 * linear_step(-0.1, 0.25, -sun_dir.y);

    float lon = atan(ray_dir.x, ray_dir.z);
    float lat = fast_acos(-ray_dir.y);

    vec3 galaxy
        = texture(galaxy_sampler, vec2(lon * rcp(tau) + 0.5, lat * rcp(pi)))
              .rgb;

    galaxy = srgb_eotf_inv(galaxy) * rec709_to_working_color;

    galaxy *= galaxy_intensity * galaxy_tint;

    galaxy_luminance = dot(galaxy, luminance_weights_rec709);

    galaxy = mix(vec3(galaxy_luminance), galaxy, 2.0);

    return max0(galaxy);
}
#endif

vec3 draw_sky(
    vec3 ray_dir,
    vec3 atmosphere,
    vec4 clouds_and_aurora,
    float clouds_apparent_distance
) {
    vec3 sky = vec3(0.0);

#if defined SHADOW
    // Trick to make stars rotate with sun and moon
    mat3 rot = (sunAngle < 0.5)
        ? mat3(shadowModelViewInverse)
        : mat3(
              -shadowModelViewInverse[0].xyz,
              shadowModelViewInverse[1].xyz,
              -shadowModelViewInverse[2].xyz
          );

    vec3 celestial_dir = ray_dir * rot;
#else
    vec3 celestial_dir = ray_dir;
#endif

    // Black hole (Overworld + End mode)
    //
    // It is a distant object in space, so it is composited together with the
    // things drawn below it here, before the atmosphere and the clouds are
    // laid over the result: it fades into the daytime sky, disappears in rain
    // and behind clouds exactly like Photon's own stars and moon do.
    //
    // Depth order, near to far: sun and moon, then the black hole, then the
    // stars and the galaxy. So only the stars and the galaxy are seen through
    // the lens and hidden by the event horizon; the sun and the moon pass in
    // front of the black hole untouched. (Lensing the sun would also turn its
    // hard-edged, very bright disc into a full Einstein ring whenever the two
    // line up - the "drawn circle" removed from the End in V2.3.)
#if defined PROGRAM_DEFERRED4 && defined SKY_BLACK_HOLE
    // Where it is in the End's sky (its Azimuth and Elevation options), in
    // the Overworld too (v0.9.3: v0.9.0 - v0.9.2 placed it among the stars,
    // turning with them, which put it too high)
    vec3 black_hole_dir = end_black_hole_direction();
    vec3 black_hole_background_dir = ray_dir;
    float black_hole_transmittance;
    vec3 black_hole_glow;
    float black_hole_lens_magnification;
    float black_hole_lens_strength;
    draw_end_black_hole(
        black_hole_background_dir,
        black_hole_transmittance,
        black_hole_glow,
        black_hole_lens_magnification,
        black_hole_lens_strength,
        black_hole_dir,
        interleaved_gradient_noise(gl_FragCoord.xy, frameCounter)
    );
#if defined CONCEPT_OVERWORLD_BLACK_HOLE
    // By day (v0.9.4, v0.9.8) it stays: its disc nearly as bright, seen
    // through the blue of the air laid over it below, and its shadow a dark
    // hole in the blue ("Atmosphere" below); the clouds pass in front
    {
        float black_hole_night = smoothstep(0.08, -0.12, sun_dir.y);
        black_hole_glow *= mix(0.85, 1.0, black_hole_night);
    }
#endif
    // Intensity fades the whole effect in between 0 and 1; above 1 it only
    // boosts the emitted light (below), since mix() would extrapolate the
    // transmittance to negative values and turn the background behind the
    // black hole into negative light
    black_hole_transmittance = mix(
        1.0,
        black_hole_transmittance,
        min(END_BLACK_HOLE_INTENSITY, 1.0)
    );

    // How much of the disc is not covered by the nearer objects drawn below
    // (the moon and the planet). The disc's light is added after them, further
    // down, so it has to be masked by them explicitly.
    float black_hole_front_visibility = 1.0;

#if defined SHADOW
    celestial_dir = black_hole_background_dir * rot;
#else
    celestial_dir = black_hole_background_dir;
#endif
#endif

    // Galaxy

#ifdef GALAXY
    float galaxy_luminance;
    sky += draw_galaxy(celestial_dir, galaxy_luminance);
#else
    const float galaxy_luminance = 0.0;
#endif

#if defined CONCEPT_MILKY_WAY
    // The Milky Way (v0.9.4): among the stars, so at night only (as the
    // galaxy above: 5% by day, under the bright air)
    sky += draw_milky_way(celestial_dir)
        * (0.05 + 0.95 * linear_step(-0.1, 0.25, -sun_dir.y));
    // (hidden behind the black hole with the galaxy, just below)
#endif

    // Sun, moon stars

#if defined PROGRAM_DEFERRED4
#if defined SKY_BLACK_HOLE
    // The galaxy is behind the black hole: hide it behind the event horizon
    // and the thick parts of the disc. The disc's own light is added further
    // down, after the atmosphere's transmittance (see "Atmosphere")
    sky *= black_hole_transmittance;
#endif

    vec3 skytextured_output
        = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
    sky += texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;

#ifdef STARS
    // Stars
    float stars_visibility
        = clamp01(1.0 - dot(skytextured_output, vec3(0.33) * 256.0));
#if defined SKY_BLACK_HOLE
    // Behind the black hole too
    stars_visibility *= black_hole_transmittance;
#endif
#if defined CONCEPT_OVERWORLD_STARS
    // The Enhanced Star Field (v0.9.4) in place of Photon's stars, dimmed to
    // their brightness (the End's peak at 6 to 14, Photon's at about 1)
    sky += 0.12 * stars_visibility * end_stars(
        celestial_dir,
        2.0 / (gbufferProjection[1][1] * view_res.y * taau_render_scale),
        vec3(0.0, 1.0, 0.0), 0.0, 1.0, // (no lensing arcs: bent by the black hole's lens above)
        vec3(0.0, 1.0, 0.0), 1e6,      // (no stars pulled in)
        frameTimeCounter
    );
#else
    sky += draw_stars(celestial_dir, galaxy_luminance) * stars_visibility;
#endif
#if defined CONCEPT_OVERWORLD_SHOOTING_STARS
    // Shooting stars (v0.9.0), at night only, dimmer than in the End (the
    // night's exposure is much higher); the atmosphere and the clouds are
    // laid over them below, as over the stars
    sky += 0.25 * smoothstep(0.05, -0.15, sun_dir.y) * stars_visibility
        * end_shooting_stars(
            ray_dir,
            2.0 / (gbufferProjection[1][1] * view_res.y * taau_render_scale),
            frameTimeCounter
        );
#endif
#endif

#ifndef VANILLA_SUN
    // Shader sun
    sky += draw_sun(ray_dir);
#endif

#ifndef VANILLA_MOON
#if defined CONCEPT_PLANET_MOON
    // Our planet as the moon (see above): lit from where Photon's moon is
    // lit from in each phase (full at phase 0, new at phase 4)
    vec4 moon;
    {
        float phase_angle = 0.125 * tau * float(moonPhase);
        vec3 moon_left = normalize(cross(vec3(0.0, 1.0, 0.0), moon_dir) + vec3(1e-5, 0.0, 0.0));
        vec3 moon_light_dir = cos(phase_angle) * -moon_dir + sin(phase_angle) * moon_left;
        moon = draw_end_planet_at(
            ray_dir,
            moon_dir,
            moon_angular_radius * (float(OVERWORLD_PLANET_MOON_SIZE) * 0.01),
            moon_light_dir,
            vec3(16.0, 15.4, 14.4) // (sunlight, about as bright as Photon's moon)
        );
        moon.rgb *= moon.a; // (as Photon's moon: added over what it covers)
    }
#else
    // Shader moon
    vec4 moon = draw_moon(ray_dir);
#endif
    sky *= 1.0 - moon.a;
    sky += moon.rgb;
#if defined SKY_BLACK_HOLE
    black_hole_front_visibility *= 1.0 - moon.a;
#endif
#endif

#if defined SKY_PLANET
    // Planet (Overworld + End mode): the nearest of these objects, so it
    // covers the sun, the moon and the black hole when it passes in front of
    // them. Same world-space orbit as in the End (so the same parallax), lit
    // by Photon's own sunlight instead of the End's fixed light colour.
    vec4 planet = draw_end_planet(ray_dir, sun_dir, sun_color);
    sky = mix(sky, planet.rgb, planet.a);
#if defined SKY_BLACK_HOLE
    black_hole_front_visibility *= 1.0 - planet.a;
#endif
#endif
#endif

    // Atmosphere

    sky *= atmosphere_transmittance(ray_dir.y, planet_radius)
        * (1.0 - rainStrength);

#if defined PROGRAM_DEFERRED4 && defined SKY_BLACK_HOLE
    // Accretion disc light. Seen through only part of the atmosphere: with the
    // full transmittance above, a disc near the horizon kept ~55% of its End
    // brightness and lost most of its blue. Transmittance is exp(-optical
    // depth), so raising it to 0.35 is the same as crossing 35% of the air
    // column: the fading and reddening towards the horizon keep their shape,
    // just lighter. Rays that hit the ground have a transmittance of exactly
    // zero, and 0^0.35 is still zero, so the ground keeps hiding the black
    // hole below the horizon on its own.
    sky += black_hole_glow * END_BLACK_HOLE_INTENSITY
        * (1.0 - rainStrength)
        * black_hole_front_visibility
        * pow(atmosphere_transmittance(ray_dir.y, planet_radius), vec3(0.35));
#endif

#if defined PROGRAM_DEFERRED4 && defined SKY_BLACK_HOLE && defined CONCEPT_OVERWORLD_BLACK_HOLE
    // (v0.9.8) The black hole's shadow darkens the air's light behind it
    // too: a dark hole in the blue by day (not black - the air in front
    // still glows), barely different at night
    sky += atmosphere * mix(1.0, black_hole_transmittance, 0.65);
#else
    sky += atmosphere;
#endif

    // Clouds, aurora, crepuscular rays

    sky *= clouds_and_aurora.a; // Transmittance
    sky += clouds_and_aurora.rgb; // Scattering

    // Rainbow

    sky = draw_rainbows(
        sky,
        ray_dir,
        mix(clouds_apparent_distance,
            1e6,
            linear_step(1.0, 0.95, clouds_and_aurora.w))
    );

    // Cave sky fix

#if !defined PROGRAM_DEFERRED0
    // Fade lower part of sky into cave fog color when underground so that the
    // sky isn't visible beyond the render distance
    float underground_sky_fade
        = biome_cave * smoothstep(-0.1, 0.1, 0.4 - ray_dir.y);
    sky = mix(sky, vec3(0.0), underground_sky_fade);
#endif

    return sky;
}

#if defined PROGRAM_DEFERRED0
vec4 get_clouds_and_aurora(
    vec3 ray_dir,
    vec3 clear_sky,
    out float clouds_apparent_distance
) {
    clouds_apparent_distance = 1e6;

    ivec2 texel = ivec2(gl_FragCoord.xy);
    texel.x = texel.x % (sky_map_res.x - 4);

    float dither = interleaved_gradient_noise(vec2(texel));

    // Clouds

#ifndef BLOCKY_CLOUDS
    const vec3 air_viewer_pos = vec3(0.0, planet_radius, 0.0);
    CloudsResult result
        = draw_clouds(air_viewer_pos, ray_dir, clear_sky, -1.0, dither);

    // Lightning flash
    result.scattering.rgb += LIGHTNING_FLASH_UNIFORM * lightning_flash_intensity
        * result.scattering.a;
#else
    CloudsResult result = clouds_not_hit;
#endif

    clouds_apparent_distance = result.apparent_distance;

    // Aurora

    vec3 aurora = draw_aurora(ray_dir, dither);

    vec4 clouds_and_aurora = vec4(
        result.scattering.xyz + aurora * result.transmittance,
        result.transmittance
    );

    // Crepuscular rays

#if defined CREPUSCULAR_RAYS && !defined BLOCKY_CLOUDS
    vec4 crepuscular_rays
        = draw_crepuscular_rays(colortex8, ray_dir, false, 0.5);
    clouds_and_aurora *= crepuscular_rays.w;
    clouds_and_aurora.rgb += crepuscular_rays.xyz;
#endif

    return clouds_and_aurora;
}

vec3 draw_sky(vec3 ray_dir) {
    vec3 atmosphere = atmosphere_scattering(
        ray_dir,
        sun_color,
        sun_dir,
        moon_color,
        moon_dir,
        true
    );
    float clouds_apparent_distance;
    vec4 clouds_and_aurora
        = get_clouds_and_aurora(ray_dir, atmosphere, clouds_apparent_distance);
    return draw_sky(
        ray_dir,
        atmosphere,
        clouds_and_aurora,
        clouds_apparent_distance
    );
}
#endif

//----------------------------------------------------------------------------//
#elif defined WORLD_NETHER

vec3 draw_sky(vec3 ray_dir) { return ambient_color; }

//----------------------------------------------------------------------------//
#elif defined WORLD_END

#include "/include/misc/end_lighting_fix.glsl"
#include "/include/sky/atmosphere.glsl"
#include "/include/sky/end_stars.glsl"
#include "/include/sky/end_shooting_stars.glsl"
#include "/include/sky/end_void.glsl"
#include "/include/sky/stars.glsl"
#include "/include/lighting/end_black_hole_light.glsl"

// Planet in front of the black hole: the black hole's broad halo is dimmed by
// the share of its light the planet hides (end_planet_black_hole_visibility()
// below, declared here because draw_end_black_hole() uses it)
#if defined SKY_BLACK_HOLE && defined SKY_PLANET
float end_planet_black_hole_visibility();
#define BH_BROAD_HALO_OCCLUSION end_planet_black_hole_visibility()
#endif

#if defined SKY_BLACK_HOLE
#include "/include/sky/end_black_hole.glsl"
#endif

#if defined SKY_PLANET
#include "/include/sky/end_planet.glsl"
#endif

#include "/include/sky/end_nebula.glsl"

#if defined SKY_BLACK_HOLE && defined SKY_PLANET
// Share of the black hole's light that gets past the planet to world_pos:
// 1 = not eclipsed, 0 = fully hidden. Continuous as the planet moves.
//
// The black hole is seen as a luminous disc: 97% of its emission lies within
// 0.33 rad of its centre at the default Size (the bright lensed ring round the
// shadow), i.e. 1.5 black hole local units, scaled by the same camera
// distance as the drawn black hole so it follows Size. The planet is the real
// sphere on its orbit: its size is the one it is drawn with from the camera,
// seen from world_pos at its true distance, so the eclipse shifts slightly
// across the world like an object's shadow, not a screen-space mask. The
// visible share is the part of the black hole's disc outside the planet's
// (overlap of two circles, closed form: smooth at first and last contact).
const float EP_BH_SOURCE_RADIUS = 1.5; // black hole local units

float end_planet_black_hole_visibility(vec3 world_pos) {
    float apparent_scale
        = pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE;
    float cam_dist
        = max(BH_CAMERA_DISTANCE / apparent_scale, BH_MIN_CAMERA_DISTANCE);
    float source = EP_BH_SOURCE_RADIUS / cam_dist;

    vec3 planet_pos = end_planet_position();
    float planet_radius_blocks
        = length(planet_pos - cameraPosition)
        * sin(clamp(EP_RADIUS * END_PLANET_SIZE, 0.05, 1.45));
    vec3 to_planet = planet_pos - world_pos;
    float planet_distance = max(length(to_planet), 1.0);
    float planet = asin(clamp(planet_radius_blocks / planet_distance, 0.0, 0.999));

    float d = fast_acos(clamp(
        dot(to_planet / planet_distance, end_black_hole_direction()), -1.0, 1.0
    ));
    if (d >= planet + source) return 1.0; // no overlap
    if (d <= planet - source) return 0.0; // black hole entirely behind the planet
    if (d <= source - planet) {           // planet entirely inside the disc
        return 1.0 - sqr(planet / source);
    }
    // Area of the lens where the two discs overlap
    float d_safe = max(d, 1e-5);
    float a_source = sqr(source)
        * acos(clamp((d * d + source * source - planet * planet) / (2.0 * d_safe * source), -1.0, 1.0));
    float a_planet = sqr(planet)
        * acos(clamp((d * d + planet * planet - source * source) / (2.0 * d_safe * planet), -1.0, 1.0));
    float a_kite = 0.5 * sqrt(max(
        (-d + source + planet) * (d + source - planet) * (d - source + planet)
            * (d + source + planet),
        0.0
    ));
    return clamp01(1.0 - (a_source + a_planet - a_kite) / (pi * sqr(source)));
}

// Seen from the camera: the broad halo and the light colour of the frame
float end_planet_black_hole_visibility() {
    return end_planet_black_hole_visibility(cameraPosition);
}
#endif

const float sun_solid_angle = cone_angle_to_solid_angle(sun_angular_radius);
const vec3 end_sun_color = vec3(1.0, 0.5, 0.25);

// The sun can be drawn towards any direction: the black hole moves it (and the
// glow around it) away from `sun_dir` so it stays right behind the black hole
vec3 draw_sun(vec3 ray_dir, vec3 sun_direction) {
    float nu = dot(ray_dir, sun_direction);
    float r = fast_acos(nu);

    // Sun disk

    const vec3 alpha = vec3(0.6, 0.5, 0.4);
    float center_to_edge = max0(sun_angular_radius - r);
    vec3 limb_darkening
        = pow(vec3(1.0 - sqr(1.0 - center_to_edge)), 0.5 * alpha);

#if defined SKY_BLACK_HOLE
    // With the black hole enabled the sun can be seen through its lens, which
    // stretches it into a long arc. Photon draws the disc as a binary step
    // (limb_darkening is computed here but unused), and a hard-edged,
    // uniformly saturated arc is exactly what reads as a circle drawn on top
    // of the sky - the artefact this version set out to remove. Applying the
    // limb darkening that is already computed and softening the edge costs
    // nothing and makes the sun behave like a light source instead. Guarded,
    // so that with the black hole off Photon's own sun is untouched.
    vec3 sun_disk = limb_darkening
        * (1.0 - smoothstep(0.85 * sun_angular_radius, sun_angular_radius, r));
#else
    vec3 sun_disk = vec3(r < sun_angular_radius);
#endif

    // Solar flare effect

    // Transform the coordinate space such that z is parallel to sun_direction
    vec3 tangent = sun_direction.y == 1.0
        ? vec3(1.0, 0.0, 0.0)
        : normalize(cross(vec3(0.0, 1.0, 0.0), sun_direction));
    vec3 bitangent = normalize(cross(tangent, sun_direction));
    mat3 rot = mat3(tangent, bitangent, sun_direction);

    // Vector from ray dir to sun dir
    vec2 q = ((ray_dir - sun_direction) * rot).xy;

    float theta = fract(
        linear_step(-pi, pi, atan(q.y, q.x)) + 0.015 * frameTimeCounter
        - 0.33 * r
    );

    float flare
        = texture(noisetex, vec2(theta, r - 0.025 * frameTimeCounter)).x;
    flare = pow5(flare) * exp(-25.0 * (r - sun_angular_radius));
    flare = r < sun_angular_radius ? 0.0 : flare;

    return end_sun_color * rcp(sun_solid_angle) * max0(sun_disk + 0.1 * flare);
}

vec3 draw_sun(vec3 ray_dir) {
    return draw_sun(ray_dir, sun_dir);
}

vec3 draw_sky(vec3 ray_dir) {
    // The End sun stays where Photon puts it, on `sun_dir`.
    //
    // Earlier versions moved it onto the black hole's axis so it would be
    // lensed into a bright ring around it. That ring was the "artificial white
    // circle": a source sitting exactly on the axis is lensed into a complete
    // Einstein ring, and because the sun disc was a binary step at a very high
    // luminance, that ring came out as a perfectly uniform, hard-edged white
    // circle - one that no amount of tuning inside the accretion disc could
    // affect, because it was never part of the disc. Keeping the sun on its
    // own direction is what removes it; the bright rim that remains around the
    // shadow is the disc's own light bent around the hole.
    vec3 end_sun_dir = sun_dir;

#if defined CONCEPT_CINEMATIC_VOID
    // Cinematic Void: a deep-space background (include/sky/end_void.glsl) in
    // place of Photon's purple gradient and of its glow towards the End sun,
    // which is not drawn in this pack. Only this background layer changes:
    // everything below (black hole, sun, stars, planet) is the same code for
    // both sky styles.
    vec3 sky = end_void_background(ray_dir);
#else
    // Sky gradient

    float up_gradient
        = linear_step(0.0, 0.4, ray_dir.y) + linear_step(0.1, 0.8, -ray_dir.y);
    vec3 sky = ambient_color * mix(0.1, 0.04, up_gradient);
    float mie_phase = cornette_shanks_phase(dot(ray_dir, end_sun_dir), 0.6);
    sky += 0.1 * (ambient_color + 0.5 * end_sun_color) * mie_phase;
#endif

#if defined CONCEPT_END_NEBULA_BUFFERED
    // The nebula's far part and front (v0.7.7 - v0.7.9, Frame Accumulation):
    // drawn by deferred2 and averaged over the frames, following the camera
    // (include/sky/end_nebula_buffer.glsl)
    EndNebulaLayers nebula_layers = end_nebula_buffer_read(ivec2(gl_FragCoord.xy));
#endif

#if defined PROGRAM_DEFERRED4
    // The planet, found first (v0.7.4, optimization). It is drawn last, over
    // everything but the nebula's close wisps (see the end of this function):
    // where it covers the pixel completely nothing behind it is seen, so
    // nothing behind it is drawn - the black hole, the nebula, the stars and
    // the dust are skipped there, the largest saving there is when the
    // planet is in view. The pixel is exactly what it was (the planet's own
    // colour, then the close wisps over it).
#if defined SKY_PLANET
#if defined CONCEPT_BH_LIGHT
    // Environmental Light: the planet is lit by the black hole, like the
    // terrain (the same light, scaled to the sky's brightness: 0.7 at the
    // default options in Cinematic Void, like the End sun's it replaces).
    // With the black hole behind it, it shows its night side outlined by
    // the backlit atmosphere (draw_end_planet())
    vec4 planet = draw_end_planet(
        ray_dir,
        end_black_hole_direction(),
        concept_bh_light_color() * (0.7 / 5.0)
    );
#else
    vec4 planet = draw_end_planet(ray_dir, end_sun_dir);
#endif
    if (planet.a >= 1.0) {
        sky = planet.rgb;
#if defined CONCEPT_END_NEBULA
        float planet_pixel = 2.0
            / (gbufferProjection[1][1] * view_res.y * taau_render_scale);
        float planet_view_cos
            = clamp(dot(ray_dir, -gbufferModelViewInverse[2].xyz), 0.05, 1.0);
        planet_pixel *= planet_view_cos * sqrt(planet_view_cos);
        mat2x3 planet_wisps
            = end_nebula_close_wisps(ray_dir, end_nebula_field(), planet_pixel);
        sky = sky * planet_wisps[1] + planet_wisps[0];
#endif
        return sky;
    }
#endif

    // Black hole
    //
    // Gravitationally lenses the background direction used for the sun and
    // stars below, and occludes/adds to it with the accretion disc. When
    // disabled, background_dir/background_transmittance/black_hole_glow
    // simply leave the sun and stars untouched, exactly as before.

    vec3 background_dir = ray_dir;
    float black_hole_transmittance = 1.0;
    vec3 black_hole_glow = vec3(0.0);
    float black_hole_lens_magnification = 1.0;
    float black_hole_lens_strength = 0.0;

#if defined SKY_BLACK_HOLE
    vec3 black_hole_dir = end_black_hole_direction();
    float black_hole_dither
        = interleaved_gradient_noise(gl_FragCoord.xy, frameCounter);
    draw_end_black_hole(
        background_dir,
        black_hole_transmittance,
        black_hole_glow,
        black_hole_lens_magnification,
        black_hole_lens_strength,
        black_hole_dir,
        black_hole_dither
    );
    // Intensity fades the whole effect in between 0 and 1; above 1 it only
    // boosts the emitted light (black_hole_glow below). The occlusion and the
    // lensing stop at full strength: mix() would otherwise extrapolate the
    // transmittance to negative values and turn the sun and the stars behind
    // the black hole into negative light.
    black_hole_transmittance = mix(
        1.0,
        black_hole_transmittance,
        min(END_BLACK_HOLE_INTENSITY, 1.0)
    );
    black_hole_lens_strength *= min(END_BLACK_HOLE_INTENSITY, 1.0);

    // The event horizon (and optically thick parts of the disc) also hide the
    // sky gradient behind them, so the core is actually dark instead of
    // showing the purple sky through it
    sky *= smoothstep(0.0, 0.3, black_hole_transmittance);
#endif

    // How much of the distant stars gets through the nebula's part behind the
    // black hole (v0.6.8, v0.6.9): its dust hides the stars behind it and its
    // dense gas veils them, so the stars are in the nebula rather than pasted
    // over it
#if defined CONCEPT_END_STARS
    vec3 star_veil = vec3(1.0);
#endif

#if defined CONCEPT_END_NEBULA
    // Nebula (include/sky/end_nebula.glsl, v0.7.1.6: the Eagle in the Hubble
    // palette): its part behind the black hole, in front of the distant stars. Looked up
    // along the lensed direction and hidden by the black hole's shadow and
    // disc, exactly like the stars; its dust dims the background behind it.
    // Angular size of a pixel as for the stars below, to fade out detail finer
    // than the screen can show.
    float nebula_pixel = 2.0
        / (gbufferProjection[1][1] * view_res.y * taau_render_scale);
    float nebula_view_cos
        = clamp(dot(ray_dir, -gbufferModelViewInverse[2].xyz), 0.05, 1.0);
    nebula_pixel *= nebula_view_cos * sqrt(nebula_view_cos);

    // The sky's luminance before the nebula (the cosmic dust particles
    // scatter only the nebula's own light)
    float nebula_base_luminance = end_nebula_luminance(sky);

    EndNebulaField nebula_field = end_nebula_field();
    // (v0.7.4: not in the black hole's shadow, where all of it is hidden)
    mat2x3 nebula = mat2x3(vec3(0.0), vec3(1.0));
#if defined CONCEPT_END_NEBULA_BUFFERED
    // (v0.7.5 - v0.7.9, Frame Accumulation - drawn by deferred2, through the
    // lens: see include/sky/end_nebula_buffer.glsl)
    vec4 nebula_part = nebula_layers.back;
    nebula = mat2x3(nebula_part.rgb, end_nebula_buffer_transmittance(nebula_part.a));
#else
    if (black_hole_transmittance > 0.0) {
        nebula = end_nebula_behind(background_dir, nebula_field, nebula_pixel);
    }
#endif
    sky = sky * nebula[1] + nebula[0] * black_hole_transmittance;
#if defined CONCEPT_END_STARS
    star_veil *= nebula[1] * end_nebula_star_veil(nebula[0]);
#endif

    // Photon Original: a darker surround behind the black hole's outer disc,
    // so its light (added below) keeps its outline against the purple (1 in
    // the Cinematic Void)
    sky *= end_nebula_black_hole_surround(ray_dir);
#endif

    // Sun

#ifdef END_SUN_EFFECT
    sky += draw_sun(background_dir, end_sun_dir) * black_hole_transmittance;
#endif

    // Stars

#if defined CONCEPT_END_STARS
    // Enhanced Star Field (include/sky/end_stars.glsl), in both sky styles:
    // over the whole sphere (no fade below the horizon: the Void under the
    // island is full of stars too; the End fog still dims them where it is
    // thick), in neutral colours (no .xzy swap, no purple-tinted fade). With
    // Enhanced Star Field off, the #else branch is Photon's own field,
    // unchanged.
    //
    // Angular size of this pixel, for sharp but never sub-pixel stars: a
    // pinhole camera's pixel spans 2 / (projection[1][1] * height) radians at
    // the centre of the screen and gets smaller away from it: its solid angle
    // goes with cos^3 of the angle off the view axis, so its linear size with
    // about cos^1.5. Computed from the view ray rather than with derivatives,
    // which are undefined here (the sky is drawn inside a branch on the
    // depth).
    float star_pixel = 2.0
        / (gbufferProjection[1][1] * view_res.y * taau_render_scale);
    float star_view_cos
        = clamp(dot(ray_dir, -gbufferModelViewInverse[2].xyz), 0.05, 1.0);
    star_pixel *= star_view_cos * sqrt(star_view_cos);

#if defined SKY_BLACK_HOLE
    vec3 star_tangent;
    float star_arc, star_gain;
    bh_star_lens(
        background_dir,
        black_hole_dir,
        black_hole_lens_magnification,
        black_hole_lens_strength,
        star_tangent,
        star_arc,
        star_gain
    );
    vec3 star_hole_dir = black_hole_dir;
    float star_hole_distance = bh_impact(ray_dir);
#else
    const vec3 star_tangent = vec3(0.0, 1.0, 0.0);
    const float star_arc = 0.0;
    const float star_gain = 1.0;
    const vec3 star_hole_dir = vec3(0.0, 1.0, 0.0);
    const float star_hole_distance = 1e6; // no black hole: no pulled stars
#endif

    // (v0.7.4: not in the black hole's shadow, where they are hidden)
    if (black_hole_transmittance > 0.0)
    sky += end_stars(
        background_dir,
        star_pixel,
        star_tangent,
        star_arc,
        star_gain,
        star_hole_dir,
        star_hole_distance,
        frameTimeCounter
    ) * black_hole_transmittance * star_veil;

    // Intermediate stars (v0.6.8): at 6 000 blocks, among the nebula, in front
    // of its part behind the black hole and behind its part in front (real
    // parallax; kept clear round the black hole, which they are in front of)
#if defined SKY_BLACK_HOLE
    const bool star_has_hole = true;
#else
    const bool star_has_hole = false;
#endif
    sky += end_stars_middle(
        ray_dir, cameraPosition, star_hole_dir, star_has_hole, star_pixel, frameTimeCounter
    );

    // The nebula's young cluster (v0.7.1.6): among its heart, in front of the
    // lit cavity wall, so not veiled by the nebula's far part; bent by the
    // black hole like the distant stars
    if (black_hole_transmittance > 0.0)
    sky += end_stars_cluster_stars(
        background_dir, star_pixel, star_tangent, star_arc, star_gain, frameTimeCounter
    ) * black_hole_transmittance;
#else
    vec3 stars_fade
        = exp2(-0.1 * max0(1.0 - background_dir.y) / max(ambient_color, eps))
        * linear_step(-0.2, 0.0, background_dir.y);
#if defined SKY_BLACK_HOLE
    vec3 end_stars = bh_draw_lensed_stars(
        background_dir,
        black_hole_dir,
        black_hole_lens_magnification,
        black_hole_lens_strength
    );
#else
    vec3 end_stars = draw_stars(background_dir, 0.0);
#endif
    sky += end_stars.xzy * stars_fade * black_hole_transmittance;
#endif

#if defined SKY_BLACK_HOLE
    sky += black_hole_glow * END_BLACK_HOLE_INTENSITY;
#endif

#if defined CONCEPT_END_NEBULA_BUFFERED
    // The nebula's sea, its canopy and its near part (see below), with
    // Temporal Upscaling (v0.7.5, v0.7.7): one layer, already put together by
    // deferred2 - its light, how much the sea and the canopy let through, and
    // its dust
    sky = sky * (nebula_layers.through
            * mix(vec3(1.0), end_nebula_buffer_transmittance(nebula_layers.front.a), end_nebula_black_hole_surround(ray_dir)))
        + nebula_layers.front.rgb;
#endif

#if defined CONCEPT_END_NEBULA && !defined CONCEPT_END_NEBULA_BUFFERED
    // The nebula's basin (v0.7.1.9): the luminous sea of gas below the island,
    // a surface in front of the nebula's far part and the stars, behind its
    // near part
    nebula = end_nebula_basin(ray_dir, nebula_field, nebula_pixel);
    sky = sky * nebula[1] + nebula[0];
    // ... and its canopy (v0.7.1.12), the same kind of layer high in the sky
    nebula = end_nebula_canopy(ray_dir, nebula_field, nebula_pixel);
    sky = sky * nebula[1] + nebula[0];

    // Nebula, the part in front: over the black hole (not bent by it) and the
    // stars behind it, which its dust can hide. Still behind the planet,
    // drawn over it next.
    nebula = end_nebula_front(ray_dir, nebula_field, nebula_pixel);
    sky = sky * nebula[1] + nebula[0];
#endif

#if defined CONCEPT_END_STARS
    // Near stars (v0.6.8): a few at 2 200 blocks, in front of the nebula (the
    // strongest parallax of the stars)
    sky += end_stars_near(
        ray_dir, cameraPosition, star_hole_dir, star_has_hole, star_pixel, frameTimeCounter
    );
#endif

#ifdef END_SHOOTING_STARS
#if END_SHOOTING_STARS_WORLD == CONCEPT_WORLD_END || END_SHOOTING_STARS_WORLD == CONCEPT_WORLD_BOTH
    // Shooting stars (v0.8.1, include/sky/end_shooting_stars.glsl): over the
    // nebula and the stars, behind the planet and the close wisps
    sky += end_shooting_stars(
        ray_dir,
        2.0 / (gbufferProjection[1][1] * view_res.y * taau_render_scale),
        frameTimeCounter
    );
#endif
#endif

#if defined CONCEPT_END_NEBULA
    // The cosmic dust particles, around you
    sky = end_nebula_particles(ray_dir, nebula_field, sky, nebula_base_luminance, nebula_pixel);
#endif

    // Colossal planet in the foreground.
    //
    // Drawn last and sampled along the RAW ray direction (not background_dir,
    // which is the black hole's lensed direction used for everything behind
    // it): a foreground object isn't bent by gravity it hasn't reached yet.
    // Compositing it last, over the finished disc/glow/stars/sun, is what
    // makes it occlude all of them wherever it covers the screen, the same
    // way a real body eclipsing the sky behind it would.
    //
    // Entirely independent of the black hole: its own toggle, its own place in
    // the sky, its own light source. Neither needs the other to compile or to
    // draw.
#if defined SKY_PLANET
    // (v0.7.4: the planet itself is found at the top of this function)
    sky = mix(sky, planet.rgb, planet.a);
#endif

#if defined CONCEPT_END_NEBULA
    // The nebula's close wisps (v0.7.1.9): thin gas near the island, nearer
    // than the planet's orbit, so drawn over it and everything else
    // (always drawn here, every frame: near enough to shift as you walk,
    // they are not kept from frame to frame like the rest of the nebula)
    nebula = end_nebula_close_wisps(ray_dir, nebula_field, nebula_pixel);
    sky = sky * nebula[1] + nebula[0];
#endif
#endif

    return sky;
}

#endif

#endif // INCLUDE_SKY_SKY
