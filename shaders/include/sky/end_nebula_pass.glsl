#if !defined INCLUDE_SKY_END_NEBULA_PASS
#define INCLUDE_SKY_END_NEBULA_PASS

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.7.5, v0.7.7)

  include/sky/end_nebula_pass:
  What deferred2 needs to draw the End nebula's quarter of the frame (Temporal
  Upscaling, see include/sky/end_nebula_buffer.glsl): the nebula itself and,
  for its far part, the black hole's lens. Included by
  program/d2_clouds_upscaling.fsh, which has nothing else to draw in the End.
  Compiles to nothing in the other worlds, with the nebula off, or with
  Temporal Upscaling off.

--------------------------------------------------------------------------------
*/

// (plain #ifdef for the option, as everywhere: Iris only lists a boolean
// option in the menu when it is tested with #ifdef)
#if defined WORLD_END && defined PROGRAM_DEFERRED2
#ifdef END_NEBULA
#ifdef END_NEBULA_TEMPORAL

#include "/include/utility/color.glsl"

// The black hole in this world, as include/sky/sky.glsl decides it
#ifdef END_BLACK_HOLE
#if END_BLACK_HOLE_WORLD == CONCEPT_WORLD_END || END_BLACK_HOLE_WORLD == CONCEPT_WORLD_BOTH
#define SKY_BLACK_HOLE
#endif
#endif

#if defined SKY_BLACK_HOLE
#include "/include/sky/end_black_hole.glsl"
#endif

// The planet in this world (v0.7.6: what it covers is not drawn)
#ifdef END_PLANET
#if END_PLANET_WORLD == CONCEPT_WORLD_END || END_PLANET_WORLD == CONCEPT_WORLD_BOTH
#define SKY_PLANET
#endif
#endif

#if defined SKY_PLANET
#include "/include/sky/end_planet.glsl"
#endif

#include "/include/sky/end_nebula.glsl"

#endif
#endif
#endif

#endif // INCLUDE_SKY_END_NEBULA_PASS
