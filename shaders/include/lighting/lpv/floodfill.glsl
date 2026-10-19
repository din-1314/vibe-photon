#if !defined INCLUDE_LIGHTING_LPV_FLOODFILL
#define INCLUDE_LIGHTING_LPV_FLOODFILL

#include "voxelization.glsl"

bool is_emitter(uint block_id) { return 32u <= block_id && block_id < 80u; }

bool is_translucent(uint block_id) { return 80u <= block_id && block_id < 96u; }

vec3 get_emitted_light(uint block_id) {
    if (is_emitter(block_id)) {
        return texelFetch(light_data_sampler, ivec2(int(block_id) - 32, 0), 0)
            .rgb;
    } else {
        return vec3(0.0);
    }
}

vec3 get_tint(uint block_id, bool is_transparent) {
    if (is_translucent(block_id)) {
        return texelFetch(light_data_sampler, ivec2(int(block_id) - 80, 1), 0)
            .rgb;
    } else {
        return vec3(is_transparent);
    }
}

ivec3 clamp_to_voxel_volume(ivec3 pos) {
    return clamp(pos, ivec3(0), voxel_volume_size - 1);
}

// Photon Cinematic Concept (v0.8.6): the End portal, found from its frame.
// The portal's blocks are drawn as block entities, which never reach the voxel
// map, so they are empty there; the frame's blocks with an eye (id 45) are.
// An empty voxel with a frame within 3 blocks in all four directions at its
// height, with only empty voxels in between, is the portal: it shines in its
// light (light_colors.glsl, End portal) and is flagged in the light volume's
// alpha for its mist (include/fog/end_portal_mist.glsl). (plain #ifdef for the
// menu)
#ifdef END_PORTAL_GLOW
#define CONCEPT_PORTAL_LIGHT

bool concept_portal_frame_towards(ivec3 pos, ivec3 dir) {
    for (int d = 1; d <= 3; ++d) {
        ivec3 p = pos + dir * d;
        if (any(lessThan(p, ivec3(0))) || any(greaterThanEqual(p, voxel_volume_size))) {
            return false;
        }
        uint id = texelFetch(voxel_sampler, p, 0).x;
        if ((id & 127u) == 45u) return true;
        if (id != 0u) return false;
    }
    return false;
}

bool concept_voxel_solid(ivec3 p) {
    return all(greaterThanEqual(p, ivec3(0))) && all(lessThan(p, voxel_volume_size))
        && texelFetch(voxel_sampler, p, 0).x != 0u;
}

bool concept_is_end_portal(ivec3 pos) {
    bool framed = concept_portal_frame_towards(pos, ivec3(1, 0, 0))
        && concept_portal_frame_towards(pos, ivec3(-1, 0, 0))
        && concept_portal_frame_towards(pos, ivec3(0, 0, 1))
        && concept_portal_frame_towards(pos, ivec3(0, 0, -1));
#if defined WORLD_END
    // v0.8.7: the End's exit portal has no frame, but its place and shape
    // are fixed: round the bedrock pillar at x = z = 0, the 20 blocks within
    // 2.5 of it (Minecraft's exit podium), on a bedrock floor, inside a
    // bedrock rim. An empty voxel there, with the pillar beside it, the floor
    // under it and the rim at its height, is the portal. (While the dragon
    // lives the podium is empty and passes too: it shines all the same.)
    if (!framed) {
        ivec3 block = ivec3(floor(voxel_to_scene_space(vec3(pos) + 0.5) + cameraPosition));
        int r2 = block.x * block.x + block.z * block.z;
        if (0 < r2 && r2 < 7) { // (r2 < 6.25: the 5x5 square without its corners)
            ivec3 to_pillar = ivec3(-block.x, 0, -block.z);
            framed = concept_voxel_solid(pos + to_pillar)                       // the pillar
                && concept_voxel_solid(pos + ivec3(0, -1, 0))                  // the floor
                && concept_voxel_solid(pos + to_pillar + ivec3(3, 0, 0))       // the rim
                && concept_voxel_solid(pos + to_pillar + ivec3(-3, 0, 0))
                && concept_voxel_solid(pos + to_pillar + ivec3(0, 0, 3))
                && concept_voxel_solid(pos + to_pillar + ivec3(0, 0, -3));
        }
    }
#endif
    return framed;
}
#endif

vec3 gather_light(sampler3D light_sampler, ivec3 pos) {
    const ivec3[6] face_offsets = ivec3[6](
        ivec3(1, 0, 0),
        ivec3(0, 1, 0),
        ivec3(0, 0, 1),
        ivec3(-1, 0, 0),
        ivec3(0, -1, 0),
        ivec3(0, 0, -1)
    );

    if (clamp_to_voxel_volume(pos) != pos) {
        return vec3(0.0);
    }

    const float center_weight = 1.05;

    return (texelFetch(light_sampler, pos, 0).rgb * center_weight
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[0]),
                  0
            )
                  .xyz
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[1]),
                  0
            )
                  .xyz
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[2]),
                  0
            )
                  .xyz
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[3]),
                  0
            )
                  .xyz
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[4]),
                  0
            )
                  .xyz
            + texelFetch(
                  light_sampler,
                  clamp_to_voxel_volume(pos + face_offsets[5]),
                  0
            )
                  .xyz)
        * rcp(7.0 * center_weight);
}

void update_lpv(writeonly image3D light_img, sampler3D light_sampler) {
    vec3 current_center
        = get_voxel_volume_center(gbufferModelViewInverse[2].xyz);
    vec3 previous_center = get_voxel_volume_center(vec3(
        gbufferPreviousModelView[0].z,
        gbufferPreviousModelView[1].z,
        gbufferPreviousModelView[2].z
    ));

    ivec3 pos = ivec3(gl_GlobalInvocationID);
    ivec3 previous_pos = ivec3(
        vec3(pos) - floor(previousCameraPosition) + floor(cameraPosition)
        - current_center + previous_center
    );

    uint block_id = texelFetch(voxel_sampler, pos, 0).x;
#if defined CONCEPT_PORTAL_LIGHT
    bool end_portal = block_id == 0u && concept_is_end_portal(pos);
#else
    const bool end_portal = false;
#endif
    bool transparent = block_id == 0u || block_id >= 128u;
    block_id = block_id & 127;
    vec3 light_avg = gather_light(light_sampler, previous_pos);
    vec3 emitted_light = sqr(get_emitted_light(end_portal ? 63u : block_id));
    vec3 tint = sqr(get_tint(block_id, transparent));

    vec3 light = emitted_light + light_avg * tint;

    imageStore(light_img, pos, vec4(light, float(end_portal)));
}

#endif // INCLUDE_LIGHTING_LPV_FLOODFILL
