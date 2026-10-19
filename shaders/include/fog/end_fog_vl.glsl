#if !defined INCLUDE_FOG_END_FOG_VL
#define INCLUDE_FOG_END_FOG_VL

#include "/include/lighting/end_black_hole_light.glsl"
#include "/include/lighting/shadows/distortion.glsl"
#include "/include/sky/end_void.glsl"
#include "/include/utility/color.glsl"
#include "/include/utility/fast_math.glsl"
#include "/include/utility/phase_functions.glsl"

// Light scattered by the fog in Photon Original. With Environmental Light on,
// the fog follows the black hole's direction and shadow map but keeps the
// End sun's colour and strength it had before (Photon Original's warm fog;
// the black hole's much stronger light would blow it out to white). The fog's
// full integration with the black hole comes in a later version.
#if defined CONCEPT_BH_LIGHT
// (dimmed with the black hole's light when the planet eclipses it: the ratio
// of this frame's light colour to the black hole's full light)
#define end_fog_light_color \
    (from_srgb(vec3(END_LIGHT_R, END_LIGHT_G, END_LIGHT_B)) * END_LIGHT_I \
        * (dot(light_color, luminance_weights_rec2020) \
            / max(dot(concept_bh_light_color(), luminance_weights_rec2020), 1e-6)))
#else
#define end_fog_light_color light_color
#endif

// Photon Original with the nebula (v0.6.8.1, v0.6.8.1.1): the black hole's
// dark surround over the fog's light. The nebula darkens the purple sky and
// gas round the black hole (include/sky/end_nebula.glsl,
// end_nebula_black_hole_surround()) so its disc stands out, but this fog is
// drawn later, over the sky, and its purple in-scattering added about as much
// purple there as the darkened sky had left (and, with Environmental Light,
// its forward-scattering lobe of the black hole's light glowed right round
// it; Photon's own End sun sits near the zenith). So the light it scatters
// (the black hole's or sun's, and the ambient purple) gets the same surround,
// with the same shape and size (the black hole's units, as bh_impact(), so it
// follows its Size option), in every view direction, over the sky and the
// terrain alike: one dark region round the black hole whichever layer the
// purple came from, anchored to its direction, not to the screen. The End
// glow and the fog's transmittance are untouched. Nebula off, Environmental
// Light off and Cinematic Void: unchanged.
#if defined CONCEPT_BH_LIGHT && !defined CONCEPT_CINEMATIC_VOID
#ifdef END_NEBULA
#define END_FOG_BH_SURROUND
// BH_CAMERA_DISTANCE / (Size^BH_SIZE_EXPONENT * BH_PRESENCE), at least
// BH_MIN_CAMERA_DISTANCE (include/sky/end_black_hole.glsl)
const float end_fog_bh_camera_distance = max(
    8.0 / (pow(max(END_BLACK_HOLE_SIZE, 0.05), 0.8) * 1.75),
    2.0
);
const vec3 end_fog_bh_surround_look = vec3(1.0, 3.0, 9.0); // as end_nebula_black_hole_surround_look (v0.7.0: black round the disc)
#endif
#endif

// The black hole's light rays (Photon Cinematic Concept v0.8.1, options Black
// Hole Rays and Intensity): a thin haze in the air round the main island, from
// the ground up to above the pillars' tops, lit by the black hole and shadowed
// by everything in its shadow map - the pillars above all: its light comes
// through between them in beams, brightest looking towards it (the haze
// scatters forwards). Needs Environmental Light (the black hole's shadows).
// Plain #ifdef for the option: Iris only lists a boolean option in the menu
// when it is tested with #ifdef
#if defined CONCEPT_BH_LIGHT
#ifdef END_BLACK_HOLE_RAYS
#define END_FOG_BH_RAYS
#endif
#endif

#if defined END_FOG_BH_RAYS
// The haze: how much light it scatters per block (at Intensity 100%), how
// forward its scattering is, and where it is (blocks: heights from, full,
// full, to; distance from the island's middle, full to none)
// (v0.8.2: 100% is what was 200%, the developer's choice in game)
const float end_rays_scattering = 8.0e-4 * float(END_BLACK_HOLE_RAYS_INTENSITY) * 0.01;
const float end_rays_forward = 0.6;
const vec4 end_rays_heights = vec4(46.0, 62.0, 112.0, 150.0);
const vec2 end_rays_reach = vec2(110.0, 170.0);

float end_rays_density(vec3 world_pos) {
    return smoothstep(end_rays_heights.x, end_rays_heights.y, world_pos.y)
        * (1.0 - smoothstep(end_rays_heights.z, end_rays_heights.w, world_pos.y))
        * (1.0 - smoothstep(end_rays_reach.x, end_rays_reach.y, length(world_pos.xz)));
}
#endif

float end_fog_density(vec3 world_pos) {
    const float falloff_start = 64.0;
    const float falloff_half_life = 7.0;

    const float mul = -rcp(falloff_half_life);
    const float add = -mul * falloff_start;

    float density = exp2(min(world_pos.y * mul + add, 0.0));

    // fade away below the island
    density *= linear_step(0.0, 64.0, world_pos.y);

    return density;
}

vec3 end_fog_emission(vec3 world_pos) {
    const vec3 main_col
        = from_srgb(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B))
        * END_AMBIENT_I;
    const vec3 alt_col = 0.5 * vec3(0.25, 1.0, 0.5);
    const vec3 wind0 = vec3(1.0, 0.1, 0.5) * 0.01;
    const vec3 wind1 = vec3(-0.7, -0.1, -0.1) * 0.05;

    float base_noise
        = texture(colortex0, 0.02 * world_pos + wind0 * frameTimeCounter).x;
    float detail_nose
        = texture(colortex0, 0.04 * world_pos + wind1 * frameTimeCounter).x
            * 0.8
        - 0.4;
    float color_noise = texture(colortex0, 0.02 * world_pos + 0.2).x;

    float density = max0(linear_step(0.6, 0.9, base_noise) + detail_nose);
    float color_mix = linear_step(0.5, 0.7, color_noise);

    float view_dist = distance(world_pos, cameraPosition);
    float fade_near = 1.0 - exp2(-0.1 * view_dist);
    float fade_far = exp2(-0.05 * view_dist);
    float fade_height = exp2(-0.05 * (max0(cameraPosition.y - 120.0)))
        * linear_step(0.0, 64.0, world_pos.y);

    return mix(main_col, alt_col, color_mix)
        * (density * fade_near * fade_far * fade_height);
}

mat2x3 raymarch_end_fog(
    vec3 world_start_pos,
    vec3 world_end_pos,
    bool sky,
    float dither
) {
    const uint min_step_count = 16;
    const uint max_step_count = 25;
    const float volume_top = 256.0;
    const float volume_bottom = 0.0;
    const float step_count_growth = 0.5;

    const vec3 end_color
        = from_srgb(vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B));
    const float density_scale = 0.01;
    const vec3 absorption_coeff = exp2(-end_color) * density_scale;
    const vec3 scattering_coeff = vec3(1.0) * density_scale;
    const vec3 extinction_coeff = absorption_coeff + scattering_coeff;

    const uint multiple_scattering_iterations = 4;

    vec3 world_dir = world_end_pos - world_start_pos;
    float ray_length;
    length_normalize(world_dir, world_dir, ray_length);

    float distance_to_lower_plane = (volume_bottom - eyeAltitude) / world_dir.y;
    float distance_to_upper_plane = (volume_top - eyeAltitude) / world_dir.y;
    float distance_to_volume_start, distance_to_volume_end;

    if (eyeAltitude < volume_bottom) {
        // Below volume
        distance_to_volume_start = distance_to_lower_plane;
        distance_to_volume_end
            = world_dir.y < 0.0 ? -1.0 : distance_to_upper_plane;
    } else if (eyeAltitude < volume_top) {
        // Inside volume
        distance_to_volume_start = 0.0;
        distance_to_volume_end = world_dir.y < 0.0
            ? distance_to_lower_plane
            : distance_to_upper_plane;
    } else {
        // Above volume
        distance_to_volume_start = distance_to_upper_plane;
        distance_to_volume_end
            = world_dir.y < 0.0 ? distance_to_upper_plane : -1.0;
    }

    if (distance_to_volume_end < 0.0) {
        return mat2x3(vec3(0.0), vec3(1.0));
    }

    ray_length = sky ? distance_to_volume_end : ray_length;
    ray_length = clamp(ray_length - distance_to_volume_start, 0.0, far);

    // Adjust step count based on ray length
    uint step_count
        = uint(float(min_step_count) + step_count_growth * ray_length);
    step_count = min(step_count, max_step_count);

    float step_length = ray_length * rcp(float(step_count));
    vec3 world_step = world_dir * step_length;

    // Jitter ray origin
    vec3 world_pos = world_start_pos
        + world_dir * (distance_to_volume_start + step_length * dither);

    // Space conversions

    vec3 shadow_pos = transform(shadowModelView, world_pos - cameraPosition);
    shadow_pos = project_ortho(shadowProjection, shadow_pos);

    vec3 shadow_step = mat3(shadowModelView) * world_step;
    shadow_step = diagonal(shadowProjection).xyz * shadow_step;

    // Calculations moved out of the loop

    float LoV = dot(world_dir, light_dir);

#if defined END_FOG_BH_SURROUND
    // How much of the fog's light is kept in this direction (see above)
    float bh_surround = 1.0 - end_fog_bh_surround_look.x * (1.0 - smoothstep(
        end_fog_bh_surround_look.y,
        end_fog_bh_surround_look.z,
        end_fog_bh_camera_distance * fast_acos(clamp(LoV, -1.0, 1.0))
    ));
#endif

    vec3 scattering = vec3(0.0);
    vec3 transmittance = vec3(1.0);
#if defined END_FOG_BH_RAYS
    float rays = 0.0; // (the haze's lit length along the ray, blocks)
#endif

    for (int i = 0; i < step_count;
         ++i, world_pos += world_step, shadow_pos += shadow_step) {
        vec3 shadow_screen_pos = distort_shadow_space(shadow_pos) * 0.5 + 0.5;

#ifdef SHADOW
        ivec2 shadow_texel = ivec2(
            shadow_screen_pos.xy * shadowMapResolution * MC_SHADOW_QUALITY
        );
        float depth0 = texelFetch(shadowtex0, shadow_texel, 0).x;
        float depth1 = texelFetch(shadowtex1, shadow_texel, 0).x;
        float shadow = step(
            float(clamp01(shadow_screen_pos) == shadow_screen_pos)
                * shadow_screen_pos.z,
            depth1
        );
#else
#define shadow 1.0
#endif

        float density = end_fog_density(world_pos) * step_length;

#if defined END_FOG_BH_RAYS
        // (seen through the fog in front of it)
        rays += end_rays_density(world_pos) * step_length * shadow
            * dot(transmittance, vec3(1.0 / 3.0));
#endif

        vec3 step_optical_depth = extinction_coeff * density;
        vec3 step_transmittance = exp(-step_optical_depth);
        vec3 step_transmitted_fraction
            = (1.0 - step_transmittance) / max(step_optical_depth, eps);

        vec3 visible_scattering = step_transmitted_fraction * transmittance;

        float anisotropy = 1.0;
        float scattering_amount = 1.0;
        for (uint i = 0u; i < multiple_scattering_iterations; ++i) {
            float mie_phase
                = 0.7 * henyey_greenstein_phase(LoV, 0.5 * anisotropy)
                + 0.3 * isotropic_phase;

            // Sunlight
#if defined CONCEPT_CINEMATIC_VOID
            // Cinematic Void: the unseen End sun's orange light is not
            // scattered (include/sky/end_void.glsl)
            scattering += density * light_color * mie_phase * shadow
                * visible_scattering * scattering_amount
                * end_void_fog_light_scale;
#elif defined END_FOG_BH_SURROUND
            scattering += density * end_fog_light_color * mie_phase * shadow
                * visible_scattering * scattering_amount * bh_surround;
#else
            scattering += density * end_fog_light_color * mie_phase * shadow
                * visible_scattering * scattering_amount;
#endif

            // Ambient light
#if defined CONCEPT_CINEMATIC_VOID
            // Cinematic Void: a faint cold haze instead of the purple ambient
            // glow (include/sky/end_void.glsl)
            scattering += density * end_void_fog_haze_color * isotropic_phase
                * visible_scattering * scattering_amount;
#elif defined END_FOG_BH_SURROUND
            scattering += density * ambient_color * isotropic_phase
                * visible_scattering * scattering_amount * bh_surround;
#else
            scattering += density * ambient_color * isotropic_phase
                * visible_scattering * scattering_amount;
#endif

            anisotropy *= 0.5;
            scattering_amount *= 0.5;
        }

#ifdef END_GLOW
        // Emission
#if defined CONCEPT_CINEMATIC_VOID
        // Cinematic Void: the End Glow becomes a faint cold trace, keeping
        // its shape but not its purple (include/sky/end_void.glsl)
        scattering += 4.0 * end_void_fog_glow_tint
            * dot(end_fog_emission(world_pos), luminance_weights)
            * step_length * transmittance * end_void_fog_glow_scale;
#else
        scattering
            += 4.0 * end_fog_emission(world_pos) * step_length * transmittance;
#endif
#endif

        transmittance *= step_transmittance;
    }

    scattering *= scattering_coeff;
    transmittance = pow(transmittance, vec3(0.75));

#if defined END_FOG_BH_RAYS
    // The black hole's light the haze scatters towards the camera: the light
    // that lights the terrain (dimmed when the planet eclipses it), mostly
    // forwards, with a little all round
    float rays_phase = 0.85 * henyey_greenstein_phase(LoV, end_rays_forward) + 0.15 * isotropic_phase;
    scattering += light_color * (end_rays_scattering * rays_phase * rays);
#endif

    return mat2x3(scattering, transmittance);
}

#endif // INCLUDE_FOG_END_FOG_VL
