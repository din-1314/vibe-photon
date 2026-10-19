#if !defined INCLUDE_MISC_END_PORTAL_CONCEPT
#define INCLUDE_MISC_END_PORTAL_CONCEPT

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.8.5)

  include/misc/end_portal_concept:
  The End portal (and the End gateway), Minecraft's own look in our End's
  colours (option Cinematic End Portal).

  Minecraft's portal is a near-black base under many layers of small square
  specks, each layer turned, scaled and drifting its own way, the colours
  brighter in the later layers, the deepest layer the End sky's cloudy
  texture. All of that is kept: the specks are on the block's own texel grid
  (16 per block), the layers turn and drift, the deepest one is a faint
  cloud. Changed: the colours are our End's (near-black, the nebula's brown,
  deep blue, orange, amber and steel blue, the black hole disc's warm white),
  and the layers sit at real depths under the surface (0.06 to 2.9 blocks),
  so they move against each other as the camera moves (parallax), the deeper
  ones fainter. The specks twinkle, a few near the top flare now and then
  (Photon's bloom turns the flares into glints), and the whole portal
  "breathes" slowly (7 s).

  Every portal block is drawn the same way from its world position: there is
  no centre (a stronghold portal's centre cannot be known by the shader).
  The colour is returned as an albedo (sRGB, 0-1): the portal is emissive
  (material mask 63, emission 1, x40 in the deferred shading).

--------------------------------------------------------------------------------
*/

#include "/include/utility/color.glsl"

const int end_portal_layers = 14;
const float end_portal_layer_gap = 0.22; // blocks between layers
const float end_portal_first = 0.06;     // the first layer under the surface
const float end_portal_texels = 16.0;    // specks per block (Minecraft's texel)

// The layers' colours (sRGB, as Minecraft's list: dim first, brighter later)
const vec3 end_portal_colors[16] = vec3[16](
    vec3(0.030, 0.026, 0.034), vec3(0.060, 0.040, 0.030), vec3(0.040, 0.060, 0.090), vec3(0.090, 0.055, 0.030),
    vec3(0.060, 0.085, 0.120), vec3(0.140, 0.080, 0.035), vec3(0.090, 0.130, 0.180), vec3(0.200, 0.110, 0.045),
    vec3(0.130, 0.180, 0.240), vec3(0.290, 0.160, 0.060), vec3(0.160, 0.240, 0.330), vec3(0.380, 0.220, 0.080),
    vec3(0.220, 0.330, 0.420), vec3(0.480, 0.300, 0.120), vec3(0.330, 0.450, 0.560), vec3(0.620, 0.480, 0.330)
);

// Integer hash (own, so the pattern is the same on every driver)
uint end_portal_hash_u(uvec3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return v.x ^ v.y ^ v.z;
}

vec4 end_portal_hash4(ivec3 c) {
    uint h = end_portal_hash_u(uvec3(c + 32768));
    uvec4 k = uvec4(h, h * 747796405u + 2891336453u, h * 2654435761u + 1u, h * 1597334677u + 7u);
    k ^= k >> 15u;
    k *= 2246822519u;
    k ^= k >> 13u;
    return vec4(k & 0xffffu) / 65535.0;
}

float end_portal_noise(vec2 p) {
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = end_portal_hash4(ivec3(i, 900)).x;
    float b = end_portal_hash4(ivec3(i + ivec2(1, 0), 900)).x;
    float c = end_portal_hash4(ivec3(i + ivec2(0, 1), 900)).x;
    float d = end_portal_hash4(ivec3(i + ivec2(1, 1), 900)).x;
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// The deepest layer: faint clouds in the nebula's orange and blue, drifting
vec3 end_portal_clouds(vec2 uv, float time) {
    uv = uv * 0.55 + vec2(0.02 * time, 0.0);
    float n = 0.5 * end_portal_noise(uv)
        + 0.3 * end_portal_noise(uv * 2.1 + 5.3)
        + 0.2 * end_portal_noise(uv * 4.3 + 1.7);
    float tone = end_portal_noise(uv * 0.7 + 11.0);
    vec3 c = mix(vec3(0.55, 0.32, 0.16), vec3(0.22, 0.33, 0.48), smoothstep(0.35, 0.65, tone));
    return c * c * smoothstep(0.35, 0.85, n);
}

//   world_pos: the surface's world position
//   world_dir: the view direction
//   normal:    the face's normal (world space)
//   time:      frameTimeCounter
// Returns the albedo (sRGB) to store for the portal's surface.
vec3 end_portal_concept(vec3 world_pos, vec3 world_dir, vec3 normal, float time) {
    float cos_in = max(-dot(world_dir, normal), 0.05);
    vec3 t1 = normalize(cross(normal, abs(normal.y) > 0.5 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0)));
    vec3 t2 = cross(normal, t1);
    float breathe = 0.85 + 0.15 * sin(time * (6.2831853 / 7.0));

    // the base
    vec3 light = 0.25 * end_portal_colors[0] * end_portal_colors[0];
    float fade = 1.0;
    for (int i = 0; i < end_portal_layers; ++i) {
        float fi = float(i);
        float depth = end_portal_first + end_portal_layer_gap * fi;
        vec3 p = world_pos + world_dir * (depth / cos_in);
        vec2 uv = vec2(dot(p, t1), dot(p, t2));

        // turned, scaled and drifting its own way
        float angle = fi * fi * 4321.0 + fi * 9.0;
        mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
        float scale = 1.0 + 0.12 * mod(fi * 7.0, 5.0);
        uv = rot * uv * scale + vec2(17.0 * fi, 0.0)
            + vec2(0.0, 0.04 * time * (1.0 + 0.3 * mod(fi, 3.0)));

        // square specks on the texel grid, a few bigger 2x2 ones
        vec4 h = end_portal_hash4(ivec3(floor(uv * end_portal_texels), i));
        float speck = step(0.995, h.x);
        vec4 hb = end_portal_hash4(ivec3(floor(uv * end_portal_texels * 0.5), i + 64));
        speck = max(speck, step(0.9975, hb.x));

        float twinkle = 0.65 + 0.35 * sin(time * (1.0 + 2.0 * h.y) + h.z * 30.0);
        // a few specks near the top flare now and then (glints)
        if (i < 4 && h.w < 0.3) {
            twinkle += 5.0 * pow(max(sin(time * (0.35 + 0.5 * h.y) + h.z * 40.0), 0.0), 40.0);
        }

        vec3 c = end_portal_colors[min(i + 2, 15)];
        light += fade * (3.0 * c * c) * (speck * twinkle * breathe);
        fade *= 0.88;
    }

    // the clouds, under the last layer
    {
        float depth = end_portal_first + end_portal_layer_gap * float(end_portal_layers) + 0.3;
        vec3 p = world_pos + world_dir * (depth / cos_in);
        light += 0.04 * breathe * end_portal_clouds(vec2(dot(p, t1), dot(p, t2)), time);
    }
    // a faint haze, more of it deeper
    vec3 haze = mix(end_portal_colors[13], end_portal_colors[12], 0.5);
    light += (1.0 - fade) * 0.010 * haze * haze;

    // (preview units: x40 on screen; the albedo is stored in sRGB)
    return srgb_eotf(clamp01(light * 0.45));
}

#endif // INCLUDE_MISC_END_PORTAL_CONCEPT
