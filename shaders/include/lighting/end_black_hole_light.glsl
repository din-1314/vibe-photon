#if !defined INCLUDE_LIGHTING_END_BLACK_HOLE_LIGHT
#define INCLUDE_LIGHTING_END_BLACK_HOLE_LIGHT

/*
--------------------------------------------------------------------------------

  include/lighting/end_black_hole_light:
  Black Hole Environmental Light (Photon Cinematic Concept, End only).

  The black hole becomes the End's directional light: Photon's own End light
  (the "End sun") is pointed at the black hole and given the black hole's
  light, and Photon's shadow map is rendered from the black hole. Everything
  else is Photon's existing lighting: diffuse, specular, SSS, PCSS/PCF,
  screen-space shadows and the volumetric fog read the same light direction,
  shadow map and light colour as before. No second light and no second
  shadow system.

  With Environmental Light off (or without a black hole in the End) this file
  defines nothing but a few macros, and every program compiles to exactly
  what it was before.

  How the pieces reach the programs:
    - light_dir: the programs that light surfaces in the End declare it
      through end_black_hole_light_dir.glsl, which turns the uniform into a
      constant pointing at the black hole.
    - shadow map: the programs that render or read the shadow map declare
      shadowModelView through end_black_hole_shadow_view.glsl, which swaps it
      for concept_bh_shadow_view() below. shadowModelViewInverse is left
      alone: the shadow pass uses it to undo Iris' own shadow camera.
    - light colour and ambient: get_light_color() / get_ambient_color() in
      include/lighting/colors/end_color.glsl.

--------------------------------------------------------------------------------
*/

// Enabled only in the End, only when the black hole is drawn there (same
// world condition as include/sky/sky.glsl), and only with the option on.
// Plain #ifdef on purpose: Iris only lists a boolean option in the menu when
// it is tested with #ifdef/#ifndef.
#if defined WORLD_END && (END_BLACK_HOLE_WORLD == CONCEPT_WORLD_END || END_BLACK_HOLE_WORLD == CONCEPT_WORLD_BOTH)
#ifdef END_BLACK_HOLE
#ifdef END_BLACK_HOLE_LIGHT
#define CONCEPT_BH_LIGHT
#endif
#endif
#endif

// ... and when the planet is drawn in the End as well, it can eclipse the black
// hole's light (same world condition as include/sky/sky.glsl's planet)
#if defined CONCEPT_BH_LIGHT && (END_PLANET_WORLD == CONCEPT_WORLD_END || END_PLANET_WORLD == CONCEPT_WORLD_BOTH)
#ifdef END_PLANET
#define CONCEPT_PLANET_ECLIPSE
#endif
#endif

#if defined CONCEPT_BH_LIGHT

// Direction towards the black hole (world space, y up). Same formula and
// options as end_sky_direction() / end_black_hole_direction(), so the light
// comes from exactly where the black hole is drawn. Constant: it never
// depends on the camera or on the black hole being on screen.
const float concept_bh_light_azimuth = radians(float(END_BLACK_HOLE_AZIMUTH));
const float concept_bh_light_elevation = radians(float(END_BLACK_HOLE_ELEVATION));
const vec3 concept_bh_light_dir = vec3(
    sin(concept_bh_light_azimuth) * cos(concept_bh_light_elevation),
    sin(concept_bh_light_elevation),
    -cos(concept_bh_light_azimuth) * cos(concept_bh_light_elevation)
);

// Shadow camera basis: z points towards the light (the shadow camera looks
// down -z, like Iris' own), x and y span the shadow map. The reference axis
// switches away from y near the zenith so the cross product never degenerates
// (its length is always > 0.14).
const vec3 concept_bh_shadow_z = concept_bh_light_dir;
const vec3 concept_bh_shadow_ref = abs(concept_bh_light_dir.y) > 0.99
    ? vec3(1.0, 0.0, 0.0)
    : vec3(0.0, 1.0, 0.0);
const vec3 concept_bh_shadow_x
    = normalize(cross(concept_bh_shadow_ref, concept_bh_shadow_z));
const vec3 concept_bh_shadow_y = cross(concept_bh_shadow_z, concept_bh_shadow_x);

// Shadow view matrix (scene space -> shadow view space), used in place of
// Iris' shadowModelView by the shadow pass and by every reader of the map.
//   x, y: the map is anchored to the world in steps of shadowIntervalSize
//         blocks (what Iris does for its own matrix): between two steps a
//         world position always lands on the same shadow texel, so shadows
//         do not swim while the camera moves. The step is in blocks, so it
//         does not depend on the shadow resolution or distance.
//   z:    the camera sits 100 blocks from the near plane, exactly where Iris
//         puts it in its own shadow camera, so Iris' shadowProjection (and
//         Photon's SHADOW_DEPTH_SCALE) keep the depth range they were made
//         for: casters up to ~500 blocks towards the black hole are kept,
//         enough for the long shadows of a low black hole.
mat4 concept_bh_shadow_view(vec3 camera_position) {
    vec2 camera_xy = vec2(
        dot(concept_bh_shadow_x, camera_position),
        dot(concept_bh_shadow_y, camera_position)
    );
    vec2 offset_xy = mod(camera_xy, shadowIntervalSize);

    return mat4(
        vec4(concept_bh_shadow_x.x, concept_bh_shadow_y.x, concept_bh_shadow_z.x, 0.0),
        vec4(concept_bh_shadow_x.y, concept_bh_shadow_y.y, concept_bh_shadow_z.y, 0.0),
        vec4(concept_bh_shadow_x.z, concept_bh_shadow_y.z, concept_bh_shadow_z.z, 0.0),
        vec4(offset_xy, -100.0, 1.0)
    );
}

// Light colour (working colour space), a fixed value derived from the black
// hole's emission - never from the animated disc, so it cannot pulse.
//
// Tint: the black hole's emission integrated over its whole image (disc,
// near and broad halo, at the default options: numerical integration of
// draw_end_black_hole()) comes out blue-white, 0.65 : 1.05 : 1.92 at unit
// luminance (the 8000 K inner disc reads cyan in Photon's 3-wavelength
// blackbody). A quarter of that tint is kept: a cool white, the colour the
// saturated core of the black hole is seen in.
const vec3 concept_bh_light_tint_base = vec3(0.9135, 1.0133, 1.2303); // luminance 1
// Colour options (v0.7.7, screen Black Hole Colour): the black hole's red,
// green and blue (in rec709; all 1.00: unchanged) colour the light it casts
// too - the terrain, the fog and the planet are lit in the colour it is seen
// in. (the matrices are include/utility/color.glsl's rec2020_to_rec709 and
// rec709_to_rec2020, written out: not every program that lights includes it)
const mat3 concept_bh_light_to_rec709 = mat3(
     1.6604910, -0.5876411, -0.0728499,
    -0.1245505,  1.1328999, -0.0083494,
    -0.0181508, -0.1005789,  1.1187297
);
const mat3 concept_bh_light_from_rec709 = mat3(
    0.6274039, 0.3292830, 0.0433131,
    0.0690973, 0.9195404, 0.0113623,
    0.0163914, 0.0880133, 0.8955953
);
const vec3 concept_bh_light_tint = max(
    (concept_bh_light_tint_base * concept_bh_light_to_rec709)
        * vec3(END_BLACK_HOLE_TINT_R, END_BLACK_HOLE_TINT_G, END_BLACK_HOLE_TINT_B),
    vec3(0.0)
) * concept_bh_light_from_rec709;
// Strength: follows the black hole's emission options (Intensity x Disc
// Brightness), linear up to the default and compressed above it (x3 -> x2),
// so turning the black hole up cannot blow the terrain and fog out to white.
const float concept_bh_light_emission
    = float(END_BLACK_HOLE_INTENSITY) * float(END_BLACK_HOLE_DISC_BRIGHTNESS);
const float concept_bh_light_level = concept_bh_light_emission <= 1.0
    ? concept_bh_light_emission
    : 1.0 + 0.5 * (concept_bh_light_emission - 1.0);
// Luminance at the default options, calibrated with Photon's lighting and
// tonemap against the IterationT references (lit End stone ~150 sRGB with the
// black hole 12 degrees up, shadows ~20% of the light in Cinematic Void).
// Photon Original keeps more of its purple ambient in the mix.
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
const float concept_bh_light_luminance = 5.0 * 0.75;
#else
const float concept_bh_light_luminance = 5.0;
#endif

vec3 concept_bh_light_color() {
    return concept_bh_light_tint
        * (concept_bh_light_luminance * concept_bh_light_level);
}

// The ambient light (Cinematic Void's cool base ambient, Photon Original's
// purple) is in include/lighting/colors/end_color.glsl: it belongs to the sky
// style, not to this option.

#endif // CONCEPT_BH_LIGHT

#endif // INCLUDE_LIGHTING_END_BLACK_HOLE_LIGHT
