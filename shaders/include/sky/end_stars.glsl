#if !defined INCLUDE_SKY_END_STARS
#define INCLUDE_SKY_END_STARS

/*
--------------------------------------------------------------------------------

  include/sky/end_stars:
  Enhanced Star Field of the Photon Cinematic Concept (End, both sky styles).

  With Enhanced Star Field off, the End keeps Photon's own star field
  (include/sky/stars.glsl) exactly as before, in Photon Original and in the
  Cinematic Void alike, and this file adds no code at all.

  Why a separate field rather than a tweak of Photon's:
    - Photon's stars live on a 2D projection of the sky (one disc per
      hemisphere) whose density varies across the sky, and are faded out
      below the horizon: the Void under the island has none. These are placed
      in 3D cells directly on the sphere of directions: the same density
      everywhere, no seam, up, around and down.
    - Photon interpolates neighbouring cells, which draws every star as the
      same 3x3 pixel blob. These are sharp points (0.7 px, up to 1.1 px for
      the rare bright ones).

  Brightness. A star is a point: what the eye reads is its peak on screen, so
  the peak is set directly and does not depend on the FOV or the resolution
  (the v0.4 field conserved each star's energy per pixel, which at a 110
  degree FOV left 90% of the stars 1-2 display levels above the sky:
  present, but invisible). Peaks follow a power law with a visible floor:
  many faint stars, fewer medium ones, rare bright ones.

  Density. Three layers of cells of different sizes, each rotated
  differently, so no grid can be seen. The cells are much larger than a star
  (about 9, 12 and 21 pixels at a 110 degree FOV, and larger at lower FOVs).
  Each star only exists if it lands inside its own cell on the sphere, which
  makes the search exact: a pixel tests its own cell plus only the
  neighbours it can actually receive light from (about 4 cells per layer
  instead of 8; on the longest arcs next to the black hole, about 22 cells
  for the three layers instead of about 50).

  Lensing. The field is looked up along the black hole's lensed direction, and
  stars are stretched into arcs with the black hole's arc model
  (bh_star_lens): each star's distance is measured to the arc segment, so
  sharp points become continuous streaks.

  Depth (v0.6.8). The three layers above are the distant stars, at infinity
  (no parallax), drawn behind the nebula's far part, whose dust hides them
  and whose dense gas veils them. Two more populations are at real distances
  round the island, found on spheres, so they show true parallax when you
  move:
    - intermediate stars, 6 000 blocks away, among the nebula (in front of its
      far part, behind its near part); more of the rare standout stars are
      here, so some bright stars sit in the gas;
    - a few near stars, 2 200 blocks away (in front of the nebula).
  Both are kept clear round the black hole (they are in front of it).

  Brightness (v0.6.8). Many faint stars, fewer medium ones, rare bright ones
  (the power law above), and very rare standout stars, much brighter and a
  little wider, with a faint glow round them. v0.6.8-r1: a star's peak
  (after the lens or depth gain) is softly limited below the screen's white,
  and every star fades out before the edge of its search, so no star becomes
  a large static dot. v0.7.0: about a dozen beacon stars in the whole sky,
  far brighter (past the screen's white, so the bloom spreads them), with a
  wider glow and strong scintillation.

  Colours and the cluster (v0.7.1.6, with the nebula's Hubble palette). The
  stars take the favourite reference's colours: most warm white, gold and
  orange, some white, a few blue-white. In the nebula's heart, round the
  light of its young cluster (end_sky_cluster_position()), a dense knot of
  hot blue-white stars, brighter than the field's, like NGC 6611 in M16.

  The black hole's pull (v0.7.2). The stars round the black hole (out to
  about 7 of its units) no longer only circle it: they fall towards it too,
  at the rate the nebula's gas does (end_sky_pull_rate()), through the lens,
  so they spiral in and stretch into its arcs. Both motions follow the black
  hole's Animation Speed. v0.7.2.1: they speed up as they get closer
  (end_sky_infall_from(): much faster next to it than far from it) and are
  gone when they reach its axis, so they are seen streaming into it.

  Motion. Everything moving is periodic with a whole number of cycles per
  hour, so the hourly wrap of frameTimeCounter never makes the sky jump:
    - scintillation (v0.6.8): every star its own rhythm (about 1 to 4.5 s,
      two incommensurate waves, so it never pulses regularly) and its own
      depth: most stars vary a little, some clearly, a few strongly, never
      together and never off;
    - drift: each layer sways by +-1.5 degrees around its own axis over 10 to
      15 minutes; far from the black hole this is barely perceptible and only
      gives depth (the layers slide against each other), but the lens
      magnifies it near the black hole;
    - pulled stars: around the black hole (up to about 3 shadow radii, where
      the lens stretches stars) an extra population of stars circles around
      it, faster closer in like an orbit, clearly moving but slow. Rotating the
      look-up direction around the black hole's axis is the same as rotating
      the image around it (the lens is symmetric about that axis), so these
      stars stay on the lens' arcs. Each of them lives one 20 s cycle, fading
      in and out, and each cycle draws a new population; two cycles half a
      period apart overlap, so the region never empties and never loops.

--------------------------------------------------------------------------------
*/

// (v0.9.4: by its World option too; in the Overworld, the final sky pass
// only, where it takes Photon's stars' place - include/sky/sky.glsl)
#ifdef CONCEPT_ENHANCED_STARS
#if defined WORLD_END && (CONCEPT_ENHANCED_STARS_WORLD == CONCEPT_WORLD_END || CONCEPT_ENHANCED_STARS_WORLD == CONCEPT_WORLD_BOTH)
#define CONCEPT_END_STARS
#endif
#if defined WORLD_OVERWORLD && defined PROGRAM_DEFERRED4 && (CONCEPT_ENHANCED_STARS_WORLD == CONCEPT_WORLD_OVERWORLD || CONCEPT_ENHANCED_STARS_WORLD == CONCEPT_WORLD_BOTH)
#define CONCEPT_END_STARS
#define CONCEPT_OVERWORLD_STARS
#endif
#endif

#if defined CONCEPT_END_STARS

#include "/include/utility/color.glsl"
#include "/include/utility/random.glsl"
#include "/include/sky/end_sky_common.glsl"

// Layers: cells per radian and orientation. The sizes are mutually
// irrational so the three lattices never line up.
const float end_stars_cells_0 = 44.0;
const float end_stars_cells_1 = 31.0;
const float end_stars_cells_2 = 18.0;
const mat3 end_stars_rotation_0 = mat3(
    0.346929, 0.292215, -0.891207,
    -0.414008, 0.900349, 0.134047,
    0.841568, 0.322462, 0.433337
);
const mat3 end_stars_rotation_1 = mat3(
    -0.297769, 0.871600, -0.389418,
    0.369062, 0.481310, 0.795068,
    0.880413, 0.093027, -0.464994
);
const mat3 end_stars_rotation_2 = mat3(
    -0.839808, -0.170238, -0.515501,
    0.433671, 0.360849, -0.825662,
    0.326577, -0.916955, -0.229217
);
// Fraction of cells holding a star at the default Stars Coverage (0.5)
// (v0.6.8-r1: 0.28 -> 0.34, a few more stars, most of them faint)
const float end_stars_occupancy = 0.40; // v0.7.1.6: 0.34 -> 0.40

// Peak brightness: floor * u^(-1 / beta) + lift, u uniform in (0, 1]. The
// lift only matters for the faintest stars (it doubles them, so they read at
// gameplay distance); the bright ones keep their brightness
const float end_stars_peak_floor = 0.006;
const float end_stars_peak_lift = 0.006;
const float end_stars_peak_rcp_beta = 1.0 / 1.25;
const float end_stars_peak_max = 6.0;
// Stars brighter than this get slightly wider (never beyond sigma_max)
const float end_stars_peak_wide = 0.6;
const float end_stars_sigma_min = 0.7;  // pixels
const float end_stars_sigma_max = 1.1;  // pixels

// Scintillation (v0.6.8, v0.6.8-r1): depth from min to max (most stars
// nearer min: depth grows with a random number to the power below), two
// waves of cycles per hour (the second about 1.7 times faster): about 1 to
// 4.5 s. A star never drops below 1 - max of its light
const vec2 end_stars_twinkle_depth = vec2(0.12, 0.75);
const float end_stars_twinkle_depth_power = 1.6;
const float end_stars_twinkle_cycles_min = 800.0;
const float end_stars_twinkle_cycles_max = 2400.0;

// Standout stars (v0.6.8): share of the stars (per population), their peak
// brightness, width (pixels) and the strength and width of their faint glow
// (v0.6.8-r1: lowered as the populations got denser, so the number of
// standout stars in the sky stays the same)
const vec3 end_stars_standout_share = vec3(0.0033, 0.0078, 0.0038); // distant, intermediate, near
const vec2 end_stars_standout_peak = vec2(2.5, 6.0);
const float end_stars_standout_sigma = 1.05; // v0.6.8-r1: was 1.3
const vec2 end_stars_standout_glow = vec2(0.025, 1.7); // of the peak, times sigma (v0.6.8-r1: was 0.07, 2.0)
// v0.6.8-r1: their scintillation is never weaker than this
const float end_stars_standout_twinkle_min = 0.20;

// Beacon stars (v0.7.0): a dozen in the whole sky (a share of every
// population), far brighter than the standout stars, with a wider glow (which
// the bloom spreads) and strong scintillation: peak brightness, width
// (pixels), glow (of the peak, times the width), how deep their scintillation
// is, and their own soft limit (far above the others')
const float end_stars_beacon_share = 0.0006;
const vec2 end_stars_beacon_peak = vec2(8.0, 14.0);
const float end_stars_beacon_sigma = 1.0;
const vec2 end_stars_beacon_glow = vec2(0.12, 2.2);
const float end_stars_beacon_twinkle = 0.85;
const vec2 end_stars_beacon_knee = vec2(4.0, 14.0);

// Soft limit of a star's peak (v0.6.8-r1), after the lens or depth gain:
// unchanged below knee.x, approaching knee.y above it. Without it the
// standout stars and the brightest intermediate and near stars (depth gain
// up to 2.5) reached 10-15, far past the screen's white: their core clipped,
// so their scintillation could not be seen (static), and their glow ran out
// to the edge of the search, a hard-edged disc of about 8 px (large dots).
// Below the limit the scintillation shows on them too
const vec2 end_stars_peak_knee = vec2(0.8, 1.8);
// Every star fades to nothing between this share of its reach and its reach
// (v0.6.8-r1), so no star ever ends in a hard edge
const float end_stars_edge_fade = 0.55;
// Stars can be this wide (the search reaches 3 of these round the pixel)
const float end_stars_reach_sigma = 1.4;

// Depth populations (v0.6.8): sphere radius (blocks), cells per radian (of
// the sphere seen from its centre), fraction of cells holding a star; how
// much brighter they are than the distant stars (closer); and the angles
// from the black hole (radians) over which they fade in
// (v0.6.8-r1: occupancy 0.30 -> 0.46 and 0.48, denser)
const vec3 end_stars_middle_layer = vec3(6000.0, 34.0, 0.46);
const vec3 end_stars_near_layer = vec3(2200.0, 30.0, 0.48);
const vec2 end_stars_depth_gain = vec2(1.5, 2.5); // intermediate, near
const vec2 end_stars_depth_clear = vec2(0.35, 0.60);
const vec3 end_stars_center = vec3(0.0, 64.0, 0.0);
const mat3 end_stars_rotation_3 = mat3(
    0.612372, -0.353553, 0.707107,
    0.707107, 0.612372, -0.353553,
    -0.353553, 0.707107, 0.612372
);
const mat3 end_stars_rotation_4 = mat3(
    0.433013, 0.750000, -0.500000,
    -0.250000, 0.612372, 0.750000,
    0.866025, -0.250000, 0.433013
);

// Drift of each layer: amplitude (radians) and oscillations per hour
const float end_stars_drift_amplitude = 0.02618; // 1.5 degrees
const vec3 end_stars_drift_axis_0 = vec3(0.301511, 0.904534, -0.301511); // unit
const vec3 end_stars_drift_axis_1 = vec3(-0.741999, 0.212000, 0.635999); // unit
const vec3 end_stars_drift_axis_2 = vec3(0.507020, -0.405616, 0.760530); // unit
const float end_stars_drift_cycles_0 = 4.0; // 15 min
const float end_stars_drift_cycles_1 = 5.0; // 12 min
const float end_stars_drift_cycles_2 = 6.0; // 10 min

// Pulled stars around the black hole. Distances are in black hole local
// units (bh_impact(): the shadow edge is at ~1.1), so they follow Size.
// v0.7.2: they also fall towards it (end_sky_pull_rate(), the rate the
// nebula's gas falls at), over a wider region, so the pull is seen at a
// glance with the camera still; the still stars of the three layers are
// dimmed among them (end_stars_pulled_still: how much is left of them)
const float end_stars_pulled_occupancy = 0.5;
const float end_stars_pulled_still = 0.5;
const float end_stars_pulled_reach_inner = 4.0; // full population inside this
const float end_stars_pulled_reach_outer = 7.0; // none beyond this: the lens
                                                // barely stretches stars there
// Angular speed around the black hole's axis at 1.5 units, falling off
// outwards like an orbit (distance^-1.5): about 5 px/s next to the shadow
// at a 110 degree FOV (twice that at 70 degrees), slower further out, so
// neighbouring stars never move in step
const float end_stars_pulled_speed = 0.042; // radians/second
const float end_stars_pulled_period = 20.0; // seconds: 180 cycles per hour
const float end_stars_pulled_cycles = 180.0;

// Colours (v0.7.1.6, the favourite reference's stars): warm white, gold,
// orange, white, blue-white, and the share of the stars each is (cumulative)
const vec3 end_stars_warm_white = vec3(1.00, 0.92, 0.80) * rec709_to_working_color;
const vec3 end_stars_gold = vec3(1.00, 0.80, 0.56) * rec709_to_working_color;
const vec3 end_stars_orange = vec3(1.00, 0.64, 0.38) * rec709_to_working_color;
const vec3 end_stars_white = vec3(0.95, 0.97, 1.00) * rec709_to_working_color;
const vec3 end_stars_blue = vec3(0.72, 0.83, 1.00) * rec709_to_working_color;
const vec4 end_stars_color_shares = vec4(0.40, 0.65, 0.80, 0.92);

// The heart's cluster (v0.7.1.6): its angular radius (radians, where it has
// thinned to 37%), cells per radian, the share of cells holding a star at its
// centre, their peak brightness (faintest, brightest)
const vec3 end_stars_cluster = vec3(0.10, 80.0, 0.55);
const vec2 end_stars_cluster_peak = vec2(0.6, 5.0);
const mat3 end_stars_rotation_5 = mat3(
    0.707107, 0.000000, -0.707107,
    0.408248, 0.816497, 0.408248,
    0.577350, -0.577350, 0.577350
);

// Rotation of v by angle around the unit axis (Rodrigues)
vec3 end_stars_rotate(vec3 v, vec3 axis, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return v * c + cross(axis, v) * s + axis * (dot(axis, v) * (1.0 - c));
}

// One layer: the stars that can reach this pixel, looked up along layer_dir
// (a unit direction in layer space) with the lensing arc.
//   pixel: angular size of this pixel (radians); gain: lens brightening
//
// Each star only exists if its position on the sphere falls inside its own
// cell. That guarantees that every pixel within reach of a star finds it: a
// star is never found from one pixel and missed from the next, which would
// cut it or, with the sky's slow motion, make it pop in and out. It also
// makes the search exact and small: a star can only reach this pixel if it
// lies within its visible radius (3 sigma) of the pixel's arc segment, so
// along each axis only a neighbour across a face closer than that is
// tested. The box follows the arc's direction, so a long arc near the black
// hole adds only the cells it actually crosses (at most one per side).
vec3 end_stars_layer(
    vec3 layer_dir,
    vec3 layer_tangent,
    float arc,
    float cells,
    float hash_offset,
    float occupancy,
    float pixel,
    float gain,
    float time,
    float standout_share,
    vec4 focus
) {
    vec3 q = layer_dir * cells;
    vec3 cell0 = floor(q);
    vec3 f = q - cell0;
    vec3 reach = (3.0 * end_stars_reach_sigma * pixel + abs(layer_tangent) * arc) * cells;
    ivec3 lo = -ivec3(lessThan(f, reach));             // -1: the lower neighbour too
    ivec3 hi = ivec3(greaterThan(f + reach, vec3(1.0))); // 1: the upper neighbour too
    float rcp_pixel = 1.0 / pixel;

    vec3 stars = vec3(0.0);

    for (int z = lo.z; z <= hi.z; ++z) {
    for (int y = lo.y; y <= hi.y; ++y) {
    for (int x = lo.x; x <= hi.x; ++x) {
        vec3 cell = cell0 + vec3(float(x), float(y), float(z));

        // Cheap occupancy test first: most cells are empty. The cluster's
        // cells (focus.w > 0) thin out away from its centre (focus.xyz)
        float cell_occupancy = occupancy;
        if (focus.w > 0.0) {
            cell_occupancy *= exp(-2.0 * (1.0 - dot(normalize(cell + 0.5), focus.xyz)) / sqr(focus.w));
        }
        if (hash1(cell + hash_offset) >= cell_occupancy) continue;

        vec4 h = hash4(cell + (hash_offset + 19.19));
        vec3 star = normalize(cell + 0.5 + (h.yzw - 0.5) * 0.8);
        if (any(notEqual(floor(star * cells), cell))) continue; // see above

        // Angular offset from this pixel to the star, measured to the arc
        // segment when the lens stretches it; far stars stop here, before
        // any of the more expensive maths
        vec3 offset = star - layer_dir;
        float along = clamp(dot(offset, layer_tangent), -arc, arc);
        float dist = length(offset - layer_tangent * along) * rcp_pixel;
        if (dist > 3.0 * end_stars_reach_sigma) continue;

        float peak = min(
            end_stars_peak_floor
                * pow(max(h.x, 1e-4), -end_stars_peak_rcp_beta)
                + end_stars_peak_lift,
            end_stars_peak_max
        );
        float sigma = clamp(
            end_stars_sigma_min
                * (1.0 + 0.2 * log2(max(peak / end_stars_peak_wide, 1.0))),
            end_stars_sigma_min,
            end_stars_sigma_max
        );

        // Standout stars: very rare, much brighter, a little wider, with a
        // faint glow
        float standout_pick = fract(h.w * 13.37 + h.x * 5.71);
        bool standout = standout_pick < standout_share;
        float glow = 0.0;
        if (standout) {
            peak = mix(end_stars_standout_peak.x, end_stars_standout_peak.y,
                fract(standout_pick * 97.13));
            sigma = end_stars_standout_sigma;
            glow = end_stars_standout_glow.x
                * exp(-0.5 * sqr(dist / (sigma * end_stars_standout_glow.y)));
        }

        // Beacon stars (v0.7.0): rarer still, far brighter
        bool beacon = fract(h.w * 31.71 + h.y * 7.13) < end_stars_beacon_share;
        if (beacon) {
            peak = mix(end_stars_beacon_peak.x, end_stars_beacon_peak.y, fract(h.x * 53.1));
            sigma = end_stars_beacon_sigma;
            glow = end_stars_beacon_glow.x
                * exp(-0.5 * sqr(dist / (sigma * end_stars_beacon_glow.y)));
        }

        // Scintillation: own depth and own rhythm, two waves
        float depth = mix(end_stars_twinkle_depth.x, end_stars_twinkle_depth.y,
            pow(fract(h.z * 3.71 + h.y * 1.37), end_stars_twinkle_depth_power));
        if (standout) depth = max(depth, end_stars_standout_twinkle_min);
        if (beacon) depth = end_stars_beacon_twinkle;
        float cycles_1 = floor(mix(
            end_stars_twinkle_cycles_min,
            end_stars_twinkle_cycles_max + 0.999,
            h.z
        ));
        float cycles_2 = floor(cycles_1 * 1.7 + 13.0);
        float twinkle = 1.0 + depth * (
            0.65 * sin(time * (cycles_1 * (tau / 3600.0)) + tau * h.w)
            + 0.35 * sin(time * (cycles_2 * (tau / 3600.0)) + tau * fract(h.w * 7.7))
        );

        float kind = fract(h.y * 7.31 + h.w * 3.17);
        vec3 tint = kind < end_stars_color_shares.x ? end_stars_warm_white
            : kind < end_stars_color_shares.y ? end_stars_gold
            : kind < end_stars_color_shares.z ? end_stars_orange
            : kind < end_stars_color_shares.w ? end_stars_white
            : end_stars_blue;
        vec3 color = mix(end_stars_white, tint, 0.6 + 0.4 * fract(h.z * 5.13));

        // The cluster's stars: hot, blue-white, brighter
        if (focus.w > 0.0) {
            peak = mix(end_stars_cluster_peak.x, end_stars_cluster_peak.y, sqr(sqr(h.x)));
            color = mix(end_stars_blue, end_stars_white, fract(h.z * 5.13));
        }

        // Soft limit of the peak, then the scintillation on top of it (so it
        // shows on the brightest stars too), and the fade before the reach
        float brightness = peak * gain;
        vec2 knee = beacon ? end_stars_beacon_knee : end_stars_peak_knee;
        if (brightness > knee.x) {
            float room = knee.y - knee.x;
            brightness = knee.x + room * (1.0 - exp(-(brightness - knee.x) / room));
        }
        float edge = 1.0 - smoothstep(
            end_stars_edge_fade * 3.0 * end_stars_reach_sigma,
            3.0 * end_stars_reach_sigma,
            dist
        );

        stars = max(
            stars,
            color * (brightness * twinkle * edge * (exp(-0.5 * sqr(dist / sigma)) + glow))
        );
    }
    }
    }

    return stars;
}

// One drifting layer, looked up along dir with the lensing arc (world space).
// The arc direction is not drifted: the drift is at most 1.5 degrees.
vec3 end_stars_drifting_layer(
    vec3 dir,
    vec3 tangent,
    float arc,
    vec3 drift_axis,
    float drift_cycles,
    float drift_phase,
    mat3 rotation,
    float cells,
    float hash_offset,
    float occupancy,
    float pixel,
    float gain,
    float time
) {
    float drift = end_stars_drift_amplitude
        * sin(time * (drift_cycles * (tau / 3600.0)) + drift_phase);

    return end_stars_layer(
        rotation * end_stars_rotate(dir, drift_axis, drift),
        rotation * tangent,
        arc,
        cells,
        hash_offset,
        occupancy,
        pixel,
        gain,
        time,
        end_stars_standout_share.x,
        vec4(0.0)
    );
}

#if defined SKY_BLACK_HOLE
// (include/sky/end_black_hole.glsl, included after this file)
float bh_impact(vec3 ray_dir);
#endif

// Enhanced Star Field.
//   dir:        direction to look the stars up in (the lensed direction)
//   pixel:      angular size of this pixel, in radians
//   tangent, arc, gain: lensing arc and brightening (bh_star_lens), or
//               (any unit vector, 0, 1) without a black hole
//   hole_dir:   direction of the black hole
//   hole_distance: how far the view ray passes from the black hole
//               (bh_impact(), local units); very large without a black hole
//   time:       frameTimeCounter
vec3 end_stars(
    vec3 dir,
    float pixel,
    vec3 tangent,
    float arc,
    float gain,
    vec3 hole_dir,
    float hole_distance,
    float time
) {
    float occupancy = clamp(end_stars_occupancy * STARS_COVERAGE * 2.0, 0.0, 0.9);

    vec3 stars = end_stars_drifting_layer(
        dir, tangent, arc,
        end_stars_drift_axis_0, end_stars_drift_cycles_0, 0.0,
        end_stars_rotation_0, end_stars_cells_0, 0.0,
        occupancy, pixel, gain, time
    );
    stars = max(stars, end_stars_drifting_layer(
        dir, tangent, arc,
        end_stars_drift_axis_1, end_stars_drift_cycles_1, 1.7,
        end_stars_rotation_1, end_stars_cells_1, 71.3,
        occupancy, pixel, gain, time
    ));
    stars = max(stars, end_stars_drifting_layer(
        dir, tangent, arc,
        end_stars_drift_axis_2, end_stars_drift_cycles_2, 3.4,
        end_stars_rotation_2, end_stars_cells_2, 157.9,
        occupancy, pixel, gain, time
    ));

    // Pulled stars (see the header): only around the black hole
    float pull_weight = 1.0 - smoothstep(
        end_stars_pulled_reach_inner,
        end_stars_pulled_reach_outer,
        hole_distance
    );
    if (pull_weight > 0.001) {
        stars *= 1.0 - (1.0 - end_stars_pulled_still) * pull_weight;
        float pulled_occupancy
            = clamp(end_stars_pulled_occupancy * STARS_COVERAGE * 2.0, 0.0, 0.9);
        float orbit = 1.5 / max(hole_distance, 1.5);
        float speed = end_stars_pulled_speed * float(END_BLACK_HOLE_SPEED) * end_sky_pull_turn * orbit * sqrt(orbit);
        // Falling in (v0.7.2): looking the stars up farther from the black
        // hole's axis as time passes moves their images towards it (inside the
        // Einstein ring, towards the ring: both images of a source nearing the
        // axis converge on it, as with a real lens)
        // v0.7.2.1: faster the closer they are (end_sky_infall_from()), so
        // they are seen streaming in and speeding up, and those that reach
        // the axis are gone (swallowed, on the ring)
        vec3 infall_axis = cross(hole_dir, dir);
        float infall_axis_length = length(infall_axis);
        infall_axis /= max(infall_axis_length, 1e-4);
#if defined SKY_BLACK_HOLE
        // (the black hole's units per radian, from its own measure: the
        // direction opposite to it is pi radians away)
        float hole_scale = bh_impact(-hole_dir) * (1.0 / 3.14159265);
        float source_units = bh_impact(dir);
#else
        const float hole_scale = 4.57;
        float source_units = hole_scale * acos(clamp(dot(dir, hole_dir), -1.0, 1.0));
#endif

        for (int cycle_phase = 0; cycle_phase < 2; ++cycle_phase) {
            float t = time + float(cycle_phase) * (0.5 * end_stars_pulled_period);
            float tau_cycle = mod(t, end_stars_pulled_period);
            float cycle = mod(floor(t / end_stars_pulled_period), end_stars_pulled_cycles);
            // Fades in, moves, fades out: the two cycles always sum to 1
            float fade = 1.0 - abs(2.0 * tau_cycle / end_stars_pulled_period - 1.0);
            float angle = speed * (tau_cycle - 0.5 * end_stars_pulled_period);

            float from = end_sky_infall_from(source_units, end_sky_pull_speed * (tau_cycle - 0.5 * end_stars_pulled_period));
            fade *= smoothstep(0.0, 1.0, from);
            float outwards = (pow(max(from, 0.0), 1.0 / 3.0) - source_units) / hole_scale;
            vec3 pulled_dir = end_stars_rotate(end_stars_rotate(dir, infall_axis, outwards), hole_dir, angle);
            vec3 pulled_tangent = end_stars_rotate(end_stars_rotate(tangent, infall_axis, outwards), hole_dir, angle);

            stars = max(stars, end_stars_layer(
                end_stars_rotation_0 * pulled_dir,
                end_stars_rotation_0 * pulled_tangent,
                arc,
                end_stars_cells_0,
                301.7 + 97.3 * float(cycle_phase) + 37.13 * cycle,
                pulled_occupancy,
                pixel,
                gain,
                time,
                end_stars_standout_share.x,
                vec4(0.0)
            ) * (fade * pull_weight));
        }
    }

    return stars * STARS_INTENSITY;
}

// The heart's cluster (v0.7.1.6): its stars are among the nebula's heart,
// in front of its lit cavity wall, so sky.glsl adds them after the nebula's
// far part, not veiled by it (like the intermediate stars). Looked up along
// the lensed direction with the lensing arc, like the distant stars
vec3 end_stars_cluster_stars(vec3 dir, float pixel, vec3 tangent, float arc, float gain, float time) {
    vec3 cluster_dir = normalize(end_sky_cluster_position());
    if (dot(dir, cluster_dir) < cos(3.0 * end_stars_cluster.x)) return vec3(0.0);
    float occupancy = clamp(end_stars_cluster.z * STARS_COVERAGE * 2.0, 0.0, 0.9);
    return end_stars_layer(
        end_stars_rotation_5 * dir,
        end_stars_rotation_5 * tangent,
        arc,
        end_stars_cluster.y,
        433.1,
        occupancy,
        pixel,
        gain,
        time,
        0.0,
        vec4(end_stars_rotation_5 * cluster_dir, end_stars_cluster.x)
    ) * STARS_INTENSITY;
}

// A population of stars at a real distance (v0.6.8): found on a sphere of
// radius blocks round the island, from the observer, like the nebula's
// layers, so it shows true parallax. Kept clear round the black hole.
//   ray_dir: view direction (not lensed: these stars are in front of it)
//   layer:   radius, cells per radian, occupancy (end_stars_*_layer)
vec3 end_stars_at_distance(
    vec3 ray_dir,
    vec3 observer,
    vec3 layer,
    mat3 rotation,
    float hash_offset,
    float standout_share,
    float gain,
    vec3 hole_dir,
    bool has_hole,
    float pixel,
    float time
) {
    float clear = has_hole
        ? smoothstep(end_stars_depth_clear.x, end_stars_depth_clear.y,
            acos(clamp(dot(ray_dir, hole_dir), -1.0, 1.0)))
        : 1.0;
    if (clear < 1e-3) return vec3(0.0);

    // Where the ray leaves the sphere (the observer kept inside 0.8 of it)
    vec3 camera = (observer - end_stars_center) / layer.x;
    camera *= min(1.0, 0.8 / max(length(camera), 1e-6));
    float b = dot(camera, ray_dir);
    float t = -b + sqrt(max(b * b - dot(camera, camera) + 1.0, 0.0));
    vec3 point = camera + ray_dir * t;

    // A pixel there, seen from the sphere's centre (the stars' cells are on
    // the sphere): its angular size scaled by distance / radius
    float occupancy = clamp(layer.z * STARS_COVERAGE * 2.0, 0.0, 0.9);
    return end_stars_layer(
        rotation * point,
        rotation * vec3(0.0, 1.0, 0.0),
        0.0,
        layer.y,
        hash_offset,
        occupancy,
        pixel * t,
        gain,
        time,
        standout_share,
        vec4(0.0)
    ) * (clear * STARS_INTENSITY);
}

vec3 end_stars_middle(vec3 ray_dir, vec3 observer, vec3 hole_dir, bool has_hole, float pixel, float time) {
    return end_stars_at_distance(
        ray_dir, observer, end_stars_middle_layer, end_stars_rotation_3, 503.3,
        end_stars_standout_share.y, end_stars_depth_gain.x, hole_dir, has_hole, pixel, time
    );
}

vec3 end_stars_near(vec3 ray_dir, vec3 observer, vec3 hole_dir, bool has_hole, float pixel, float time) {
    return end_stars_at_distance(
        ray_dir, observer, end_stars_near_layer, end_stars_rotation_4, 611.9,
        end_stars_standout_share.z, end_stars_depth_gain.y, hole_dir, has_hole, pixel, time
    );
}

#endif // CONCEPT_END_STARS

#endif // INCLUDE_SKY_END_STARS
