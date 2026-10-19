// include/lighting/end_black_hole_shadow_view:
// Declares `shadowModelView` in the programs that render or read the shadow
// map in the End, in place of their own `uniform mat4 shadowModelView;` (see
// end_black_hole_light.glsl).
//
// Environmental Light on: every later use of shadowModelView becomes the
// black hole's shadow view, so the shadow pass writes the map from the black
// hole and every reader (PCSS/PCF, volumetric fog, translucents) looks it up
// the same way. Off, or without a black hole: exactly the original uniform.
//
// No include guard on purpose: each program includes it once, where it used
// to declare the uniform.

#include "/include/lighting/end_black_hole_light.glsl"

uniform mat4 shadowModelView;

#if defined CONCEPT_BH_LIGHT
#define shadowModelView concept_bh_shadow_view(cameraPosition)
#endif
