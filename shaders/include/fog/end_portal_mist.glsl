#if !defined INCLUDE_FOG_END_PORTAL_MIST
#define INCLUDE_FOG_END_PORTAL_MIST

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.8.6.2)

  include/fog/end_portal_mist:
  Mist and glints rising out of the End portal (option Portal Light and Mist,
  needs Colored Lights).

  The shader only sees the portal on its own surface (its blocks are block
  entities, which never reach Colored Lights' voxel map), so Colored Lights'
  floodfill finds it from its frame (include/lighting/lpv/floodfill.glsl): an
  empty voxel enclosed by frames with an eye is the portal. There it shines
  in its colour (its entry in include/lighting/lpv/light_colors.glsl: the
  room is lit, and glows in Colored Lights' fog), and it is flagged in the
  light volume's alpha, read here.

  Along the view ray (up to 24 blocks) a coarse walk looks for the first
  point over a portal (a few blocks straight down in the light volume); the
  mist is then marched finely over the 7 blocks of the ray round it, so its
  samples fall inside the mist (v0.8.6.2: one sample every 1.2 blocks over the
  whole ray left it grainy). The flag is read with the volume's linear
  filter: its edges fade out smoothly over the frame instead of in blocks.
  The mist: slow, rising, turning, in our End's colours (the nebula's orange
  and blue), thinning out about two blocks up. The glints: small sparks
  rising out of the portal and fading, in the black hole disc's warm white.

--------------------------------------------------------------------------------
*/

#include "/include/lighting/lpv/voxelization.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"

// (the light volume, as include/lighting/lpv/blocklight.glsl reads it; c0
// declares it already with Colored Lights Fog Scattering)
#ifndef LPV_VL
uniform sampler3D light_sampler_a;
uniform sampler3D light_sampler_b;
#endif

const float end_portal_mist_reach = 24.0;  // blocks from the camera
const int end_portal_mist_search = 24;     // coarse steps over the reach
const int end_portal_mist_steps = 16;      // fine steps round the portal
const float end_portal_mist_span = 7.0;    // blocks of ray marched finely
const float end_portal_mist_height = 2.2;  // e-folding height (blocks)
const float end_portal_mist_strength = 0.35 * END_PORTAL_MIST_INTENSITY * 0.01;
const float end_portal_glint_strength = 4.0 * END_PORTAL_MIST_INTENSITY * 0.01;
const vec3 end_portal_mist_warm = vec3(1.00, 0.55, 0.25) * rec709_to_working_color;
const vec3 end_portal_mist_cool = vec3(0.35, 0.55, 1.00) * rec709_to_working_color;
const vec3 end_portal_glint_color = vec3(1.00, 0.72, 0.45) * rec709_to_working_color;

float end_portal_flag(vec3 sample_pos) {
    return (frameCounter & 1) == 0
        ? texture(light_sampler_a, sample_pos).a
        : texture(light_sampler_b, sample_pos).a;
}

// Over a portal: x = height above its surface (blocks), y = how much over it
// (0-1, soft at its edges); x = -1 if no portal within 5 blocks below
vec2 end_portal_below(vec3 world_pos) {
    vec3 voxel_pos = scene_to_voxel_space(world_pos - cameraPosition);
    float y = floor(voxel_pos.y);
    for (int k = 0; k < 5; ++k) {
        float layer = y - float(k);
        vec3 sample_pos = vec3(voxel_pos.x, layer + 0.5, voxel_pos.z) / vec3(voxel_volume_size);
        if (clamp01(sample_pos) != sample_pos) return vec2(-1.0, 0.0);
        float flag = end_portal_flag(sample_pos);
        if (flag > 0.05) return vec2(voxel_pos.y - (layer + 0.75), flag);
    }
    return vec2(-1.0, 0.0);
}

uint end_portal_mist_hash_u(uvec3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return v.x ^ v.y ^ v.z;
}

vec4 end_portal_mist_hash4(ivec3 c) {
    uint h = end_portal_mist_hash_u(uvec3(c + 32768));
    uvec4 k = uvec4(h, h * 747796405u + 2891336453u, h * 2654435761u + 1u, h * 1597334677u + 7u);
    k ^= k >> 15u;
    k *= 2246822519u;
    k ^= k >> 13u;
    return vec4(k & 0xffffu) / 65535.0;
}

float end_portal_mist_noise(vec3 p) {
    ivec3 i = ivec3(floor(p));
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = end_portal_mist_hash4(i).x, b = end_portal_mist_hash4(i + ivec3(1, 0, 0)).x;
    float c = end_portal_mist_hash4(i + ivec3(0, 1, 0)).x, d = end_portal_mist_hash4(i + ivec3(1, 1, 0)).x;
    float e = end_portal_mist_hash4(i + ivec3(0, 0, 1)).x, g = end_portal_mist_hash4(i + ivec3(1, 0, 1)).x;
    float h = end_portal_mist_hash4(i + ivec3(0, 1, 1)).x, k = end_portal_mist_hash4(i + ivec3(1, 1, 1)).x;
    return mix(mix(mix(a, b, f.x), mix(c, d, f.x), f.y), mix(mix(e, g, f.x), mix(h, k, f.x), f.y), f.z);
}

// The glints: sparks in a grid of cells moving up (0.6 blocks each), one in
// some cells; only those over a portal, low above it, are seen
vec3 end_portal_glints(vec3 origin, vec3 dir, float reach, float time) {
    const float cell = 0.6;
    const float rise = 0.55; // blocks per second
    float lift = time * rise / cell;
    vec3 g = origin / cell - vec3(0.0, lift, 0.0);
    ivec3 c = ivec3(floor(g));
    vec3 inv = 1.0 / max(abs(dir), vec3(1e-4));
    ivec3 stp = ivec3(sign(dir));
    vec3 side = (vec3(stp) * (vec3(c) - g) + max(vec3(stp), 0.0)) * inv;
    float limit = reach / cell;
    vec3 light = vec3(0.0);
    for (int i = 0; i < 32; ++i) {
        vec4 h = end_portal_mist_hash4(c + ivec3(0, 0, 7919));
        if (h.w < 0.12) {
            vec3 m = (vec3(c) + 0.3 + 0.4 * h.xyz + vec3(0.0, lift, 0.0)) * cell;
            vec2 below = end_portal_below(m);
            if (below.x > 0.0 && below.x < 3.5 && below.y > 0.5) {
                vec3 om = m - origin;
                float along = dot(om, dir);
                float off2 = max(dot(om, om) - along * along, 0.0);
                // small: about a pixel or two (with the bloom round it)
                float r = 0.012 + 0.0012 * max(along, 0.0);
                float fade = smoothstep(0.0, 0.3, below.x) * (1.0 - smoothstep(1.5, 3.5, below.x));
                float flicker = 0.6 + 0.4 * sin(time * (3.0 + 4.0 * h.z) + h.x * 20.0);
                light += step(0.0, along) * fade * flicker
                    * (exp(-off2 / (r * r)) + 0.06 * exp(-off2 / (6.0 * r * r)));
            }
        }
        float next = min(side.x, min(side.y, side.z));
        if (next > limit) break;
        if (side.x <= side.y && side.x <= side.z) { side.x += inv.x; c.x += stp.x; }
        else if (side.y <= side.z) { side.y += inv.y; c.y += stp.y; }
        else { side.z += inv.z; c.z += stp.z; }
    }
    return end_portal_glint_color * light;
}

// The light of the mist and glints along the view ray (added to the fog's
// scattering)
vec3 end_portal_mist(vec3 world_start_pos, vec3 world_end_pos, float dither) {
    vec3 dir;
    float ray_length;
    length_normalize(world_end_pos - world_start_pos, dir, ray_length);
    ray_length = min(ray_length, end_portal_mist_reach);

    // Coarse: the first point of the ray over a portal
    float search_step = ray_length / float(end_portal_mist_search);
    float hit = -1.0;
    for (int i = 0; i < end_portal_mist_search; ++i) {
        float t = (float(i) + dither) * search_step;
        vec2 below = end_portal_below(world_start_pos + dir * t);
        if (below.x > -0.5 && below.x < 4.5) {
            hit = t;
            break;
        }
    }
    if (hit < 0.0) return vec3(0.0);

    // Fine: the stretch of the ray round it
    float t0 = max(hit - search_step - 1.0, 0.0);
    float t1 = min(t0 + end_portal_mist_span, ray_length);
    float step_length = (t1 - t0) / float(end_portal_mist_steps);

    float time = frameTimeCounter;
    float breathe = 0.85 + 0.15 * sin(time * (6.2831853 / 7.0)); // as the portal

    vec3 light = vec3(0.0);
    float transmittance = 1.0;
    for (int i = 0; i < end_portal_mist_steps; ++i) {
        vec3 p = world_start_pos + dir * (t0 + (float(i) + dither) * step_length);
        vec2 below = end_portal_below(p);
        if (below.x <= 0.0) continue;

        // rising, turning wisps
        vec3 q = p * 1.1 - vec3(0.0, 0.45 * time, 0.0);
        q.xz += 0.8 * vec2(end_portal_mist_noise(q * 0.6 + 3.1), end_portal_mist_noise(q * 0.6 + 8.7)) - 0.4;
        float n = 0.65 * end_portal_mist_noise(q) + 0.35 * end_portal_mist_noise(q * 2.3 + 5.0);
        float density = smoothstep(0.30, 0.75, n)
            * exp(-below.x / end_portal_mist_height * 1.6)
            * smoothstep(0.0, 0.25, below.x)
            * smoothstep(0.15, 0.75, below.y);

        vec3 color = mix(end_portal_mist_warm, end_portal_mist_cool,
            smoothstep(0.4, 0.7, end_portal_mist_noise(q * 0.4 + 13.0)));
        light += transmittance * color * (density * step_length * end_portal_mist_strength * breathe);
        transmittance *= exp(-0.4 * density * step_length);
    }

    light += end_portal_glint_strength * breathe
        * end_portal_glints(world_start_pos + dir * t0, dir, t1 - t0, time);
    return light;
}

#endif // INCLUDE_FOG_END_PORTAL_MIST
