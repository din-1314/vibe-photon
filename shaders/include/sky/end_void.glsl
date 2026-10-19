#if !defined INCLUDE_SKY_END_VOID
#define INCLUDE_SKY_END_VOID

/*
--------------------------------------------------------------------------------

  include/sky/end_void:
  Cinematic Void, the Concept's deep-space End sky style.

  Photon Original (the other style) is, by definition, Photon's own End left
  exactly as it is. So everything the Cinematic Void changes lives behind
  CONCEPT_CINEMATIC_VOID, and with Photon Original selected this file adds no
  code at all.

  What the Cinematic Void replaces is only where Photon's End gets its purple:
    - the sky background (Photon's ambient-coloured gradient and the glow
      towards the unseen End sun), replaced by end_void_background() below,
      in draw_sky() in include/sky/sky.glsl;
    - the colour of the light the End fog adds (see "End fog in the Cinematic
      Void" below), in include/fog/end_fog_vl.glsl.
  Everything drawn on top of the background (black hole, stars, planet, sun)
  and the terrain lighting are shared with Photon Original unchanged.

  This is also where the later Cinematic Void layers (star field, nebula)
  are meant to be added.

--------------------------------------------------------------------------------
*/

#if defined WORLD_END && CONCEPT_SKY_STYLE == CONCEPT_SKY_CINEMATIC_VOID
#define CONCEPT_CINEMATIC_VOID
#endif

#if defined CONCEPT_CINEMATIC_VOID

#include "/include/sky/end_sky_common.glsl"
#include "/include/utility/color.glsl"

// End fog in the Cinematic Void
//
// The fog keeps absorbing light exactly as in Photon Original (distant
// terrain keeps its depth, and the black hole and planet are seen through it
// unchanged). What changes is only the colour of the light it adds:
//
//  - Directional light. Photon's End fog scatters the End sun's light, whose
//    colour (END_LIGHT, 1.00 0.50 0.25 by default) is orange-red. Under
//    Photon's purple it is hidden, but in the void it was the dominant
//    colour of the whole sky: a "sunset" around the horizon (where the view
//    ray runs longest through the dense layer of fog at island height) and a
//    red cast up and down. The End sun is not drawn in this pack, so nothing
//    justifies that glow here. The directional light will come back from the
//    black hole in the lighting phase.
//  - Ambient light and End Glow. Their purple (END_AMBIENT) became a pink /
//    violet tint. Both keep their brightness and their shape (the horizon
//    haze that gives depth, and the End Glow's slow swirls), but take a cold,
//    nearly neutral colour instead.
const float end_void_fog_light_scale = 0.0; // End sun light scattered by the fog
const vec3 end_void_fog_haze_color = vec3(0.022, 0.029, 0.040); // replaces 15% of END_AMBIENT (same luminance)
const vec3 end_void_fog_glow_tint = vec3(0.80, 1.00, 1.30);     // End Glow colour, by luminance
const float end_void_fog_glow_scale = 0.12; // End Glow brightness

// Deep-space background colours (sRGB-authored, converted to the working
// colour space). Very dark, but not black: a cold deep blue, drifting towards
// a slightly more violet and a slightly more teal shade across the sky.
const vec3 end_void_base_color = from_srgb(vec3(0.020, 0.024, 0.040));
const vec3 end_void_violet_tint = vec3(1.10, 0.85, 1.20);
const vec3 end_void_teal_tint = vec3(0.80, 1.10, 1.05);

// Background of the Cinematic Void sky, in place of Photon's purple gradient.
//
// Two octaves of value noise evaluated on the view direction (a point on the
// unit sphere, so there is no seam anywhere) give very large, soft variations
// in brightness and hue. They depend only on the direction, not on time or on
// the camera position, so the background is perfectly stable: it never moves,
// flickers or shows parallax.
vec3 end_void_background(vec3 ray_dir) {
    float large = end_sky_value_noise(ray_dir * 1.6 + 3.1);
    float small = end_sky_value_noise(ray_dir * 4.3 + 17.7);
    float hue = end_sky_value_noise(ray_dir * 1.1 - 8.4);

    float variation = large * 0.7 + small * 0.3;
    float brightness = mix(0.55, 1.45, smoothstep(0.2, 0.8, variation));

    vec3 tint
        = mix(end_void_violet_tint, end_void_teal_tint, smoothstep(0.3, 0.7, hue));

    // A little darker straight up and straight down than around the horizon,
    // so the void still has a sense of direction instead of being uniform
    float vertical = 1.0 - 0.25 * sqr(ray_dir.y);

    return end_void_base_color * tint * (brightness * vertical);
}

#endif // CONCEPT_CINEMATIC_VOID

#endif // INCLUDE_SKY_END_VOID
