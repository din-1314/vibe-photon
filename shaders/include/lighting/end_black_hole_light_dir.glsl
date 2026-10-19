// include/lighting/end_black_hole_light_dir:
// Declares `light_dir` in the programs that light surfaces or fog in the End,
// in place of their own `uniform vec3 light_dir;` (see end_black_hole_light.glsl).
//
// Environmental Light on: a constant pointing at the black hole (a constant,
// not a macro, so functions that take a parameter named light_dir are not
// affected). Off, or without a black hole: exactly the original uniform.
//
// No include guard on purpose: each program includes it once, where it used
// to declare the uniform.

#include "/include/lighting/end_black_hole_light.glsl"

#if defined CONCEPT_BH_LIGHT
const vec3 light_dir = concept_bh_light_dir;
#else
uniform vec3 light_dir;
#endif
