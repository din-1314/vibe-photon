#if !defined INCLUDE_SKY_OVERWORLD_MILKY_WAY
#define INCLUDE_SKY_OVERWORLD_MILKY_WAY

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.9.4)

  include/sky/overworld_milky_way:
  The Milky Way of the Overworld's night sky in our End's nebula colours
  (option Milky Way, its Intensity).

  A faint band across the sky along a great circle fixed among the stars (it
  turns with them), brightest and widest at its core - a warm amber bulge -
  bluer towards its ends, mottled by star clouds and split by a dark dust
  lane. Built from a few octaves of value noise on the direction: no texture,
  no march, a handful of arithmetic per sky pixel. Seen through the
  atmosphere like the stars, so it shows only at night, and is hidden by the
  moon's glow, the clouds and the rain.

--------------------------------------------------------------------------------
*/

#include "/include/utility/color.glsl"

// The band's plane (celestial frame) and where its core is along it
const vec3 milky_way_normal = vec3(0.36, 0.30, 0.88) / length(vec3(0.36, 0.30, 0.88));
const vec3 milky_way_core = vec3(0.92, -0.10, -0.34) / length(vec3(0.92, -0.10, -0.34));
const float milky_way_brightness = 0.50 * float(MILKY_WAY_INTENSITY) * 0.01; // (v0.9.7: 100 % = v0.9.5's 200 %)

const vec3 milky_way_warm = vec3(1.00, 0.90, 0.78) * rec709_to_working_color; // (v0.9.8: a neutral warm white, not orange)
const vec3 milky_way_cool = vec3(0.50, 0.66, 1.00) * rec709_to_working_color;

float milky_way_hash(vec3 p) {
    uvec3 v = uvec3(ivec3(floor(p)) + 32768);
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return float((v.x ^ v.y ^ v.z) & 0xffffu) / 65535.0;
}

float milky_way_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(milky_way_hash(i), milky_way_hash(i + vec3(1, 0, 0)), f.x),
            mix(milky_way_hash(i + vec3(0, 1, 0)), milky_way_hash(i + vec3(1, 1, 0)), f.x), f.y),
        mix(mix(milky_way_hash(i + vec3(0, 0, 1)), milky_way_hash(i + vec3(1, 0, 1)), f.x),
            mix(milky_way_hash(i + vec3(0, 1, 1)), milky_way_hash(i + vec3(1, 1, 1)), f.x), f.y),
        f.z
    );
}

float milky_way_fbm(vec3 p) {
    return 0.5 * milky_way_noise(p)
        + 0.3 * milky_way_noise(p * 2.03 + 7.1)
        + 0.2 * milky_way_noise(p * 4.07 + 3.3);
}

// The Milky Way's light along a direction in the celestial frame
// (v0.9.7: grander - a band about twice as wide, a big glowing bulge round
// its core, star clouds and dust on a larger scale)
vec3 draw_milky_way(vec3 dir) {
    float lat = dot(dir, milky_way_normal);                   // ~ angle off the band
    float along = dot(dir, milky_way_core);                     // 1 at the core
    float core = smoothstep(-0.2, 1.0, along);                  // the bulge's side

    // Width: a wide band with soft wings, swelling into the bulge
    float width = mix(0.16, 0.40, core * core);
    float band = 0.7 * exp(-sqr(lat / width)) + 0.3 * exp(-abs(lat) / (1.5 * width));
    // The bulge: a big round glow round the core, above and below the band
    float bulge = exp(-sqr(acos(clamp(along, -1.0, 1.0)) / 0.45))
        * exp(-sqr(lat / 0.55));
    if (band + bulge < 2e-4) return vec3(0.0);

    // Star clouds: large patches with gaps; a fine grain of unresolved stars
    float clouds = milky_way_fbm(dir * 3.2 + 1.3);
    float patches = smoothstep(0.28, 0.75, clouds);
    float fine = milky_way_noise(dir * 30.0);

    // Dust: a wide, broken rift down the middle, and darker knots off it
    float rift_wave = 0.06 * (milky_way_fbm(dir * 2.2 + 9.0) - 0.5) + 0.03 * sin(4.0 * along);
    float rift = exp(-sqr((lat - rift_wave) / mix(0.05, 0.12, core)))
        * smoothstep(0.28, 0.58, milky_way_fbm(dir * 4.0 + 5.0));
    float knots = smoothstep(0.58, 0.85, milky_way_fbm(dir * 8.0 + 2.0));
    float dust = 0.8 * clamp01(0.85 * rift + 0.4 * knots); // (never fully black)

    float light = (band * (0.15 + 1.6 * patches * patches + 0.25 * fine)
            + 0.75 * bulge * (0.6 + 0.6 * clouds)) // (v0.9.8: 1.2 lit the clouds like a dawn)
        * (0.45 + 1.1 * core * core)
        * (1.0 - dust);

    // Warm amber at the core, bluer out along the band, varying with the clouds
    vec3 color = mix(
        milky_way_cool,
        milky_way_warm,
        clamp01(1.3 * core + 0.6 * (clouds - 0.5))
    );
    return milky_way_brightness * light * color;
}

#endif // INCLUDE_SKY_OVERWORLD_MILKY_WAY
