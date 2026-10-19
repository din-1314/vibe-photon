#if !defined INCLUDE_LIGHTING_COLORS_END_COLOR
#define INCLUDE_LIGHTING_COLORS_END_COLOR

#include "/include/lighting/end_black_hole_light.glsl"
#include "/include/utility/color.glsl"

// Cinematic Void is a neutral, deep-space End: its light and ambient are never
// Photon's orange and purple, whether the black hole lights the End or not.
// Photon Original keeps Photon's colours.
//
// Base ambient: the same restrained cool light with or without Environmental
// Light (the toggle only adds or removes the black hole's directional light).
// Photon's purple ambient is not simply neutralised at equal luminance: its
// strength was chosen for a saturated purple scene, and made grey it leaves
// the terrain close to black. 0.30 is the level calibrated for the black
// hole's light (shadows readable, about a fifth of the lit ground); it follows
// the End Ambient intensity option (0.30 at its default of 0.75).
// Without Environmental Light, the directional light is Photon's End light at
// the strength of its End Light options, only neutral in colour.
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_CINEMATIC_VOID
const vec3 end_void_light_tint = vec3(1.0); // luminance 1
const vec3 end_void_ambient
    = vec3(0.862, 1.024, 1.347) * (0.30 / 0.75 * END_AMBIENT_I); // cool, luminance 1 x strength
#endif

vec3 get_light_color() {
#if defined CONCEPT_BH_LIGHT
    // Environmental Light: the black hole's light replaces the End sun's
    return concept_bh_light_color();
#elif CONCEPT_SKY_STYLE == CONCEPT_SKY_CINEMATIC_VOID
    return end_void_light_tint * dot(
        from_srgb(vec3(END_LIGHT_R, END_LIGHT_G, END_LIGHT_B)) * END_LIGHT_I,
        luminance_weights_rec2020
    );
#else
    return from_srgb(vec3(END_LIGHT_R, END_LIGHT_G, END_LIGHT_B)) * END_LIGHT_I;
#endif
}

vec3 get_ambient_color() {
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_CINEMATIC_VOID
    return end_void_ambient;
#else
    return from_srgb(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B))
        * END_AMBIENT_I;
#endif
}

#endif
