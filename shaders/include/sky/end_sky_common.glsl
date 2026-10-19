#if !defined INCLUDE_SKY_END_SKY_COMMON
#define INCLUDE_SKY_END_SKY_COMMON

#include "/include/utility/fast_math.glsl"
#include "/include/utility/random.glsl"

/*
--------------------------------------------------------------------------------

  include/sky/end_sky_common:
  Helpers shared by the End sky's optional objects (the black hole, the
  planet, the nebula and the star field).

  These used to live in end_black_hole.glsl, which meant the planet had to
  include - and therefore depend on - the black hole to be drawn at all.
  They are the same helpers, moved here so each object can be compiled and
  drawn on its own.

--------------------------------------------------------------------------------
*/

// Direction in the sky (world space, y up) from a compass direction and an
// elevation in degrees: azimuth 0 = north, 90 = east, 180 = south, 270 = west
vec3 end_sky_direction(float azimuth_degrees, float elevation_degrees) {
    float azimuth = radians(azimuth_degrees);
    float elevation = radians(elevation_degrees);

    return vec3(
        sin(azimuth) * cos(elevation),
        sin(elevation),
        -cos(azimuth) * cos(elevation)
    );
}

// Screen-aligned basis around a direction: `up` points towards the zenith as
// seen from that direction
void end_sky_basis(vec3 dir, out vec3 up, out vec3 right) {
    vec3 world_up = abs(dir.y) > 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    up = normalize(world_up - dir * dot(world_up, dir));
    right = cross(up, dir);
}

// Cheap analytic 3D value noise (trilinearly-interpolated hash)
float end_sky_value_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n00 = mix(hash1(i + vec3(0.0, 0.0, 0.0)), hash1(i + vec3(1.0, 0.0, 0.0)), f.x);
    float n10 = mix(hash1(i + vec3(0.0, 1.0, 0.0)), hash1(i + vec3(1.0, 1.0, 0.0)), f.x);
    float n01 = mix(hash1(i + vec3(0.0, 0.0, 1.0)), hash1(i + vec3(1.0, 0.0, 1.0)), f.x);
    float n11 = mix(hash1(i + vec3(0.0, 1.0, 1.0)), hash1(i + vec3(1.0, 1.0, 1.0)), f.x);

    return mix(mix(n00, n10, f.y), mix(n01, n11, f.y), f.z);
}

float end_sky_fbm(vec3 position, vec3 shift) {
    const int oct = 4;
    const float gain = 0.87;
    const float scale = 2.5;
    const float oct_shift = (gain / scale) * 0.25;

    float accum = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < oct; ++i) {
        accum += amplitude * end_sky_value_noise(position);
        position = (position + shift) * scale;
        amplitude *= gain;
    }

    return accum + oct_shift;
}

// The nebula's heart and the young cluster lighting it (v0.7.1.6), shared by
// the nebula and the star field (the cluster's stars): the heart is placed
// relative to the black hole's options (degrees of azimuth and elevation
// away from it), at a distance (blocks from the island); the cluster is
// offset from the heart's centre in the heart's frame (blocks: right, up,
// towards the island = negative)
const vec2 end_sky_heart_offset = vec2(-48.0, 12.0);
const float end_sky_heart_distance = 10000.0;
const vec3 end_sky_cluster_offset = vec3(840.0, -2240.0, -600.0);

vec3 end_sky_heart_direction() {
    return end_sky_direction(
        float(END_BLACK_HOLE_AZIMUTH) + end_sky_heart_offset.x,
        clamp(float(END_BLACK_HOLE_ELEVATION) + end_sky_heart_offset.y, -20.0, 70.0)
    );
}

// A frame facing a direction: x right, y up, z = the direction
mat3 end_sky_facing(vec3 c) {
    vec3 right = normalize(cross(c, vec3(0.0, 1.0, 0.0)));
    return mat3(right, cross(right, c), c);
}

// The cluster, relative to the island (blocks)
vec3 end_sky_cluster_position() {
    vec3 heart = end_sky_heart_direction();
    return heart * end_sky_heart_distance + end_sky_facing(heart) * end_sky_cluster_offset;
}

// The black hole's pull (v0.7.2), shared by the star field and the nebula so
// that both fall towards it at the same angular rate: radians per second at a
// distance from its line of sight (in black hole units; its shadow's edge is
// at ~1.1): pull.x at pull.y units, falling off with the distance, gone
// between reach.x and reach.y. Follows the black hole's Animation Speed
const vec2 end_sky_pull = vec2(0.016, 1.5);
const vec2 end_sky_pull_reach = vec2(8.0, 12.0);

// v0.7.2.3, option Pull Speed (Off / Slow / Normal / Fast): how fast
// everything the black hole pulls falls in, without changing its disc's
// animation or the nebula's own motion (speed), and how fast the stars round
// it circle it (turn: as before the pull when it is off)
#if END_BLACK_HOLE_PULL == 1
const float end_sky_pull_speed = 0.5;
const float end_sky_pull_turn = 0.5;
#elif END_BLACK_HOLE_PULL == 2
const float end_sky_pull_speed = 1.0;
const float end_sky_pull_turn = 1.0;
#elif END_BLACK_HOLE_PULL == 3
const float end_sky_pull_speed = 2.0;
const float end_sky_pull_turn = 2.0;
#else
const float end_sky_pull_speed = 0.0;
const float end_sky_pull_turn = 1.0;
#endif

float end_sky_pull_rate(float units) {
    return (float(END_BLACK_HOLE_SPEED) * end_sky_pull_speed * end_sky_pull.x * end_sky_pull.y) / max(units, end_sky_pull.y)
        * (1.0 - smoothstep(end_sky_pull_reach.x, end_sky_pull_reach.y, units));
}

// v0.7.2.1: falling in, for what is seen being swallowed (the stars round the
// black hole, the nebula's far gas): it falls at end_sky_infall / distance^2
// units per second, much faster the closer it is (the cube of its distance
// shrinks steadily), so it is seen speeding up as it goes in. Where to look
// for what is seen at `units` from the black hole's axis, `seconds` later:
// the cube of that distance (below 0: nothing gets there, it would have come
// from beyond the axis). Follows the black hole's Animation Speed; the
// callers apply Pull Speed (the stars to `seconds`, the nebula to how fast
// its cycle runs)
const float end_sky_infall = 0.60;

float end_sky_infall_from(float units, float seconds) {
    return units * units * units + (3.0 * end_sky_infall * float(END_BLACK_HOLE_SPEED)) * seconds;
}

// Colour options (v0.7.6, v0.7.7): the nebula's and the black hole's light,
// red, green and blue in rec709 (1: unchanged; screens Nebula Colour and Black
// Hole Colour)
const vec3 end_sky_nebula_tint = vec3(END_NEBULA_TINT_R, END_NEBULA_TINT_G, END_NEBULA_TINT_B);
// (v0.7.8: the Nebula Sea's own, in place of the nebula's - screen Sea Colour)
const vec3 end_sky_sea_tint = vec3(END_NEBULA_SEA_TINT_R, END_NEBULA_SEA_TINT_G, END_NEBULA_SEA_TINT_B);
const vec3 end_sky_hole_tint = vec3(END_BLACK_HOLE_TINT_R, END_BLACK_HOLE_TINT_G, END_BLACK_HOLE_TINT_B);

#endif // INCLUDE_SKY_END_SKY_COMMON
