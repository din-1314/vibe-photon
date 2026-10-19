#if !defined INCLUDE_SKY_END_NEBULA
#define INCLUDE_SKY_END_NEBULA

/*
--------------------------------------------------------------------------------

  include/sky/end_nebula:
  The End's nebula (Photon Cinematic Concept), rebuilt in v0.7.1.6.
  v0.7.1.7: more depth (the gas itself hides what is behind it, stronger
  shadow on the side away from the light, farther clouds a little dimmer),
  five smaller young stars lighting white-cyan regions elsewhere, more black
  gaps by default (Coverage 1.00; higher values cover more).
  v0.7.1.8: volume (clouds glow at their skin and are dark and opaque
  inside), dark foreground dust clouds close to the island, and the blue as
  in the reference: a cyan heart (white only at its centre, its colour not
  greyed by shadow) grading to aqua and pale olive, and a thin teal veil in
  wisps far round it, over the golden clouds; the young stars elsewhere are
  smaller cyan pockets.
  v0.7.1.9: presence - the nebula as a place round you, not a backdrop:
    - the basin: a luminous sea of gas 1 100 blocks below the island, a
      landscape seen at a grazing angle (after the Orion fly-through), running
      to the horizon and climbing towards the heart, cyan near it, amber and
      rust farther (end_nebula_basin);
    - close wisps: thin strands of gas 450 to 1 900 blocks from the island,
      drawn over everything, the planet included (end_nebula_close_wisps),
      which shift against the rest when you walk;
    - motion as in the real time-lapses of nebulae: the clouds' fine detail
      expands away from the cluster, the wisps are blown away from the heart,
      and thin fronts of brightness leave the cluster and cross the clouds
      and the basin (Nebula Motion).
  v0.7.1.10 (rejected in game: hard faceted patches): the sea as a volume.
  v0.7.1.11: the sea (the basin; option Nebula Sea) back to the surface the
  prototype had, now below the whole End: a bowl whose rim climbs gently all
  round, so it shows above the horizon in every direction, with a wide bay
  round the black hole (it never covers its disc); its large relief read
  smoothly (no facets); depth from the shadow of its crests (the cluster's
  light) and from dimming with distance.
  v0.7.1.12: the canopy (option Nebula Canopy), the sea's sister layer high
  in the End's sky, in patches, so the sky has the Void's composition too
  (soft cyan and amber behind the crisp amber clouds); and the sea takes
  less of the cluster's light, so near the heart it is no bluer than under
  the island.
  v0.7.1.13: no streaks (neither layer is drawn near the horizon or where it
  is seen at a grazing angle, where its texture stretched; the sea no longer
  climbs in front of the heart, which both keep clear), and the canopy is the
  sea's mirror image: as near, as covering, and lit the way the sea is (the
  cluster is level with it, so its underside got hardly any light: the sky
  stayed flat and amber while the Void had its cyan).
  v0.7.1.14 (closing pass): the two layers nearly flat (the bowl was for the
  sea to show at the horizon, where it is no longer drawn), their edges a
  little farther from the horizon, crests the search only grazes faded (they
  drew thin streak lines), and a little more relief shading (deeper shadow
  behind crests, darker slopes turned away from the cluster); and a mild
  cinematic grade of the nebula's own light (a little more saturated, so its
  cyan and its orange stand apart).
  v0.7.2: motion and the black hole's pull. All the gas streams towards the
  black hole (the clouds' outlines, forms and detail each at their own speed
  and heading, so they change shape as they go; the sea, the canopy and the
  close wisps too): seen from the island the stream converges on it, like
  water on a drain. On top, the fine detail expands from the cluster,
  follows large gusts and, near the black hole, falls towards it at the rate
  the stars now do; looked up through its lens, this gas is seen flowing in
  and stretching round it (Nebula Motion; the pull also follows the black
  hole's Animation Speed).
  v0.7.2.1: the pull is seen. Round the black hole the far part's gas itself
  falls into it, faster the closer it is, turning round it as it goes (two
  cross-faded copies sharing the far part's samples, so at no extra cost; see
  end_nebula_infall_reach), as the stars there now do. The near part's dark
  dust is kept clear of the black hole's whole disc (it read as dirt on it).
  v0.7.2.2: the black hole lights the nebula. Its disc is the brightest thing
  in the sky: the gas round it scatters its gold light (the clouds' sides and
  edges turned to it, the thin gas seen in front of it), and so do the slopes
  of the sea and the canopy turned to it; it fades with the distance from it,
  so the far side of the sky is as it was (see end_nebula_hole_light).

  v0.7.4 (optimization, no visible change): reads and marches whose result
  cannot be seen are skipped - the fine noise where it is faded out, the
  probes of a sample with no gas or dust to light, the near part where it is
  kept fully clear, the dust particles likewise, and the steps of the sea's
  and canopy's search that are certainly not yet at the surface.

  Reference (references/nebula/README.md): the Eagle Nebula (M16) in the
  Hubble palette - a cyan/light-blue heart round its young cluster, golden and
  amber clouds round it with bright orange edges where they face the
  cluster, dark brown dust (a large dark cloud above the heart, pillars and
  globules in it, thin dark lanes) and, in a few places, rust red. The
  favourite photograph sets the colours and the mood; the shape comes from
  ESO's image of M16 (CC BY 4.0, credit: ESO), turned to the favourite's
  layout. Nothing of the photographs is drawn: they only guide a 3D volume.

  What changed from v0.7.0 - v0.7.1.5 (red, "oily"):
    - Colour comes from light, not from a fixed tint: every point's
      excitation is how strongly the cluster lights it (distance, and how
      much gas between them shadows it), and the palette runs from rust red
      (unlit, far) through amber and gold to cyan (next to the cluster).
    - Clouds are lit from the cluster: their faces towards it are brighter
      and edged in orange (ionisation fronts), their far sides in shadow.
    - The texture is a baked 3D noise (image/end_nebula_noise.dat: clouds,
      filaments, wisps, cells), sampled at three scales: real strands and
      wisps instead of smooth value-noise blobs, for fewer instructions.
    - The structure is 3D: the reference's gas, heart and dust are laid out
      in depth round the heart (dust in front, gold clouds round it, the
      lit cavity wall behind it), so it has parallax; round all of it, over
      the whole sky and below the island, a sparser envelope of amber, brown
      and rust-red clouds with black gaps.

  Placement (integration): the heart is fixed relative to the black hole's
  options (38 degrees to its left, 12 above), so the black hole's orange
  disc sits on the golden clouds next to the cyan heart, with gas behind it
  for its lens to bend. The planet passes in front.

  How it is drawn: along each view ray, end_nebula_steps distances, spaced
  evenly in log distance, each sample's offset changing every pixel and
  every frame, so TAA turns them into a smooth integral. Per sample: the
  structure map (1 read), the noise at a large and a middle scale (2), and
  only where there is something: the fine noise (1) and the light probe
  towards the cluster (1).

  Its far part (beyond end_nebula_range.z blocks) is looked up along the
  black hole's lensed direction and hidden by its shadow and disc, like the
  distant stars; the near part is drawn over the black hole (kept clear
  round it) and the stars behind (end_nebula_behind(), end_nebula_front()).

  Sky styles: the same structure and light. Cinematic Void: the Hubble
  palette above, on black. Photon Original: its violet palette (deep violet,
  purple, lavender, pale cyan heart, pink edges) over its purple sky.

  Cosmic dust particles (v0.6.7.1, unchanged): tiny grains at fixed places in
  the world around you (12 to 300 blocks), drawn over the nebula.

  How it is layered in draw_sky() (include/sky/sky.glsl):
    background -> nebula far part -> sun -> distant stars -> intermediate
    stars -> black hole disc -> nebula near part -> near stars -> particles
    -> planet

--------------------------------------------------------------------------------
*/

// Drawn in the End only, and only by deferred4 (the program that draws the sky
// with the black hole, the stars and the planet). Plain #ifdef on purpose: Iris
// only lists a boolean option in the menu when it is tested with #ifdef.
// v0.7.5, v0.7.9: also by deferred2, which draws it and averages it over the
// frames for deferred4 (Frame Accumulation, include/sky/end_nebula_buffer.glsl).
#if defined WORLD_END && (defined PROGRAM_DEFERRED4 || (defined PROGRAM_DEFERRED2 && defined END_NEBULA_TEMPORAL))
#ifdef END_NEBULA
#define CONCEPT_END_NEBULA
#endif
#endif

// Frame Accumulation (include/sky/end_nebula_buffer.glsl, included at the end of
// this file). Plain #ifdef for the option, as above
#ifdef END_NEBULA_TEMPORAL
#if defined CONCEPT_END_NEBULA
#define CONCEPT_END_NEBULA_BUFFERED
#endif
#endif

#if defined CONCEPT_END_NEBULA

#include "/include/sky/end_sky_common.glsl"

// Its textures (shaders.properties):
//   end_nebula_map (customTexture): the structure, square-root encoded
//     (squared when read). r: gas, g: the heart (open, ionised), b: dust,
//     a: inside the reference
//   end_nebula_noise: tileable 3D noise (96^3, image/end_nebula_noise.dat).
//     r: clouds, g: filaments, b: wisps, a: cells. Bound to this pass's
//     colortex10 (texture.deferred.colortex10.4), the way Photon binds its
//     clouds' 3D noise; the sky pass does not use colortex10 otherwise
uniform sampler2D end_nebula_map;
uniform sampler3D colortex10;
#define end_nebula_noise colortex10

// Palette, from the least to the most excited gas (measured on the favourite
// reference and, for the rust red, on the Seagull poster; rec709, linear);
// the colour of the lit edges; how much each channel of the light behind is
// absorbed by the dust (relative: reddening); the gain
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
const vec3 end_nebula_ramp_0 = vec3(0.42, 0.10, 0.52) * rec709_to_working_color;
const vec3 end_nebula_ramp_1 = vec3(0.58, 0.15, 0.78) * rec709_to_working_color;
const vec3 end_nebula_ramp_2 = vec3(0.70, 0.28, 1.00) * rec709_to_working_color;
const vec3 end_nebula_ramp_3 = vec3(0.78, 0.45, 1.00) * rec709_to_working_color;
const vec3 end_nebula_ramp_4 = vec3(0.88, 0.68, 1.00) * rec709_to_working_color;
const vec3 end_nebula_ramp_5 = vec3(0.78, 0.84, 1.00) * rec709_to_working_color;
const vec3 end_nebula_ramp_6 = vec3(0.62, 0.90, 1.00) * rec709_to_working_color;
const vec3 end_nebula_ramp_7 = vec3(0.55, 0.88, 1.00) * rec709_to_working_color;
const vec3 end_nebula_rim_color = vec3(1.00, 0.55, 0.85) * rec709_to_working_color;
const vec3 end_nebula_dust_glow = vec3(0.30, 0.18, 0.40) * rec709_to_working_color;
const vec3 end_nebula_dust_color = vec3(1.00, 1.20, 1.50);
const float end_nebula_gain = 0.20;
#else
const vec3 end_nebula_ramp_0 = vec3(1.00, 0.24, 0.16) * rec709_to_working_color; // rust red
const vec3 end_nebula_ramp_1 = vec3(1.00, 0.45, 0.13) * rec709_to_working_color; // deep orange
const vec3 end_nebula_ramp_2 = vec3(1.00, 0.62, 0.27) * rec709_to_working_color; // amber
const vec3 end_nebula_ramp_3 = vec3(1.00, 0.75, 0.40) * rec709_to_working_color; // gold
const vec3 end_nebula_ramp_4 = vec3(0.94, 0.96, 0.60) * rec709_to_working_color; // pale olive (v0.7.1.8)
const vec3 end_nebula_ramp_5 = vec3(0.62, 1.00, 0.84) * rec709_to_working_color; // aqua
const vec3 end_nebula_ramp_6 = vec3(0.28, 0.86, 1.00) * rec709_to_working_color; // cyan
const vec3 end_nebula_ramp_7 = vec3(0.20, 0.66, 1.00) * rec709_to_working_color; // light blue
const vec3 end_nebula_rim_color = vec3(1.00, 0.47, 0.13) * rec709_to_working_color;
const vec3 end_nebula_dust_glow = vec3(0.40, 0.24, 0.12) * rec709_to_working_color;
const vec3 end_nebula_dust_color = vec3(1.00, 1.25, 1.60);
const float end_nebula_gain = 0.25;
#endif

// Emission = gas * (base + lit * excitation^2) * palette; the lit edges; the
// dust's own faint glow (scattered cluster light); how much the gas and the
// dust absorb (per 1 000 blocks)
const vec2 end_nebula_emission_look = vec2(0.45, 1.30);
const float end_nebula_rim_gain = 2.6;
const float end_nebula_dust_glow_gain = 0.05;
const vec2 end_nebula_absorption = vec2(0.30, 2.6);

// The volume: from, to, where the far part starts (blocks from the island);
// samples in the near and far parts. Beyond end_nebula_reach blocks from the
// island the nebula travels with you
const vec3 end_nebula_center = vec3(0.0, 64.0, 0.0); // the main island
const vec3 end_nebula_range = vec3(1700.0, 22000.0, 7000.0);
// (v0.8.0, option Nebula Quality: fewer samples for more frame rate - 100%:
// these; never fewer than enough to keep the layers' shapes)
const float end_nebula_quality = float(END_NEBULA_QUALITY) * 0.01;
const int end_nebula_steps_near = max(3, int(8.0 * end_nebula_quality + 0.5));
const int end_nebula_steps_far = max(4, int(14.0 * end_nebula_quality + 0.5));
const float end_nebula_reach = 1500.0;

// The heart (where it is: end_sky_heart_*, include/sky/end_sky_common.glsl):
// the reference's extent round it (blocks, across and up, in the plane
// facing the island)
const vec2 end_nebula_map_size = vec2(28000.0, 22400.0);

// Depth (blocks from the heart's plane, away from the island): where the gas
// sheet is outside the heart and in it (its cavity wall, behind the
// cluster), how thick; the same for the dust (in front of the heart, the
// pillars in it); how far the large noise moves both
const vec3 end_nebula_gas_depth = vec3(-1500.0, 2500.0, 2400.0);
const vec3 end_nebula_dust_depth = vec3(-3200.0, 200.0, 1800.0);
const float end_nebula_depth_noise = 3000.0;

// Noise scales (texture tiles per block): large, middle, fine
const vec3 end_nebula_scales = vec3(1.0 / 24000.0, 1.0 / 7000.0, 1.0 / 1900.0);

// The clouds: where the gas starts (noise value) with little and with much
// gas, how sharp its edge is; how strong the filaments round them are
const vec3 end_nebula_cloud = vec3(0.68, 0.30, 0.07);
const float end_nebula_strands = 0.7;

// The heart's own glow (the ionised oxygen round the cluster: diffuse, not
// in clouds): its gain and reach (blocks)
const vec2 end_nebula_heart_glow = vec2(0.48, 3600.0);

// The envelope round everything: the shell it fills (blocks from the
// island: in, full, full, out), where its clouds start (large noise; Coverage
// moves it), how much it gives way inside the reference; its rust-red
// patches (threshold of the large noise's cells)
const vec4 end_nebula_shell = vec4(4500.0, 7000.0, 15000.0, 21000.0);
const vec2 end_nebula_envelope = vec2(0.53, 0.12);
const float end_nebula_envelope_yield = 0.6;
const vec2 end_nebula_red = vec2(0.52, 0.70);
const float end_nebula_coverage_shift = (float(END_NEBULA_COVERAGE) - 1.5) * 0.12;

// The light (the cluster: end_sky_cluster_position()): how far it reaches
// (blocks, where it is half), how far the probe towards it looks (blocks) and
// how much the gas there shadows
const float end_nebula_light_reach = 5600.0;
const vec2 end_nebula_probe = vec2(1100.0, 3.6);

// Smaller young stars elsewhere in the nebula (v0.7.1.7): each lights its own
// region white and cyan, with edges turned to it, like the favourite's
// secondary blue regions. Azimuth from the black hole's, elevation (degrees),
// distance (blocks); their light's reach (blocks) and strength
const vec3 end_nebula_star_0 = vec3(-95.0, 38.0, 9000.0);
const vec3 end_nebula_star_1 = vec3(40.0, 28.0, 12500.0);
const vec3 end_nebula_star_2 = vec3(115.0, -8.0, 8500.0);
const vec3 end_nebula_star_3 = vec3(-160.0, 52.0, 11000.0);
const vec3 end_nebula_star_4 = vec3(70.0, -48.0, 9500.0);
const vec2 end_nebula_star_light = vec2(3800.0, 0.74);

// Depth (v0.7.1.7): how much the gas itself hides what is behind it (on top
// of the dust), how much farther clouds lose contrast (from, to: blocks) and
// how dark the side away from the light is
const vec2 end_nebula_depth_fade = vec2(9000.0, 20000.0);

// Volume (v0.7.1.8): a cloud glows at its skin and is dark and opaque inside,
// like the reference's clouds. How far past its edge (noise) its body starts
// and is full, how dim the body's own light is, how much dust it holds
const vec4 end_nebula_body = vec4(0.07, 0.24, 0.28, 1.0);

// Foreground dust (v0.7.1.8): dark clouds close to the island, in front of
// everything (they shift against the rest when you move): the shell they
// fill (blocks: in, full, full, out), where they start and how sharp (middle
// noise), how much faint gas they carry
const vec4 end_nebula_fore_shell = vec4(1700.0, 2300.0, 3600.0, 4600.0);
const vec3 end_nebula_fore = vec3(0.69, 0.045, 0.10);
const float end_nebula_fore_scale = 1.0 / 3400.0;

// The teal veil (v0.7.1.8): thin ionised oxygen in wisps far round the heart
// (and a little round the young stars), over the golden clouds as in the
// reference: gain, reach (blocks)
const vec2 end_nebula_veil = vec2(0.085, 9000.0);

// The sea (v0.7.1.9, v0.7.1.11; option Nebula Sea): a luminous surface of
// gas below the whole End, in the Void, a landscape seen at a grazing angle
// like the Orion fly-through: it starts close under you and runs to the
// horizon all round (cyan where the cluster lights it, amber and rust
// elsewhere). Nearly flat (v0.7.1.14; a very wide bowl).
// How far below the island its middle is (blocks), the radius of the bowl
// (blocks; its second value is no longer used); its relief (blocks,
// large and middle noise) and their scales (tiles per block); where it ends
// (blocks from the island: from, to) and the distances it is searched between
// (from the camera) and the steps
const float end_nebula_basin_depth = 1100.0;
const vec2 end_nebula_basin_shape = vec2(120000.0, 45000.0);
const vec2 end_nebula_basin_relief = vec2(900.0, 260.0);
const vec2 end_nebula_basin_scales = vec2(1.0 / 9000.0, 1.0 / 2600.0);
const vec2 end_nebula_basin_edge = vec2(13000.0, 19000.0);
const vec2 end_nebula_basin_range = vec2(450.0, 19000.0);
const int end_nebula_basin_steps = max(8, int(16.0 * end_nebula_quality + 0.5)); // (v0.8.0: Nebula Quality)
// Its few gaps (noise: from, to), how bright it is (unlit, lit), and how much
// of the rim colour its crests turned to the cluster get
const vec2 end_nebula_basin_gap = vec2(0.26, 0.42);
const vec3 end_nebula_basin_look = vec3(0.10, 0.85, 0.35);
// Kept clear round the black hole (radians from it: none, all), a bay far
// wider than the near gas's, so its disc and halo are never covered
const vec2 end_nebula_basin_hole = vec2(0.52, 0.90);
// Depth (v0.7.1.11): how far towards the cluster its relief is probed for
// the shadow of its crests (blocks) and how dark that shadow is; how much
// dimmer it is far away (from, to: blocks from the camera; how much)
const vec2 end_nebula_basin_shadow = vec2(420.0, 0.72);
const vec3 end_nebula_basin_haze = vec3(3500.0, 15000.0, 0.45);

// Kept clear round the black hole, in the near part only (radians from it)
const vec2 end_nebula_hole_clear = vec2(0.25, 0.55);

// Cosmic Dust: a little more dust in the nebula
#if END_NEBULA_DUST == 2
const float end_nebula_dust_amount = 1.15;
#elif END_NEBULA_DUST == 3
const float end_nebula_dust_amount = 1.30;
#else
const float end_nebula_dust_amount = 1.00;
#endif

// Motion, for Off / Slow / Normal / Fast: the middle and fine noise drift
// slowly through the texture (whole numbers of cycles per hour, so the hourly
// wrap of frameTimeCounter is seamless); the structure itself never moves
#if END_NEBULA_MOTION == 1
const float end_nebula_detail_cycles = 3.0;
#elif END_NEBULA_MOTION == 2
const float end_nebula_detail_cycles = 6.0;
#elif END_NEBULA_MOTION == 3
const float end_nebula_detail_cycles = 12.0;
#else
const float end_nebula_detail_cycles = 0.0;
#endif
const float end_nebula_detail_drift = 0.035; // texture tiles

// Close wisps (v0.7.1.9): thin strands of gas near the island, in front of
// everything, the planet included: they shift against the rest when you walk
// and drift slowly, so the nebula is a place you are in, not a backdrop. The
// shell they fill (blocks from the island: in, full, full, out), the
// distances they are drawn between (from the camera) and the samples; their
// noise scales (form, detail: tiles per block), where they start and how
// sharp (noise), how much gas they are; how thin they are kept in front of
// the heart (radians from the cluster: from, to)
const vec4 end_nebula_close_shell = vec4(450.0, 700.0, 1400.0, 1900.0);
const vec2 end_nebula_close_range = vec2(380.0, 2100.0);
const int end_nebula_close_steps = max(3, int(6.0 * end_nebula_quality + 0.5)); // (v0.8.0: Nebula Quality)
const vec2 end_nebula_close_scales = vec2(1.0 / 1440.0, 1.0 / 480.0);
const vec3 end_nebula_close = vec3(0.70, 0.05, 1.5);
const vec2 end_nebula_close_heart = vec2(0.30, 0.65);
// Their wind (blocks per second), for Off / Slow / Normal / Fast: each of its
// components 0.4 * a whole number, so both noise scales wrap seamlessly with
// frameTimeCounter's hour. v0.7.2: twice as fast, and towards the black hole
// like the rest of the gas (it blew towards the heart)
#if END_NEBULA_MOTION == 1
const float end_nebula_wind = 4.0;
#elif END_NEBULA_MOTION == 2
const float end_nebula_wind = 8.0;
#elif END_NEBULA_MOTION == 3
const float end_nebula_wind = 16.0;
#else
const float end_nebula_wind = 0.0;
#endif

// Expansion and waves (v0.7.1.9), as in the real time-lapses of nebulae (the
// Crab's filaments running outwards, the ripples leaving its centre): the
// fine detail of the clouds travels away from the cluster (two copies half a
// cycle apart, cross-faded, so it never jumps: seconds per cycle and blocks
// travelled per cycle), the close wisps are blown away from the heart, and
// thin fronts of brightness leave the cluster and cross the clouds (seconds
// per front; their spacing in blocks, their strength, how much the large
// noise bends them). All periods divide the hour, so frameTimeCounter's wrap
// is seamless. Off / Slow / Normal / Fast
//
// v0.7.2: the nebula is seen moving with the camera still, and the black
// hole pulls it.
//   - The current: all the gas streams towards the black hole. The clouds'
//     outlines (large noise), their forms (middle noise) and their fine
//     detail each travel at their own speed and in a slightly different
//     direction (current.xyz: blocks per second; end_nebula_current_turn:
//     how far off the black hole's direction each heads), so the clouds
//     change shape as they go instead of sliding as one piece. Seen from the
//     island the stream converges on the black hole, like water on a drain
//     (perspective), near clouds faster than far ones. The sea's and the
//     canopy's detail flow the same way (layer.xy). These are plain
//     translations (whole numbers of noise tiles per hour, so the hourly wrap
//     of frameTimeCounter is seamless): nothing resets, no cross-fade.
//   - The detail's own flow, on top (end_nebula_velocity()): it expands
//     away from the cluster (flow.x), follows large gusts whose direction
//     changes from place to place (flow.y; their size, flow.z) and, near the
//     black hole's line of sight, falls towards it (end_sky_pull_rate(), the
//     angular rate the stars fall at; never faster than pull.x blocks per
//     second) and turns round it a little (pull.y of that, the way the pulled
//     stars turn). It travels as two copies half a cycle apart, cross-faded
//     (one copy per sample, picked at random with the cross-fade's weight,
//     as since v0.7.1.14), their cycles shifted from place to place (the
//     large noise) so nothing resets everywhere at once.
// The far part of the nebula is looked up through the black hole's lens, so
// this moving gas is seen flowing in and stretching round it: the gas moves,
// the lens bends its light. Without a black hole the current heads away from
// the heart. Off / Slow / Normal / Fast: how fast everything is, seconds per
// cycle of the detail's own flow and per front of brightness
#if END_NEBULA_MOTION == 1
const float end_nebula_flow_speed = 0.5;
const float end_nebula_flow_period = 15.0;
const float end_nebula_wave_period = 60.0;
#elif END_NEBULA_MOTION == 2
const float end_nebula_flow_speed = 1.0;
const float end_nebula_flow_period = 7.5;
const float end_nebula_wave_period = 30.0;
#elif END_NEBULA_MOTION == 3
const float end_nebula_flow_speed = 2.0;
const float end_nebula_flow_period = 3.75;
const float end_nebula_wave_period = 15.0;
#else
const float end_nebula_flow_speed = 0.0;
const float end_nebula_flow_period = 7.5;
#endif
const vec3 end_nebula_current = vec3(42.0, 62.0, 84.0);
const vec2 end_nebula_current_layer = vec2(22.0, 34.0);
const vec3 end_nebula_current_turn = vec3(0.16, -0.26, 0.30);
const vec3 end_nebula_flow = vec3(34.0, 24.0, 38000.0);
const vec2 end_nebula_pull = vec2(110.0, 0.35);
const vec3 end_nebula_wave = vec3(2600.0, 0.35, 900.0);

// v0.7.2.1: the black hole is seen swallowing the gas. The nebula's far part
// (the one looked up through its lens) falls into it, faster the closer it is
// (end_sky_infall_from(), exactly as the stars round it do), turning round
// its axis as it falls (turn: radians per unit fallen, at one unit; rate: how
// fast next to the stars, which are points and can streak). A flow
// like this cannot be a plain translation, so the far part is drawn as two
// copies half a cycle apart, cross-faded (each starts a little farther out
// than it is, falls past, and fades before it is reset): its samples
// alternate between the two, so it costs no more than one. The cycle's phase
// differs across the sky (phase: cycles), so it never resets everywhere at
// once. Units from the black hole's axis where it is in full and where it
// ends (reach); how far (units) a copy travels at most, so the two never
// drift too far apart to cross-fade (travel)
const vec2 end_nebula_infall_reach = vec2(4.5, 7.5);
const vec2 end_nebula_infall_axis = vec2(0.4, 1.6);
const float end_nebula_infall_turn = 0.55;
const float end_nebula_infall_rate = 1.5;
const float end_nebula_infall_phase = 0.30;
const float end_nebula_infall_travel = 0.9;

// The black hole's light on the gas (v0.7.2.2): the gas round the black hole
// scatters its disc's light: the clouds are brighter on the side turned to
// it, their edges facing it are rimmed in its gold, and the thin gas seen in
// front of it glows (light scattered forward). Where the light is (blocks
// from the island, along the black hole's direction: among the nebula's far
// part), how far it reaches (blocks) and its strength (which also follows
// the black hole's Intensity and Disc Brightness); how much the gas scatters,
// how bright the rims are, how much it lights the clouds' own colour; its
// colour
const vec3 end_nebula_hole_light = vec3(20000.0, 14000.0, 1.0);
const vec3 end_nebula_hole_look = vec3(0.28, 1.80, 0.45);
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
const vec3 end_nebula_hole_color = (vec3(1.00, 0.70, 0.62) * end_sky_hole_tint) * rec709_to_working_color;
#else
const vec3 end_nebula_hole_color = (vec3(1.00, 0.64, 0.30) * end_sky_hole_tint) * rec709_to_working_color;
#endif
// (v0.7.6: times the black hole's colour options, 1 by default)
// ... and on the sea and the canopy: how bright, how much of it their crests
// turned to it get
const vec2 end_nebula_hole_basin = vec2(0.55, 0.60);

// v0.7.2.1: the near part's dust (dark clouds, drawn over the black hole) is
// kept clear of the whole disc and its halo, a wider bay than the gas's
// (radians from the black hole: none, all): seen against the disc's light it
// read as dirt on it
const vec2 end_nebula_hole_clear_dust = vec2(0.62, 1.05);

// Cosmic dust particles (v0.6.7.1), for Off / Subtle / Normal / Strong: the
// size of the world cells they sit in (one candidate per cell), the distances
// they are drawn between, how many cells a ray visits at most, their radius
// (blocks); per style, the share of cells that hold one, their own faint
// glow, how much of the nebula's light behind them they scatter, and how much
// they dim it
const float end_nebula_particle_cell = 24.0;
const vec2 end_nebula_particle_range = vec2(48.0, 300.0);
const int end_nebula_particle_steps = 20;
const float end_nebula_particle_radius = 0.35;
// v0.6.7.2: a second, closer population: finer grains in 8-block cells from
// 12 to 60 blocks (the closest suspended dust)
const float end_nebula_particle_near_cell = 8.0;
const vec2 end_nebula_particle_near_range = vec2(12.0, 60.0);
const int end_nebula_particle_near_steps = 12;
const float end_nebula_particle_near_radius = 0.06;
const vec3 end_nebula_particle_color = vec3(1.00, 0.86, 0.72);
#if CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
const vec4 end_nebula_particle_shares = vec4(0.0, 0.10, 0.14, 0.20);
const vec3 end_nebula_particle_look = vec3(0.012, 0.20, 0.10); // own glow, scattered, dimming
#else
const vec4 end_nebula_particle_shares = vec4(0.0, 0.22, 0.32, 0.45);
const vec3 end_nebula_particle_look = vec3(0.060, 1.20, 0.35);
#endif
const float end_nebula_particle_share = end_nebula_particle_shares[END_NEBULA_DUST];

// What every sample of a pixel shares:
//   observer: where the nebula is seen from (the camera)
//   origin:   the camera relative to the island, kept within end_nebula_reach
//   jitter:   this pixel's offset of the samples (0..1, every frame another)
//   frame:    the heart's frame (x right, y up, z away from the island)
//   heart:    the heart's centre, cluster: the light (relative to the island)
//   drift:    the middle and fine noise's slow drift (texture tiles)
struct EndNebulaField {
    vec3 observer;
    vec3 origin;
    float jitter;
    mat3 frame;
    vec3 heart;
    vec3 cluster;
    vec3 drift;
    vec3 wind;
    vec2 basin;
    float flow;      // how far through its cycle the detail's own flow is (0..1)
    float fall;      // ... and the far part's fall into the black hole (Pull Speed)
    float wave;
    vec3 hole;       // the black hole's direction, and its units per radian
    float hole_scale;
    vec3 hole_place; // where its light is (blocks from the island), how strong
    float hole_power;
    vec3 carry[5];   // how far the current has carried the outlines, the forms,
                     // the detail, and the sea's and canopy's forms and detail
                     // (noise tiles)
    vec3 young[5];
};

EndNebulaField end_nebula_field() {
    EndNebulaField field;

    field.observer = cameraPosition;
    vec3 from_island = cameraPosition - end_nebula_center;
    field.origin = from_island * min(1.0, end_nebula_reach / max(length(from_island), 1e-3));
    field.jitter = interleaved_gradient_noise(gl_FragCoord.xy, frameCounter);

    vec3 heart_dir = end_sky_heart_direction();
    field.frame = end_sky_facing(heart_dir);
    field.heart = heart_dir * end_sky_heart_distance;
    field.cluster = end_sky_cluster_position();
    vec3 young_dir[5] = vec3[5](end_nebula_star_0, end_nebula_star_1, end_nebula_star_2, end_nebula_star_3, end_nebula_star_4);
    for (int i = 0; i < 5; ++i) {
        field.young[i] = end_sky_direction(float(END_BLACK_HOLE_AZIMUTH) + young_dir[i].x, young_dir[i].y) * young_dir[i].z;
    }

#if END_NEBULA_MOTION != 0
    float angle = (6.28318531 / 3600.0) * end_nebula_detail_cycles * frameTimeCounter;
    field.drift = end_nebula_detail_drift * vec3(cos(angle) - 1.0, sin(angle), 0.5 * sin(2.0 * angle));
#else
    field.drift = vec3(0.0);
#endif

#if defined SKY_BLACK_HOLE
    field.hole = end_black_hole_direction();
    field.hole_scale = max(
        BH_CAMERA_DISTANCE / (pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE),
        BH_MIN_CAMERA_DISTANCE
    );
    vec3 downstream = field.hole;
    field.hole_place = field.hole * end_nebula_hole_light.x;
    field.hole_power = end_nebula_hole_light.z
        * clamp(float(END_BLACK_HOLE_INTENSITY) * float(END_BLACK_HOLE_DISC_BRIGHTNESS), 0.0, 2.0);
#else
    field.hole = vec3(0.0, 1.0, 0.0);
    field.hole_scale = 0.0;
    field.hole_place = vec3(0.0);
    field.hole_power = 0.0;
    vec3 downstream = -heart_dir;
#endif
    // The wind carries the close wisps downstream (the noise is looked up
    // upstream of where it was; each component a whole number of 0.4 blocks
    // per second, see end_nebula_wind)
    field.wind = round(downstream * (-1.41 * end_nebula_wind / 0.4)) * (0.4 * frameTimeCounter);
#if END_NEBULA_MOTION != 0
    field.flow = fract(frameTimeCounter / end_nebula_flow_period);
    field.fall = fract(frameTimeCounter * (end_sky_pull_speed / end_nebula_flow_period));
    field.wave = fract(frameTimeCounter / end_nebula_wave_period);

    // The current: each noise carried downstream, a little off it (whole
    // numbers of its tiles per hour)
    vec3 across = normalize(cross(downstream, vec3(0.0, 1.0, 0.0)));
    vec3 over = cross(across, downstream);
    float hour = frameTimeCounter * (1.0 / 3600.0);
    vec3 heading = normalize(downstream + end_nebula_current_turn.x * across);
    field.carry[0] = round(heading * (end_nebula_current.x * end_nebula_flow_speed * 3600.0 * end_nebula_scales.x)) * hour;
    heading = normalize(downstream + end_nebula_current_turn.y * across + 0.15 * over);
    field.carry[1] = round(heading * (end_nebula_current.y * end_nebula_flow_speed * 3600.0 * end_nebula_scales.y)) * hour;
    field.carry[3] = round(heading * (end_nebula_current_layer.x * end_nebula_flow_speed * 3600.0 * end_nebula_basin_scales.y)) * hour;
    heading = normalize(downstream + end_nebula_current_turn.z * over - 0.10 * across);
    field.carry[2] = round(heading * (end_nebula_current.z * end_nebula_flow_speed * 3600.0 * end_nebula_scales.z)) * hour;
    field.carry[4] = round(heading * (end_nebula_current_layer.y * end_nebula_flow_speed * 3600.0 * end_nebula_scales.z)) * hour;
#else
    field.flow = 0.0;
    field.fall = 0.0;
    field.wave = 0.0;
    for (int i = 0; i < 5; ++i) field.carry[i] = vec3(0.0);
#endif
    field.basin = normalize(heart_dir.xz);

    return field;
}

// Cinematic grade (v0.7.1.14) of the nebula's own light only: a little more
// saturated, so its cyan and its orange stand apart (teal and orange)
const float end_nebula_saturation = 1.18;
vec3 end_nebula_grade(vec3 light, vec3 tint) {
    float luminance = dot(light, vec3(0.2627, 0.6780, 0.0593));
    // Colour options (v0.7.6 - v0.7.8): its light's red, green and blue, in
    // rec709 (tint: the nebula's, or the sea's own)
    vec3 graded = max(mix(vec3(luminance), light, end_nebula_saturation), vec3(0.0));
    return max((graded * working_to_display_color) * tint, vec3(0.0)) * rec709_to_working_color;
}

vec3 end_nebula_grade(vec3 light) {
    return end_nebula_grade(light, end_sky_nebula_tint);
}

// The detail's own velocity at a point, on top of the current (v0.7.2;
// blocks per second; rel: blocks from the island, r its distance)
vec3 end_nebula_velocity(vec3 rel, float r, EndNebulaField field) {
    vec3 from_cluster = rel - field.cluster;
    vec3 a = rel * (6.2831853 / end_nebula_flow.z);
    vec3 gusts = vec3(
        sin(a.y + 1.3) + 0.5 * sin(1.7 * a.z + 4.1),
        0.6 * (sin(a.z + 2.7) + 0.5 * sin(1.9 * a.x + 0.4)),
        sin(a.x + 5.2) + 0.5 * sin(1.6 * a.y + 3.3)
    );
    vec3 velocity = end_nebula_flow.x * from_cluster * inversesqrt(max(dot(from_cluster, from_cluster), 1.0))
        + (0.67 * end_nebula_flow.y) * gusts;
#if defined SKY_BLACK_HOLE
    // Falling towards the black hole's line of sight, turning round it
    float along = dot(rel, field.hole);
    vec3 inward = along * field.hole - rel;
    float off_axis = length(inward);
    inward /= max(off_axis, 1.0);
    float rate = end_sky_pull_rate(field.hole_scale * fast_acos(clamp(along / max(r, 1.0), -1.0, 1.0)));
    velocity += min(rate * r, end_nebula_pull.x) * (inward + end_nebula_pull.y * cross(field.hole, inward));
#endif
    return velocity * end_nebula_flow_speed;
}

// The palette at an excitation (0: unlit, far; 1: next to the cluster)
vec3 end_nebula_ramp(float e) {
    float x = clamp01(e) * 7.0;
    vec3 c = mix(end_nebula_ramp_0, end_nebula_ramp_1, clamp01(x));
    c = mix(c, end_nebula_ramp_2, clamp01(x - 1.0));
    c = mix(c, end_nebula_ramp_3, clamp01(x - 2.0));
    c = mix(c, end_nebula_ramp_4, clamp01(x - 3.0));
    c = mix(c, end_nebula_ramp_5, clamp01(x - 4.0));
    c = mix(c, end_nebula_ramp_6, clamp01(x - 5.0));
    return mix(c, end_nebula_ramp_7, clamp01(x - 6.0));
}

// The structure map in a direction from the island (in the heart's frame):
// gas, heart, dust (rgb) and how far inside the reference it is (a; 0
// outside). Read where the island's line of sight through the point crosses
// the heart's plane: read along the point's own direction, never extruded
// along the heart's axis (which, seen from the island, drew streaks
// converging on the heart)
vec4 end_nebula_map_at(vec3 local) {
    if (local.z < 0.2 * end_sky_heart_distance) return vec4(0.0);
    vec2 plane = local.xy * (end_sky_heart_distance / local.z);
    vec2 uv = vec2(0.5 + plane.x / end_nebula_map_size.x, 0.5 - plane.y / end_nebula_map_size.y);
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return vec4(0.0);
    vec4 m = sqr(texture(end_nebula_map, uv));
    float edge = smoothstep(0.0, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    return vec4(m.rgb, m.a * edge);
}

// Where the clouds are, from how much gas there is (amount) and the noise
float end_nebula_cloud_at(float amount, float v) {
    float from = end_nebula_cloud.x - end_nebula_cloud.y * amount;
    return amount * smoothstep(from, from + end_nebula_cloud.z, v);
}

// The nebula at a point (rel: blocks from the island; r its distance). pixel:
// the size of a pixel there (blocks). Returns the light it gives; gas, dust:
// how much of each is there (for the absorption)
vec3 end_nebula_sample(vec3 rel, float r, EndNebulaField field, float pixel, out float gas, out float dust) {
    gas = 0.0;
    dust = 0.0;

    vec3 local = rel * field.frame;
    vec4 big = texture(end_nebula_noise, rel * end_nebula_scales.x - field.carry[0] + vec3(0.13, 0.71, 0.37));
    vec4 m = end_nebula_map_at(local);
    local.z -= end_sky_heart_distance; // depth from the heart's plane

    // The reference laid out in depth: its gas in a sheet round the heart's
    // plane (behind it in the heart: the lit cavity wall), its dust in front
    // (the pillars in the heart itself), both bent by the large noise
    float depth_shift = end_nebula_depth_noise * (big.r - 0.5);
    float gas_sheet = exp(-sqr((local.z - mix(end_nebula_gas_depth.x, end_nebula_gas_depth.y, m.g) - depth_shift)
        / (end_nebula_gas_depth.z * (0.7 + 0.6 * big.a))));
    float dust_sheet = exp(-sqr((local.z - mix(end_nebula_dust_depth.x, end_nebula_dust_depth.y, m.g) + 0.8 * depth_shift)
        / end_nebula_dust_depth.z));
    float gas_amount = m.r * m.a * gas_sheet;
    float dust_amount = m.b * m.a * dust_sheet;

    // The envelope round everything (amber, brown and rust-red clouds with
    // black gaps), giving way inside the reference
    float shell = smoothstep(end_nebula_shell.x, end_nebula_shell.y, r)
        * (1.0 - smoothstep(end_nebula_shell.z, end_nebula_shell.w, r));
    float envelope_from = end_nebula_envelope.x - end_nebula_coverage_shift;
    float envelope = shell * smoothstep(envelope_from, envelope_from + end_nebula_envelope.y, 0.75 * big.r + 0.25 * big.g)
        * (1.0 - end_nebula_envelope_yield * m.a) * (1.0 - 0.8 * smoothstep(0.2, 0.7, m.g));

    // Foreground dust, close to the island (not in front of the heart)
    vec4 mid = vec4(0.0);
    float fore_shell = smoothstep(end_nebula_fore_shell.x, end_nebula_fore_shell.y, r)
        * (1.0 - smoothstep(end_nebula_fore_shell.z, end_nebula_fore_shell.w, r));
    float fore = 0.0;
    if (fore_shell > 0.0) {
        mid = texture(end_nebula_noise, rel * end_nebula_scales.y + field.drift - field.carry[1] + vec3(0.41, 0.07, 0.83));
        vec4 near_noise = texture(end_nebula_noise, rel * end_nebula_fore_scale + vec3(0.67, 0.19, 0.45));
        float fore_from = end_nebula_fore.x - 0.5 * end_nebula_coverage_shift;
        fore = fore_shell * smoothstep(fore_from, fore_from + end_nebula_fore.y, 0.45 * near_noise.r + 0.25 * near_noise.a + 0.30 * mid.r)
            * (1.0 - 0.85 * m.a * smoothstep(0.05, 0.4, m.g));
        dust_amount += fore;
    }

    float amount = 1.5 * gas_amount + 0.75 * envelope + end_nebula_fore.z * fore;
    float cluster_distance = length(field.cluster - rel);
    float glow = m.g * m.a * exp(-sqr(cluster_distance / end_nebula_heart_glow.y));
    float veil = exp(-sqr(cluster_distance / end_nebula_veil.y)) * smoothstep(0.40, 0.75, big.g);

    // The young stars elsewhere: the nearest one's light, and their own
    // smaller cyan glows (where there is envelope gas)
    float young_light = 0.0;
    vec3 young_to = vec3(0.0);
    for (int i = 0; i < 5; ++i) {
        vec3 to = field.young[i] - rel;
        float l = 1.0 / (1.0 + dot(to, to) * (1.0 / sqr(end_nebula_star_light.x)));
        if (l > young_light) { young_light = l; young_to = to; }
    }
    young_light *= end_nebula_star_light.y;
#if defined SKY_BLACK_HOLE
    // The black hole's light here (v0.7.2.2)
    vec3 to_hole = field.hole_place - rel;
    float hole_distance = length(to_hole);
    float hole_light = field.hole_power / sqr(1.0 + sqr(hole_distance / end_nebula_hole_light.y));
#endif
    float young_glow = 0.7 * envelope * smoothstep(0.25, 0.7, young_light);
    veil += 0.6 * smoothstep(0.12, 0.5, young_light) * smoothstep(0.40, 0.75, big.g);
    if (amount + dust_amount + glow + young_glow < 0.004) {
        // Only the thin veil here: no clouds to shape or light
        if (veil < 0.03) return vec3(0.0);
        if (fore_shell <= 0.0) {
            mid = texture(end_nebula_noise, rel * end_nebula_scales.y + field.drift - field.carry[1] + vec3(0.41, 0.07, 0.83));
        }
        return (end_nebula_veil.x * veil * smoothstep(0.35, 0.70, 0.5 * mid.g + 0.18) * 0.81
            * (1.0 - 0.35 * smoothstep(end_nebula_depth_fade.x, end_nebula_depth_fade.y, r))) * end_nebula_ramp_5;
    }

    // The clouds: middle noise (forms and filaments), fine noise (wisps),
    // faded to its average where it is smaller than about 3 pixels
    if (fore_shell <= 0.0) {
        mid = texture(end_nebula_noise, rel * end_nebula_scales.y + field.drift - field.carry[1] + vec3(0.41, 0.07, 0.83));
    }
    // (v0.7.4: not read at all where it is faded out entirely)
    float fine_weight = smoothstep(2.0, 4.0, 1.0 / (end_nebula_scales.z * 24.0 * pixel));
    vec4 fine = vec4(0.52, 0.36, 0.40, 0.49);
    if (fine_weight > 0.0) {
#if END_NEBULA_MOTION != 0
        // (the fine noise also has its own flow, see end_nebula_velocity(): two
        // copies half a cycle apart, cross-faded; one copy per sample, picked at
        // random with the cross-fade's weight, which the samples and TAA blend;
        // the cycle shifted from place to place)
        float cycle = fract(field.flow + big.a);
        float life = fract(field.jitter * 3.0 + r * 0.013) < abs(1.0 - 2.0 * cycle) ? fract(cycle + 0.5) - 0.5 : cycle - 0.5;
        fine = texture(end_nebula_noise, rel * end_nebula_scales.z + 1.7 * field.drift - field.carry[2]
            - end_nebula_velocity(rel, r, field) * (life * end_nebula_flow_period * end_nebula_scales.z)
            + vec3(0.29, 0.53, 0.11));
#else
        fine = texture(end_nebula_noise, rel * end_nebula_scales.z + 1.7 * field.drift + vec3(0.29, 0.53, 0.11));
#endif
        fine = mix(vec4(0.52, 0.36, 0.40, 0.49), fine, fine_weight);
    }

    float v = 0.50 * mid.r + 0.36 * fine.r + 0.14 * big.g;
    float strands = sqr(0.6 * mid.g + 0.4 * fine.g);
    float cloud = end_nebula_cloud_at(amount, v);
    float rho = cloud + end_nebula_strands * amount * strands * smoothstep(0.30, 0.55, v);

    // The cloud's body, past its skin: dark and opaque (not in the heart's
    // lit cavity wall)
    float cloud_from = end_nebula_cloud.x - end_nebula_cloud.y * amount;
    float body = smoothstep(cloud_from + end_nebula_body.x, cloud_from + end_nebula_body.y, v)
        * smoothstep(0.12, 0.45, amount) * (1.0 - 0.8 * m.g * m.a);

    // Dust: the reference's (pillars, the dark cloud above the heart) shaped
    // by the noise; thin dark lanes (the filaments' gaps) in the envelope's
    // and the gas's denser parts
    float shape = 0.6 * mid.r + 0.4 * fine.b;
    float delta = dust_amount * smoothstep(0.38, 0.62, shape)
        + 0.9 * (cloud + 0.5 * envelope) * smoothstep(0.55, 0.80, fine.g) * smoothstep(0.40, 0.65, mid.a)
        + 0.6 * envelope * smoothstep(0.66, 0.74, 0.7 * mid.b + 0.3 * big.a)
        + end_nebula_body.w * amount * body;

    // Light from the cluster: how close, and how much gas between them (one
    // probe towards it). The faces turned to it glow at their edge
    vec3 to_cluster = field.cluster - rel;
    float light = 1.0 / (1.0 + sqr(cluster_distance / end_nebula_light_reach));
    // (v0.7.4: the probe is read only where its result is used. With no gas
    // and no dust here - rho and delta both exactly 0 - everything the shadow
    // and the lit edges go into is multiplied by 0, so the values left here
    // give the same light)
    float probe_delta = 0.0;
    float shadow = 1.0;
    float front = 0.0;
    if (rho > 0.0 || delta > 0.0) {
        vec3 probe_rel = rel + to_cluster * (end_nebula_probe.x / cluster_distance);
        vec4 probe_noise = texture(end_nebula_noise, probe_rel * end_nebula_scales.y + field.drift - field.carry[1] + vec3(0.41, 0.07, 0.83));
        float probe_rho = end_nebula_cloud_at(amount, 0.50 * probe_noise.r + 0.36 * 0.52 + 0.14 * big.g);
        probe_delta = dust_amount * smoothstep(0.38, 0.62, 0.6 * probe_noise.r + 0.2);
        shadow = exp(-end_nebula_probe.y * (probe_rho + probe_delta));
        front = clamp01(3.0 * (cloud - probe_rho)) * smoothstep(0.02, 0.2, amount);
    }

    // ... and towards the nearest young star (the same middle noise, one
    // more read), for its own shadow and lit edges
#if defined SKY_BLACK_HOLE
    // (v0.7.2.2: one probe for both, towards wherever more of their light
    // comes from: the young star close to one, the black hole elsewhere)
    vec3 second = young_to * (young_light / max(length(young_to), 1.0)) + to_hole * (hole_light / hole_distance);
    vec3 young_probe = rel + second * (end_nebula_probe.x / max(length(second), 1e-4));
#else
    vec3 young_probe = rel + young_to * (end_nebula_probe.x / max(length(young_to), 1.0));
#endif
    // (v0.7.4: likewise, only where there is gas: this shadow and these lit
    // edges only ever light the gas - with rho exactly 0 there is no cloud
    // either, so no edge)
    float young_shadow = 1.0;
    float young_front = 0.0;
    if (rho > 0.0) {
        float young_rho = end_nebula_cloud_at(amount,
            0.50 * texture(end_nebula_noise, young_probe * end_nebula_scales.y + field.drift - field.carry[1] + vec3(0.41, 0.07, 0.83)).r
            + 0.36 * 0.52 + 0.14 * big.g);
        young_shadow = exp(-end_nebula_probe.y * young_rho);
        young_front = clamp01(3.0 * (cloud - young_rho)) * smoothstep(0.02, 0.2, amount);
    }

    // Excitation: the light, the shadow, the reference's heart; the envelope
    // gets a little of its own (gold, amber) and its rust-red patches less
    // (v0.7.1.8: in the heart the shadow dims the gas but does not change its
    // colour, so the heart is cyan throughout instead of a grey mix)
    float excitation = light * mix(0.35 + 0.65 * shadow, 1.0, smoothstep(0.15, 0.6, m.g) * m.a) * (0.5 + 0.95 * m.g);
    excitation = max(excitation, envelope * (0.20 + 0.30 * big.a));
    float red = smoothstep(end_nebula_red.x, end_nebula_red.y, big.b) * (1.0 - m.a);
    excitation *= 1.0 - 0.85 * red;
    excitation = max(excitation, young_light * (0.35 + 0.65 * young_shadow));
    excitation = max(excitation, 0.80 * smoothstep(0.1, 0.6, young_glow));
    excitation = clamp01(max(excitation, 0.85 * smoothstep(0.1, 0.6, glow)));
    float lit = max(shadow, young_shadow * smoothstep(0.2, 0.6, young_light));
#if defined SKY_BLACK_HOLE
    lit = max(lit, end_nebula_hole_look.z * young_shadow * smoothstep(0.05, 0.30, hole_light));
#endif

    // (the most excited gas a little dimmer, so the heart stays cyan instead of
    // burning out to white)
    vec3 emission = rho * (end_nebula_emission_look.x * (1.0 + 2.2 * red)
            + end_nebula_emission_look.y * sqr(excitation) * (1.0 - 0.30 * smoothstep(0.75, 1.0, excitation)))
        * (0.22 + 0.78 * lit) * mix(1.0, end_nebula_body.z, body) * end_nebula_ramp(excitation);
    emission += (end_nebula_rim_gain * (front * light + young_front * young_light) * amount) * end_nebula_rim_color;
    emission += (end_nebula_dust_glow_gain * delta * light) * end_nebula_dust_glow;
#if defined SKY_BLACK_HOLE
    // The black hole's light, scattered by the gas (v0.7.2.2): more of it
    // forward (the gas seen in front of the black hole), its rims on the
    // edges turned to it
    vec3 seen_along = rel - field.origin;
    float forward = max0(dot(to_hole, seen_along)) / (hole_distance * max(length(seen_along), 1.0));
    emission += (end_nebula_hole_look.x * rho * hole_light * (0.20 + 0.80 * young_shadow)
        * (0.50 + 1.20 * sqr(sqr(forward))) * mix(1.0, end_nebula_body.z, body)
        + end_nebula_hole_look.y * end_nebula_rim_gain * young_front * hole_light * amount) * end_nebula_hole_color;
#endif

    // The dust's edges turned to the cluster glow too (the pillars' rims):
    // only where the dust thins towards it
    float dust_front = clamp01(3.0 * (delta - probe_delta)) * (1.0 - smoothstep(0.3, 0.7, delta));
    emission += (end_nebula_rim_gain * dust_front * light * shadow) * end_nebula_rim_color;

    // The heart's glow, with the fine wisps in it
    // (v0.7.1.8: cyan, white only at its very centre; the young stars' is
    // smaller and cyan) and the teal veil in wisps far round them
    float wisps = 0.45 + 0.9 * fine.b;
    emission += (end_nebula_heart_glow.x * glow * wisps) * mix(end_nebula_ramp_6, end_nebula_ramp_7 + 0.5, smoothstep(0.75, 1.0, glow));
    emission += (end_nebula_heart_glow.x * young_glow * wisps) * end_nebula_ramp_6;
    emission += (end_nebula_veil.x * veil * smoothstep(0.35, 0.70, 0.5 * mid.g + 0.5 * fine.g) * wisps) * end_nebula_ramp_5;

#if END_NEBULA_MOTION != 0
    // Fronts of brightness leaving the cluster
    float ring = 0.5 + 0.5 * sin(6.2831853
        * ((cluster_distance + end_nebula_wave.z * (big.r - 0.5)) / end_nebula_wave.x - field.wave));
    emission *= 1.0 + end_nebula_wave.y * sqr(sqr(ring)) * smoothstep(0.04, 0.35, light);
#endif

    // Farther clouds: a little dimmer, flatter (depth cue)
    float far = smoothstep(end_nebula_depth_fade.x, end_nebula_depth_fade.y, r);
    emission *= 1.0 - 0.35 * far;

    gas = rho;
    dust = delta * end_nebula_dust_amount;
    return emission;
}

// The nebula along a view ray between distances from and to (blocks), with
// steps samples spaced evenly in log distance. pixel: angular size of a
// pixel; clear: how much of it is kept. Returns the light it adds ([0]) and
// how much of what is behind it gets through, per colour ([1]).
mat2x3 end_nebula_march(vec3 dir, EndNebulaField field, float pixel, float from, float to, const int steps, float clear, float clear_dust) {
    float log_from = log(from);
    float log_step = (log(to) - log_from) / float(steps);
    float opacity = min(float(END_NEBULA_INTENSITY), 1.0) * 0.001;
    vec3 emission = vec3(0.0);
    vec3 transmittance = vec3(1.0);
    for (int i = 0; i < steps; ++i) {
        float t0 = exp(log_from + float(i) * log_step);
        float t1 = exp(log_from + float(i + 1) * log_step);
        float t = exp(log_from + (float(i) + field.jitter) * log_step);

        vec3 rel = field.origin + dir * t;
        float r = length(rel);
        float gas, dust;
        vec3 light = end_nebula_sample(rel, r, field, pixel * r, gas, dust);
        float dt = t1 - t0;
        emission += transmittance * light * (clear * end_nebula_gain * 0.001 * dt);
        transmittance *= exp(-(end_nebula_absorption.x * gas + end_nebula_absorption.y * clear_dust * dust)
            * end_nebula_dust_color * (clear * opacity * dt));
        if (max(max(transmittance.r, transmittance.g), transmittance.b) < 0.01) break;
    }

    return mat2x3(end_nebula_grade(emission) * float(END_NEBULA_INTENSITY), transmittance);
}

#if defined SKY_BLACK_HOLE && END_NEBULA_MOTION != 0 && END_BLACK_HOLE_PULL != 0
// A direction turned by an angle round an axis (unit vectors)
vec3 end_nebula_turn(vec3 v, vec3 axis, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return v * c + cross(axis, v) * s + axis * (dot(axis, v) * (1.0 - c));
}

// The far part falling into the black hole (v0.7.2.1, see
// end_nebula_infall_reach): as end_nebula_march(), its samples alternating
// between two copies of the nebula, each looked up where what is seen now was
// `life` of a cycle ago (-0.5..0.5) and weighted by the cross-fade. Each
// copy's samples are spread over two steps, so both cover every distance.
// amount: 0 outside the black hole's reach (the plain march), 1 well inside
mat2x3 end_nebula_march_falling(vec3 dir, EndNebulaField field, float pixel, float from, float to, const int steps, float units, float amount) {
    // This direction's place in the cycle
    float cycle = fract(field.fall + end_nebula_infall_phase
        * (sin(3.1 * dir.x + 1.7 * dir.z + 0.6) + sin(2.3 * dir.y - 2.9 * dir.z + 2.1)));
    vec2 life = vec2(cycle - 0.5, fract(cycle + 0.5) - 0.5);
    vec2 weight = mix(vec2(1.0), 2.0 - 4.0 * abs(life), amount);

    // Where each copy is looked up: farther from the axis for what has yet to
    // fall, and turned round it
    vec3 axis = cross(field.hole, dir);
    axis /= max(length(axis), 1e-4);
    vec3 dirs[2];
    for (int k = 0; k < 2; ++k) {
        float fallen = end_sky_infall_from(units, amount * life[k] * (end_nebula_infall_rate * end_nebula_flow_period * end_nebula_flow_speed));
        weight[k] *= mix(1.0, smoothstep(0.0, 1.0, fallen), amount);
        float moved = clamp(pow(max(fallen, 0.0), 1.0 / 3.0) - units, -end_nebula_infall_travel, end_nebula_infall_travel);
        dirs[k] = end_nebula_turn(
            end_nebula_turn(dir, axis, moved / field.hole_scale),
            field.hole,
            end_nebula_infall_turn * moved / max(units, 1.0)
        );
    }
    // (what one copy lost at the axis the other makes up for)
    weight *= 2.0 / max(weight.x + weight.y, 1e-3);

    float log_from = log(from);
    float log_step = (log(to) - log_from) / float(steps);
    float opacity = min(float(END_NEBULA_INTENSITY), 1.0) * 0.001;
    vec3 emission = vec3(0.0);
    vec3 transmittance = vec3(1.0);
    float spread = (field.jitter - 0.5) * (1.0 + amount);
    for (int i = 0; i < steps; ++i) {
        float t0 = exp(log_from + float(i) * log_step);
        float t1 = exp(log_from + float(i + 1) * log_step);
        float t = exp(log_from + (float(i) + 0.5 + spread) * log_step);
        int k = i & 1;

        vec3 rel = field.origin + dirs[k] * t;
        float r = length(rel);
        float gas, dust;
        vec3 light = end_nebula_sample(rel, r, field, pixel * r, gas, dust);
        float dt = (t1 - t0) * weight[k];
        emission += transmittance * light * (end_nebula_gain * 0.001 * dt);
        transmittance *= exp(-(end_nebula_absorption.x * gas + end_nebula_absorption.y * dust)
            * end_nebula_dust_color * (opacity * dt));
        if (max(max(transmittance.r, transmittance.g), transmittance.b) < 0.01) break;
    }

    return mat2x3(end_nebula_grade(emission) * float(END_NEBULA_INTENSITY), transmittance);
}
#endif

// Photon Original (v0.6.7.3, v0.6.7.4, v0.6.8.1, v0.7.0): how much of the nebula and the sky
// behind the black hole's outer disc is kept. Photon's purple sky, unlike the
// Cinematic Void's black, fills the space round the disc and the purple nebula
// adds to it, so from afar the faint outer disc and its halo dissolve into
// it. A dark surround - darkest just outside the shadow, back to normal
// gradually further out - gives the black hole its outline back; its own
// light (disc, halo) is added afterwards and is untouched. Measured in the
// black hole's own units (as bh_impact() does, so it follows its Size option;
// the shadow's edge is at ~1.1, the outer disc reaches ~4). Cinematic Void:
// always 1. v0.6.8.1.1: darkest (5% left) until 2.5 units, just past the
// outer disc and its glow, back to normal over 2.5..7.5 (8% left at 3, 26% at
// 4, half at 5, 80% at 6); at a 110 degree FOV the whole band is already
// wider than the screen, so a longer reach would not help: the purple left
// there came from the End fog, which now gets the same surround
// (include/fog/end_fog_vl.glsl). v0.7.0: fully black (none left) until 3
// units and back to normal by 9, so the orange disc stands out against black
const vec3 end_nebula_black_hole_surround_look = vec3(1.0, 3.0, 9.0); // strength, from, to
float end_nebula_black_hole_surround(vec3 dir) {
#if defined SKY_BLACK_HOLE && CONCEPT_SKY_STYLE == CONCEPT_SKY_PHOTON_ORIGINAL
    float apparent_scale
        = pow(max(END_BLACK_HOLE_SIZE, 0.05), BH_SIZE_EXPONENT) * BH_PRESENCE;
    float camera_distance
        = max(BH_CAMERA_DISTANCE / apparent_scale, BH_MIN_CAMERA_DISTANCE);
    float units = camera_distance
        * fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0));
    return 1.0 - end_nebula_black_hole_surround_look.x * (1.0 - smoothstep(
        end_nebula_black_hole_surround_look.y,
        end_nebula_black_hole_surround_look.z,
        units
    ));
#else
    return 1.0;
#endif
}

// A close wisp at a point (see end_nebula_close_shell): its own noise at two
// scales, drifting with the wind; lit from the cluster's side (one probe of
// its form towards it), amber and gold, with a little dust in it
vec3 end_nebula_close_sample(vec3 rel, float r, EndNebulaField field, float pixel, out float gas, out float dust) {
    gas = 0.0;
    dust = 0.0;

    float shell = smoothstep(end_nebula_close_shell.x, end_nebula_close_shell.y, r)
        * (1.0 - smoothstep(end_nebula_close_shell.z, end_nebula_close_shell.w, r));
    if (shell <= 0.0) return vec3(0.0);

    vec3 p = rel + field.wind;
    vec4 form = texture(end_nebula_noise, p * end_nebula_close_scales.x + vec3(0.21, 0.63, 0.09));
    float strand = 0.45 * form.r + 0.55 * form.g;
    float from = end_nebula_close.x - 0.5 * end_nebula_coverage_shift;
    float wisp = shell * smoothstep(from, from + end_nebula_close.y, strand);
    if (wisp <= 0.0) return vec3(0.0);

    vec4 detail = texture(end_nebula_noise, p * end_nebula_close_scales.y + vec3(0.57, 0.31, 0.77));
    detail = mix(vec4(0.52, 0.36, 0.40, 0.49), detail,
        smoothstep(2.0, 4.0, 1.0 / (end_nebula_close_scales.y * 24.0 * pixel)));
    float rho = end_nebula_close.z * wisp
        * (smoothstep(0.30, 0.58, 0.55 * detail.r + 0.45 * form.r) + 0.6 * sqr(detail.g));

    vec3 to_cluster = normalize(field.cluster - rel);
    vec4 probe = texture(end_nebula_noise, (p + to_cluster * 110.0) * end_nebula_close_scales.x + vec3(0.21, 0.63, 0.09));
    float lit = clamp(0.65 + 4.0 * (strand - 0.45 * probe.r - 0.55 * probe.g), 0.30, 1.2);

    float excitation = clamp01(0.13 + 0.18 * form.a);
    gas = rho;
    dust = 0.25 * rho * smoothstep(0.55, 0.80, detail.b) * end_nebula_dust_amount;
    return rho * (end_nebula_emission_look.x + end_nebula_emission_look.y * sqr(excitation)) * lit
        * end_nebula_ramp(excitation);
}

// The far part (beyond end_nebula_range.z): looked up along the black hole's
// lensed direction, behind the black hole and the stars
mat2x3 end_nebula_behind(vec3 lensed_dir, EndNebulaField field, float pixel) {
#if defined SKY_BLACK_HOLE && END_NEBULA_MOTION != 0 && END_BLACK_HOLE_PULL != 0
    // (v0.7.2.1) Round the black hole it falls into it; Pull Speed (v0.7.2.3)
    // sets how fast its cycle runs, so the two copies stay as close as they
    // are at Normal
    float units = field.hole_scale * fast_acos(clamp(dot(lensed_dir, field.hole), -1.0, 1.0));
    float falling = (1.0 - smoothstep(end_nebula_infall_reach.x, end_nebula_infall_reach.y, units))
        * smoothstep(end_nebula_infall_axis.x, end_nebula_infall_axis.y, units);
    if (falling > 0.0) {
        return end_nebula_march_falling(
            lensed_dir, field, pixel, end_nebula_range.z, end_nebula_range.y, end_nebula_steps_far, units, falling
        );
    }
#endif
    return end_nebula_march(
        lensed_dir, field, pixel, end_nebula_range.z, end_nebula_range.y, end_nebula_steps_far, 1.0, 1.0
    );
}

// The near part: along the unlensed direction, over the black hole and the
// distant stars, kept clear round the black hole (Photon Original: dimmed
// round it, see above)
mat2x3 end_nebula_front(vec3 dir, EndNebulaField field, float pixel) {
#if defined SKY_BLACK_HOLE
    float clear = smoothstep(
        end_nebula_hole_clear.x,
        end_nebula_hole_clear.y,
        fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0))
    );
    float clear_dust = smoothstep(
        end_nebula_hole_clear_dust.x,
        end_nebula_hole_clear_dust.y,
        fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0))
    );
#else
    const float clear = 1.0;
    const float clear_dust = 1.0;
#endif
    // (v0.7.4: fully clear, the march adds no light and hides nothing)
    if (clear <= 0.0) return mat2x3(vec3(0.0), vec3(1.0));
    mat2x3 part = end_nebula_march(
        dir, field, pixel, end_nebula_range.x, end_nebula_range.z, end_nebula_steps_near, clear, clear_dust
    );
    float surround = end_nebula_black_hole_surround(dir);
    return mat2x3(part[0] * surround, mix(vec3(1.0), part[1], surround));
}

// The close wisps: along the unlensed direction, over everything, the planet
// included (they are nearer than its orbit); kept clear round the black hole
// like the near part, and thin in front of the heart
mat2x3 end_nebula_close_wisps(vec3 dir, EndNebulaField field, float pixel) {
    float clear = mix(0.2, 1.0, smoothstep(
        end_nebula_close_heart.x,
        end_nebula_close_heart.y,
        fast_acos(clamp(dot(dir, normalize(field.cluster)), -1.0, 1.0))
    ));
#if defined SKY_BLACK_HOLE
    clear *= smoothstep(
        end_nebula_hole_clear.x,
        end_nebula_hole_clear.y,
        fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0))
    );
#endif
    clear *= end_nebula_black_hole_surround(dir);
    if (clear < 0.01) return mat2x3(vec3(0.0), vec3(1.0));

    float log_from = log(end_nebula_close_range.x);
    float log_step = (log(end_nebula_close_range.y) - log_from) / float(end_nebula_close_steps);
    float opacity = min(float(END_NEBULA_INTENSITY), 1.0) * 0.001;
    vec3 emission = vec3(0.0);
    vec3 transmittance = vec3(1.0);
    for (int i = 0; i < end_nebula_close_steps; ++i) {
        float t0 = exp(log_from + float(i) * log_step);
        float t1 = exp(log_from + float(i + 1) * log_step);
        float t = exp(log_from + (float(i) + field.jitter) * log_step);

        vec3 rel = field.origin + dir * t;
        float gas, dust;
        vec3 light = end_nebula_close_sample(rel, length(rel), field, pixel * t, gas, dust);
        float dt = t1 - t0;
        emission += transmittance * light * (clear * end_nebula_gain * 0.001 * dt);
        transmittance *= exp(-(end_nebula_absorption.x * gas + end_nebula_absorption.y * dust)
            * end_nebula_dust_color * (clear * opacity * dt));
    }

    return mat2x3(end_nebula_grade(emission) * float(END_NEBULA_INTENSITY), transmittance);
}

// The noise read smoothly (its texels blended with a smooth curve instead of
// straight lines): the sea's large relief is read so close that plain
// filtering would show the texels as flat facets with creases between them
vec4 end_nebula_noise_smooth(vec3 tiles) {
    vec3 texel = tiles * 96.0 - 0.5;
    vec3 whole = floor(texel);
    vec3 part = texel - whole;
    part = part * part * (3.0 - 2.0 * part);
    return texture(end_nebula_noise, (whole + part + 0.5) * (1.0 / 96.0));
}

// How much of the cluster's light the sea takes (v0.7.1.12): capped, so near
// the heart it is no bluer than under the island
const float end_nebula_basin_blue = 0.28;

// The canopy (v0.7.1.12; option Nebula Canopy): the sea's sister layer, high
// in the End's sky, so the sky has the Void's composition too (soft cyan and
// amber behind the crisp amber clouds). In patches, not a ceiling: the black
// gaps, the stars and the clouds stay. A bowl like the sea, above: it starts
// this high over the island (blocks) and climbs away from it, so it is only
// seen high up (above about 22 degrees), clear of the black hole and the
// heart. Its gaps (noise: from, to; many), how opaque it is, the least light
// it gets (so it has cyan patches all round, not only near the heart)
const float end_nebula_canopy_height = 1300.0;
const vec2 end_nebula_canopy_gap = vec2(0.30, 0.48);
const float end_nebula_canopy_opacity = 0.88;
const float end_nebula_canopy_light = 0.20;
// v0.7.1.13: both layers are kept clear round the heart (radians from the
// cluster: none, all) and fade where they are seen at a grazing angle (sine
// of the angle between the view and the surface: none, all), where their
// texture would stretch into streaks
const vec2 end_nebula_basin_heart = vec2(0.20, 0.42);
const vec2 end_nebula_basin_grazing = vec2(0.10, 0.30);

// The surface of the sea (side < 0) or the canopy (side > 0): its height
// (blocks, relative to the island) at a horizontal place, and how much of it
// is there (its gaps, its outer edge)
float end_nebula_basin_height(vec2 xz, EndNebulaField field, float side, out float cover) {
    bool canopy = side > 0.0;
    vec4 relief = end_nebula_noise_smooth(vec3(xz.x, 0.0, xz.y) * end_nebula_basin_scales.x
        + (canopy ? vec3(0.71, 0.18, 0.27) : vec3(0.33, 0.52, 0.81)));
    vec2 gap = canopy ? end_nebula_canopy_gap : end_nebula_basin_gap;
    cover = smoothstep(
            gap.x - 0.5 * end_nebula_coverage_shift,
            gap.y - 0.5 * end_nebula_coverage_shift,
            0.55 * relief.g + 0.45 * relief.a
        ) * (1.0 - smoothstep(end_nebula_basin_edge.x, end_nebula_basin_edge.y, length(xz)));
    if (canopy) {
        return end_nebula_canopy_height
            + dot(xz, xz) / (2.0 * end_nebula_basin_shape.x)
            + end_nebula_basin_relief.x * (relief.r - 0.5);
    }
    return -end_nebula_basin_depth
        + dot(xz, xz) / (2.0 * end_nebula_basin_shape.x)
        + end_nebula_basin_relief.x * (relief.r - 0.5);
}

// The sea (side < 0) or the canopy (side > 0) along a view ray: found like a
// terrain (steps evenly spaced in log distance, then one refinement), shaded
// as a glowing surface lit by the cluster. Returns its light ([0]) and how
// much of what is behind it gets through ([1]). Drawn after the nebula's far
// part and the stars, before its near part
mat2x3 end_nebula_surface(vec3 dir, EndNebulaField field, float pixel, float side) {
    mat2x3 none = mat2x3(vec3(0.0), vec3(1.0));
    bool canopy = side > 0.0;
    // (neither is drawn near the horizon, where it could only be seen edge-on,
    // its texture stretched into streaks: height of the view direction)
    float band = canopy ? smoothstep(0.19, 0.44, dir.y) : 1.0 - smoothstep(-0.35, -0.11, dir.y);
    if (band < 0.01) return none;

    // Kept clear round the black hole
    float keep = end_nebula_black_hole_surround(dir) * min(float(END_NEBULA_INTENSITY), 1.0);
#if defined SKY_BLACK_HOLE
    keep *= smoothstep(
        end_nebula_basin_hole.x,
        end_nebula_basin_hole.y,
        fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0))
    );
#endif
    keep *= smoothstep(
        end_nebula_basin_heart.x,
        end_nebula_basin_heart.y,
        fast_acos(clamp(dot(dir, normalize(field.cluster)), -1.0, 1.0))
    );
    if (keep < 0.01) return none;

    float log_from = log(end_nebula_basin_range.x);
    float log_step = (log(end_nebula_basin_range.y) - log_from) / float(end_nebula_basin_steps);
    float t_before = end_nebula_basin_range.x;
    float above_before = 1.0;
    float t_hit = -1.0;
    float bite = 1.0; // how far into the layer the step that found it got (of its length)
    float cover = 0.0;
    // (v0.7.4: the surface is never farther than half its large relief from
    // its smooth bowl. A step still farther than that from the bowl is
    // certainly not at the surface: its height is not read - only later,
    // if the very next step finds the surface and needs it for the
    // refinement. Same steps, same result)
    float base_height = canopy ? end_nebula_canopy_height : -end_nebula_basin_depth;
    bool before_known = true;
    for (int i = 0; i <= end_nebula_basin_steps; ++i) {
        float t = exp(log_from + (float(i) + field.jitter - 0.5) * log_step);
        vec3 p = field.origin + dir * t;
        float c;
        float bowl = base_height + dot(p.xz, p.xz) / (2.0 * end_nebula_basin_shape.x);
        if (side * (bowl - p.y) > 0.5 * end_nebula_basin_relief.x + 1.0) {
            t_before = t;
            before_known = false;
            continue;
        }
        float above = side * (end_nebula_basin_height(p.xz, field, side, c) - p.y);
        if (above < 0.0) {
            if (i == 0) return none; // already past it (the island never is)
            if (!before_known) {
                vec3 p_before = field.origin + dir * t_before;
                above_before = side * (end_nebula_basin_height(p_before.xz, field, side, c) - p_before.y);
            }
            t_hit = mix(t_before, t, above_before / (above_before - above));
            bite = -above / (t - t_before);
            break;
        }
        t_before = t;
        above_before = above;
        before_known = true;
    }
    if (t_hit < 0.0) return none;

    vec3 p = field.origin + dir * t_hit;
    float height = end_nebula_basin_height(p.xz, field, side, cover);
    if (cover < 0.004) return none;

    // Its slope (two more heights), bumped by the middle noise. Its detail
    // fades where the grazing view squeezes it below a few pixels, instead of
    // smearing into streaks
    float reach = max(160.0, 0.012 * t_hit);
    float c;
    float height_x = end_nebula_basin_height(p.xz + vec2(reach, 0.0), field, side, c);
    float height_z = end_nebula_basin_height(p.xz + vec2(0.0, reach), field, side, c);
    vec4 mid = texture(end_nebula_noise, p * end_nebula_basin_scales.y + field.drift - field.carry[3] + vec3(0.09, 0.47, 0.25));
    vec4 fine = texture(end_nebula_noise, p * end_nebula_scales.z + 1.7 * field.drift - field.carry[4] + vec3(0.29, 0.53, 0.11));
    // (the face seen: the sea's top, the canopy's underside)
    vec3 smooth_normal = -side * normalize(vec3(height - height_x, reach, height - height_z));
    float footprint = pixel * t_hit / max(-dot(dir, smooth_normal), 0.05);
    fine = mix(vec4(0.52, 0.36, 0.40, 0.49), fine, smoothstep(2.0, 4.0, 1.0 / (end_nebula_scales.z * 24.0 * footprint)));
    mid = mix(vec4(0.52, 0.36, 0.40, 0.49), mid, smoothstep(1.0, 3.0, 1.0 / (end_nebula_basin_scales.y * 24.0 * footprint)));
    vec3 normal = -side * normalize(vec3(
        height - height_x + end_nebula_basin_relief.y * (mid.r - 0.5),
        reach,
        height - height_z + end_nebula_basin_relief.y * (mid.b - 0.5)
    ));

    // Lit by the cluster: nearer and turned to it = more excited (cyan), its
    // crests turned to it edged in the rim colour; behind a crest (the
    // surface a little way towards the cluster stands higher) it is in shadow
    vec3 to_cluster = field.cluster - p;
    float cluster_distance = length(to_cluster);
    vec3 towards = to_cluster / cluster_distance;
    // (for the canopy the light comes as it does for the sea, mirrored: from
    // below at the same angle, or its underside would hardly be lit)
    if (canopy) towards = normalize(vec3(towards.x, -(towards.y + 0.25), towards.z));
    float facing = dot(normal, towards);
    float light = 1.0 / (1.0 + sqr(cluster_distance / end_nebula_light_reach));
    float height_towards = end_nebula_basin_height(p.xz + towards.xz * end_nebula_basin_shadow.x, field, side, c);
    float shadow = 1.0 - end_nebula_basin_shadow.y
        * smoothstep(0.0, 260.0, -side * (height_towards - height - towards.y * end_nebula_basin_shadow.x));
    // (v0.7.1.12: the cluster's light capped, so near the heart the sea is no
    // bluer than under the island; the canopy is lit by the young stars too
    // and never gets less than a little, for cyan patches all round)
    float excited = min(light, end_nebula_basin_blue);
    if (canopy) {
        float young = 0.0;
        for (int k = 0; k < 5; ++k) {
            vec3 to = field.young[k] - p;
            young = max(young, 1.0 / (1.0 + dot(to, to) * (1.0 / sqr(end_nebula_star_light.x))));
        }
        excited = max(max(excited, min(young, end_nebula_basin_blue)), end_nebula_canopy_light);
    }
    float excitation = clamp01(excited * (0.75 + 0.55 * facing) * 1.35 + 0.05 + 0.22 * mid.a);
    // (straight from gold to aqua: the pale olive between them reads as grey
    // on a surface this large)
    excitation = clamp01(excitation + 0.24 * smoothstep(0.38, 0.56, excitation));
    float lit = (0.26 + 0.74 * smoothstep(-0.15, 0.55, facing)) * shadow;
    float grain = 0.65 + 0.50 * (0.6 * fine.r + 0.4 * mid.g) + 0.4 * sqr(fine.g);
    vec3 emission = (end_nebula_basin_look.x + end_nebula_basin_look.y * sqr(excitation)) * lit * grain
        * end_nebula_ramp(excitation);
    emission += (end_nebula_basin_look.z * end_nebula_rim_gain * light * shadow
        * smoothstep(0.35, 0.75, facing) * smoothstep(0.55, 0.80, mid.r)) * end_nebula_rim_color;
#if defined SKY_BLACK_HOLE
    // The black hole's light (v0.7.2.2): the slopes turned to it, their
    // crests most (for the canopy mirrored, as the cluster's)
    vec3 to_hole = field.hole_place - p;
    float hole_distance = length(to_hole);
    vec3 hole_towards = to_hole / hole_distance;
    if (canopy) hole_towards = normalize(vec3(hole_towards.x, -(hole_towards.y + 0.25), hole_towards.z));
    float hole_facing = dot(normal, hole_towards);
    float hole_light = field.hole_power / sqr(1.0 + sqr(hole_distance / end_nebula_hole_light.y));
    emission += (end_nebula_hole_basin.x * hole_light * grain
        * (smoothstep(0.05, 0.55, hole_facing)
            + end_nebula_hole_basin.y * end_nebula_rim_gain * smoothstep(0.30, 0.70, hole_facing) * smoothstep(0.50, 0.80, mid.r)))
        * end_nebula_hole_color;
#endif
#if END_NEBULA_MOTION != 0
    // Fronts of brightness leaving the cluster
    float ring = 0.5 + 0.5 * sin(6.2831853
        * ((cluster_distance + end_nebula_wave.z * (mid.g - 0.5)) / end_nebula_wave.x - field.wave));
    emission *= 1.0 + end_nebula_wave.y * sqr(sqr(ring)) * smoothstep(0.04, 0.35, light);
#endif

    // Dimmer far away (depth), thin at its gaps and outer edge, fading out
    // before the end of the search
    emission *= 1.0 - end_nebula_basin_haze.z * smoothstep(end_nebula_basin_haze.x, end_nebula_basin_haze.y, t_hit);
    float alpha = (canopy ? end_nebula_canopy_opacity : 0.88) * cover * (0.45 + 0.55 * smoothstep(0.30, 0.60, 0.5 * mid.r + 0.5 * fine.b))
        * (1.0 - smoothstep(0.55 * end_nebula_basin_range.y, 0.95 * end_nebula_basin_range.y, t_hit))
        * smoothstep(end_nebula_basin_range.x, 2.0 * end_nebula_basin_range.x, t_hit) * keep
        * smoothstep(end_nebula_basin_grazing.x, end_nebula_basin_grazing.y, -dot(dir, smooth_normal)) * band
        * smoothstep(0.0, 0.06, bite);

    // (v0.7.8: the sea in its own colour, the canopy in the nebula's)
    return mat2x3(
        end_nebula_grade(emission, canopy ? end_sky_nebula_tint : end_sky_sea_tint)
            * (alpha * end_nebula_gain * 4.0 * float(END_NEBULA_INTENSITY)),
        vec3(1.0 - alpha)
    );
}

// The sea, below the End (option Nebula Sea)
mat2x3 end_nebula_basin(vec3 dir, EndNebulaField field, float pixel) {
#ifdef END_NEBULA_SEA
    return end_nebula_surface(dir, field, pixel, -1.0);
#else
    return mat2x3(vec3(0.0), vec3(1.0));
#endif
}

// The canopy, high in the End's sky (option Nebula Canopy)
mat2x3 end_nebula_canopy(vec3 dir, EndNebulaField field, float pixel) {
#ifdef END_NEBULA_CANOPY
    return end_nebula_surface(dir, field, pixel, 1.0);
#else
    return mat2x3(vec3(0.0), vec3(1.0));
#endif
}

float end_nebula_luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// How much the nebula's glowing gas veils the distant stars behind it (v0.6.8):
// dense, bright gas hides faint stars, thin gas lets them through (its dust is
// handled by its own transmittance)
float end_nebula_star_veil(vec3 emission) {
    return 1.0 - 0.6 * smoothstep(0.03, 0.30, end_nebula_luminance(emission));
}

// Cosmic dust particles (v0.6.7.1, see the header), over the sky so far.
// base_luminance: the sky's luminance before the nebula was added; pixel:
// angular size of a pixel.
// One population of particles along a view ray: walks the world cells the ray
// crosses between range.x and range.y (a 3D DDA); each may hold one particle
// at a fixed place in it. Accumulates their glow and how much they cover.
void end_nebula_particle_grid(
    vec3 dir,
    vec3 origin,
    float cell_size,
    vec2 range,
    const int steps,
    float radius,
    float seed,
    float pixel,
    inout float glow,
    inout float shade
) {
    vec3 safe_dir = mix(dir, vec3(1e-6), lessThan(abs(dir), vec3(1e-6)));
    vec3 inv_dir = 1.0 / safe_dir;
    vec3 cell = floor((origin + dir * range.x) / cell_size);
    vec3 step_dir = sign(safe_dir);
    vec3 t_max = ((cell + max(step_dir, 0.0)) * cell_size - origin) * inv_dir;
    vec3 t_delta = abs(cell_size * inv_dir);

    for (int i = 0; i < steps; ++i) {
        vec4 h = hash4(cell + seed);
        if (h.w < end_nebula_particle_share) {
            vec3 to_particle = (cell + 0.2 + 0.6 * h.xyz) * cell_size - origin;
            float t = dot(to_particle, dir);
            if (t > range.x && t < range.y) {
                // Angular distance from the ray and angular size (never below
                // a pixel, so it does not shimmer under TAA)
                float angle = length(to_particle - dir * t) / t;
                float size = max(
                    radius * (0.6 + 0.2 * h.w / end_nebula_particle_share) / t,
                    0.9 * pixel
                );
                float disc = exp(-sqr(angle / size));
                float fade = smoothstep(range.x, 1.6 * range.x, t)
                    * (1.0 - smoothstep(0.6 * range.y, range.y, t));
                // A particle covers about its pixel: those larger than a pixel
                // (the closest) are not brighter in total
                glow = max(glow, disc * fade * min(1.0, 4.0 * sqr(0.9 * pixel / size)));
                shade = max(shade, disc * fade);
            }
        }

        // To the next cell along the ray
        float entered;
        if (t_max.x < t_max.y && t_max.x < t_max.z) {
            entered = t_max.x;
            cell.x += step_dir.x;
            t_max.x += t_delta.x;
        } else if (t_max.y < t_max.z) {
            entered = t_max.y;
            cell.y += step_dir.y;
            t_max.y += t_delta.y;
        } else {
            entered = t_max.z;
            cell.z += step_dir.z;
            t_max.z += t_delta.z;
        }
        // (v0.7.6: a particle is never more than its cell's diagonal before
        // the place the ray enters the cell: once that is past the range,
        // nothing ahead can be in it, and the walk ends. Same particles)
        if (entered > range.y + 1.7321 * cell_size) break;
    }
}

vec3 end_nebula_particles(vec3 dir, EndNebulaField field, vec3 sky, float base_luminance, float pixel) {
#if END_NEBULA_DUST == 0
    return sky;
#else
    // Kept clear round the black hole (v0.7.4: found first; fully clear,
    // they add nothing, so they are not looked for)
#if defined SKY_BLACK_HOLE
    float clear = smoothstep(
        0.30,
        0.45,
        fast_acos(clamp(dot(dir, end_black_hole_direction()), -1.0, 1.0))
    );
    if (clear <= 0.0) return sky;
#else
    const float clear = 1.0;
#endif

    float glow = 0.0;
    float shade = 0.0;
    // The closest suspended dust (fine grains, 12 to 60 blocks), then the
    // farther dust (48 to 300 blocks)
    end_nebula_particle_grid(
        dir, field.observer,
        end_nebula_particle_near_cell, end_nebula_particle_near_range,
        end_nebula_particle_near_steps, end_nebula_particle_near_radius, 57.1,
        pixel, glow, shade
    );
    end_nebula_particle_grid(
        dir, field.observer,
        end_nebula_particle_cell, end_nebula_particle_range,
        end_nebula_particle_steps, end_nebula_particle_radius, 0.0,
        pixel, glow, shade
    );
    if (glow + shade < 1e-4) return sky;

    // They glow faintly and scatter the nebula's light behind them, and dim
    // the brightest gas a little
    float behind = max(end_nebula_luminance(sky) - base_luminance, 0.0);
    vec3 light = ((end_nebula_particle_look.x + end_nebula_particle_look.y * behind) * glow * clear)
        * end_nebula_particle_color;
    float dimming = end_nebula_particle_look.z * shade * smoothstep(0.02, 0.10, behind) * clear;
    return sky * (1.0 - dimming) + light;
#endif
}

// A lower resolution (v0.7.5): drawn by deferred2, read back by deferred4
#include "/include/sky/end_nebula_buffer.glsl"

#endif // CONCEPT_END_NEBULA

#endif // INCLUDE_SKY_END_NEBULA
