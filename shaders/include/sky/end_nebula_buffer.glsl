#if !defined INCLUDE_SKY_END_NEBULA_BUFFER
#define INCLUDE_SKY_END_NEBULA_BUFFER

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.7.5 - v0.7.8)

  include/sky/end_nebula_buffer:
  The End nebula's Frame Accumulation (option Frame Accumulation, on by
  default; off: none of this is compiled and the sky pass draws the nebula
  itself, every frame, as it always did).

  The nebula is marched with few samples, offset by a dither that changes
  every frame: one frame alone is grainy (five times the grain of sixteen
  frames averaged), and it is Photon's anti-aliasing (TAA) that averages the
  frames into a smooth picture. But TAA lets go of what it averaged as soon as
  the camera moves - walking is enough, the view bobs - and the grain shows,
  which reads as the nebula losing its resolution. So the nebula keeps its own
  average: deferred2 (which has nothing else to do in the End) draws it every
  frame, every pixel at the screen's resolution, and averages it with what it
  kept from the frames before, looked up where the camera's turn has moved it
  (and, for the parts near enough, its movement) - the sky is far, so that is
  exact. What TAA receives is already smooth, moving or not. It keeps it in
  the clouds' two buffers (colortex11, colortex12: unused in the End), which
  this pass reads as the frame before left them while it writes them anew -
  what Photon does for its clouds in the Overworld. Where nothing was kept
  (the edge of the screen when the camera turns, what a block or the hand has
  just uncovered) the pixel is the frame's own: no stale picture is ever
  shown.

  What is kept, for the sky pass (deferred4) to read back - it draws other
  things between them:
    colortex11: the far part (behind the black hole and the stars) - its
                light, and 1 + its dust's optical depth
    colortex12: the sea, the canopy and the near part, put together (in
                front of them) - their light, and in one number how much the
                sea and the canopy let through and the near part's dust's
                optical depth
  (a dust's transmittance per colour is exp(-depth * its colour), exactly
  what the marches compute; alpha below 1: nothing kept - no sky there.)
  The close wisps, near enough to shift as you walk, are not kept: the sky
  pass draws them itself.

  History: v0.7.5 to v0.7.6 drew the nebula at a lower resolution (option
  Nebula Resolution, removed); v0.7.7 and v0.7.8 drew a quarter of it each
  frame and kept the rest (option Temporal Upscaling): softer, grainy, and in
  game no faster - replaced by this.

--------------------------------------------------------------------------------
*/

// (CONCEPT_END_NEBULA_BUFFERED - the option is on and the nebula is drawn -
// is defined at the top of include/sky/end_nebula.glsl, which includes this
// file at its end and needs it before)

#if defined CONCEPT_END_NEBULA_BUFFERED

// The nebula's layers at a pixel
//   back:    the far part's light, and its dust's optical depth
//   front:   the light of the sea, the canopy and the near part, and the near
//            part's dust's optical depth
//   through: how much the sea and the canopy let through
struct EndNebulaLayers {
    vec4 back;
    vec4 front;
    float through;
    float mark; // (debug view: 1 drawn again this frame, 2 drawn because nothing was kept, 0 kept)
};

// The deepest dust kept (it lets a ten-millionth through)
const float end_nebula_buffer_depth_max = 15.99;

// The dust's transmittance from its optical depth, and back
vec3 end_nebula_buffer_transmittance(float depth) {
    return exp(-depth * end_nebula_dust_color);
}

float end_nebula_buffer_depth(float transmittance_r) {
    return min(-log(max(transmittance_r, 1e-30)) / end_nebula_dust_color.r, end_nebula_buffer_depth_max);
}

// A layer as it is kept, and back. The front's alpha holds three numbers in
// one: 1 + 1024 * soft + (how much the sea and the canopy let through, in
// 1023rds) + its depth / 16 - colortex12 is 32-bit floats for it, which hold
// them exactly enough (the depth to 1/250), and it is only ever read pixel by
// pixel.
//   soft: 1 if what is kept has been interpolated (the camera has turned)
//         since the pixel was last drawn, 0 if it is as it was drawn
vec4 end_nebula_buffer_pack_back(vec4 back) {
    return vec4(max(back.rgb, vec3(0.0)), 1.0 + clamp(back.a, 0.0, end_nebula_buffer_depth_max));
}

// (mark: the debug view's, 0 to 2 - see EndNebulaLayers; this frame's only, never read back as kept)
vec4 end_nebula_buffer_pack_front(vec4 front, float through, float soft, float mark) {
    return vec4(
        max(front.rgb, vec3(0.0)),
        1.0 + 2048.0 * mark + (soft > 0.5 ? 1024.0 : 0.0)
            + floor(clamp(through, 0.0, 1.0) * 1023.0 + 0.5)
            + clamp(front.a, 0.0, end_nebula_buffer_depth_max) * (1.0 / 16.0)
    );
}

vec4 end_nebula_buffer_unpack_back(vec4 kept) {
    return vec4(kept.rgb, kept.a - 1.0);
}

vec4 end_nebula_buffer_unpack_front(vec4 kept, out float through, out float soft) {
    float stored = kept.a - 1.0;
    float whole = floor(stored);
    float fraction = stored - whole;
    whole -= 2048.0 * floor(whole * (1.0 / 2048.0)); // (without the debug view's mark)
    soft = whole >= 1024.0 ? 1.0 : 0.0;
    through = (whole - 1024.0 * soft) * (1.0 / 1023.0);
    return vec4(kept.rgb, fraction * 16.0);
}

#if defined PROGRAM_DEFERRED4
// ---------------------------------------------------------------------------
//   The sky pass: the layers deferred2 has just written for this pixel
// ---------------------------------------------------------------------------

EndNebulaLayers end_nebula_buffer_read(ivec2 texel) {
    vec4 back = texelFetch(colortex11, texel, 0);
    vec4 front = texelFetch(colortex12, texel, 0);

    EndNebulaLayers layers;
    layers.back = vec4(0.0);
    layers.front = vec4(0.0);
    layers.through = 1.0;
    layers.mark = 0.0;
    // (nothing kept: no nebula rather than a wrong one. Not expected - both
    // passes find the sky the same way)
    if (back.a >= 1.0 && front.a >= 1.0) {
        layers.back = end_nebula_buffer_unpack_back(back);
        float soft;
        layers.front = end_nebula_buffer_unpack_front(front, layers.through, soft);
        layers.mark = floor((front.a - 1.0) * (1.0 / 2048.0));
    }
    return layers;
}
#endif

#if defined PROGRAM_DEFERRED2
// ---------------------------------------------------------------------------
//   deferred2: the nebula drawn and averaged with what was kept
// ---------------------------------------------------------------------------

// How much of what was kept goes into this frame's picture (x: the camera
// still; y: the camera turning 4 pixels a frame or more, when what is kept has
// been interpolated on its way). 0.8: the average of about the last nine
// frames - the grain mostly gone. No more than that: the nebula moves (up to a
// third of a pixel a frame near the black hole), and what is kept would trail
// behind it
const vec2 end_nebula_buffer_keep = vec2(0.8, 0.6);
// ... and where the far part falls into the black hole, of that (v0.8.0: it
// moves fastest there - a third of a pixel a frame or more - and trailed)
const float end_nebula_buffer_keep_falling = 0.5;

// The nearest the front can be (blocks): the sea and the canopy straight
// below and above, the near part elsewhere. For how far the camera's own
// movement shifts it on the screen
const vec2 end_nebula_buffer_nearest = vec2(650.0, 1700.0);
// ... and how far it may shift in a frame (pixels) for what is kept of it to
// be used: faster than that (flying), it is not averaged
const float end_nebula_buffer_shift_max = 0.2;

// Where a point of the sky was on the screen the frame before (in pixels).
//   view_dir: the direction to it, view space (this frame's)
//   moved:    how far the camera has moved since, over the point's distance
//             (scene space; 0: the point is too far for it to matter)
// With the camera still it is the same pixel, to the last digit (what is
// kept is then never interpolated, so it cannot soften over time). Far off
// the screen if it was behind the camera.
vec2 end_nebula_buffer_place_before(ivec2 texel, vec3 view_dir, vec3 moved) {
    vec2 rendered = view_res * taau_render_scale;
    vec3 scene_dir = mat3(gbufferModelViewInverse) * normalize(view_dir);
    vec3 before = mat3(gbufferPreviousModelView) * (scene_dir + moved);
    if (before.z > -1e-6) return vec2(-1e6);

    vec4 clip = gbufferPreviousProjection * vec4(before, 0.0);
    vec2 place = (clip.xy / clip.w * 0.5 + 0.5) * rendered;
    vec2 same = vec2(texel) + 0.5;
    return all(lessThan(abs(place - same), vec2(0.02))) ? same : place;
}

// What was kept of a layer at a place of the frame before (in its pixels:
// their centres at halves), interpolated between the four pixels round it -
// those that kept something. False if too few of them did.
//   soft: 1 if it is interpolated now, or (the front) was before
bool end_nebula_buffer_kept(sampler2D layer, vec2 place, bool front, out vec4 kept, out float through, out float soft) {
    ivec2 limit = ivec2(view_res * taau_render_scale);
    vec2 corner = floor(place - 0.5);
    vec2 f = (place - 0.5) - corner;

    kept = vec4(0.0);
    through = 0.0;
    soft = max(f.x * (1.0 - f.x), f.y * (1.0 - f.y)) > 0.01 ? 1.0 : 0.0;
    float weight = 0.0;

    for (int j = 0; j < 2; ++j) {
        for (int i = 0; i < 2; ++i) {
            ivec2 texel = ivec2(corner) + ivec2(i, j);
            float w = (i == 0 ? 1.0 - f.x : f.x) * (j == 0 ? 1.0 - f.y : f.y);
            if (w < 1e-4 || any(lessThan(texel, ivec2(0))) || any(greaterThanEqual(texel, limit))) continue;

            vec4 stored = texelFetch(layer, texel, 0);
            // (written this way round, anything that is not a number fails too)
            if (!(stored.a >= 1.0)) continue;

            if (front) {
                float through_here, soft_here;
                kept += w * end_nebula_buffer_unpack_front(stored, through_here, soft_here);
                through += w * through_here;
                soft = max(soft, soft_here);
            } else {
                kept += w * end_nebula_buffer_unpack_back(stored);
            }
            weight += w;
        }
    }

    if (!(weight > 0.4)) return false;

    kept /= weight;
    through /= weight;
    return !(any(isnan(kept)) || any(isinf(kept)));
}

// The far part along a view ray: looked up through the black hole's lens
// (nothing in its shadow, where it is hidden). Its light and optical depth.
//   falling: how much of it is falling into the black hole there (0..1, as
//            end_nebula_behind() finds it) - where it moves fastest
vec4 end_nebula_buffer_far(vec3 ray_dir, EndNebulaField field, float pixel, out float falling) {
    vec3 lensed_dir = ray_dir;
    float seen = 1.0;
    falling = 0.0;
#if defined SKY_BLACK_HOLE
    // (v0.7.6: the lens alone, bh_lens() - the same path as the full black
    // hole's, without drawing its disc, which this pass has no use for)
    bh_lens(lensed_dir, seen, end_black_hole_direction());
    seen = mix(1.0, seen, min(END_BLACK_HOLE_INTENSITY, 1.0));
#if END_NEBULA_MOTION != 0 && END_BLACK_HOLE_PULL != 0
    falling = 1.0 - smoothstep(end_nebula_infall_reach.x, end_nebula_infall_reach.y,
        field.hole_scale * fast_acos(clamp(dot(lensed_dir, field.hole), -1.0, 1.0)));
#endif
#endif
    if (seen <= 0.0) return vec4(0.0);

    mat2x3 far_part = end_nebula_behind(lensed_dir, field, pixel);
    return vec4(far_part[0], end_nebula_buffer_depth(far_part[1].r));
}

// This pixel of the two buffers: the nebula's layers there, drawn or kept.
//   back_kept:  colortex11
//   front_kept: colortex12
void end_nebula_buffer_write(out vec4 back_kept, out vec4 front_kept) {
    // (alpha below 1: nothing kept)
    back_kept = vec4(0.0);
    front_kept = vec4(0.0);

    ivec2 texel = ivec2(gl_FragCoord.xy);
    // Only where the sky is seen, as the sky pass finds it
    if (texelFetch(depthtex1, texel, 0).x < 1.0) return;

    vec2 rendered = view_res * taau_render_scale;

    // The view direction, as the sky pass finds it (with the frame's
    // sub-pixel jitter), and a pixel's angular size
    vec3 view_pos = screen_to_view_space(vec3((vec2(texel) + 0.5) / rendered, 1.0), true);
    vec3 ray_dir = normalize(view_to_scene_space(view_pos) - gbufferModelViewInverse[3].xyz);
    float pixel = 2.0 / (gbufferProjection[1][1] * rendered.y);
    float view_cos = clamp(dot(ray_dir, -gbufferModelViewInverse[2].xyz), 0.05, 1.0);
    pixel *= view_cos * sqrt(view_cos);

    // (v0.7.6) Behind the planet nothing of the nebula's far part or front is
    // seen: where the planet covers this pixel (a few pixels inside its edge)
    // empty layers are kept, and nothing is drawn
#if defined SKY_PLANET
    {
        float planet_radius = clamp(EP_RADIUS * END_PLANET_SIZE, 0.05, 1.45);
        vec3 planet_center = end_planet_direction();
        float planet_cos = dot(ray_dir, planet_center);
        if (planet_cos > 0.0
            && length(ray_dir - planet_center * planet_cos) < (0.988 * sin(planet_radius) - 4.0 * pixel)) {
            back_kept = end_nebula_buffer_pack_back(vec4(0.0));
            front_kept = end_nebula_buffer_pack_front(vec4(0.0), 1.0, 0.0, 0.0);
            return;
        }
    }
#endif

    // What was kept for this pixel. Where it was the frame before: from the
    // pixel's centre (without the jitter). The far part is too far for the
    // camera's own movement to shift it; the front is not, quite - it is
    // looked up where that movement has shifted its nearest part, and not
    // used at all when that is too far (flying: the front is then the frame's
    // own, not averaged)
    vec3 center_dir = screen_to_view_space(vec3((vec2(texel) + 0.5) / rendered, 1.0), false);

    // (how far the nebula has moved past the camera: as end_nebula_field()
    // places it - it follows the camera beyond its reach from the island)
    vec3 from_island = cameraPosition - end_nebula_center;
    vec3 from_island_before = previousCameraPosition - end_nebula_center;
    vec3 camera_moved = from_island * min(1.0, end_nebula_reach / max(length(from_island), 1e-3))
        - from_island_before * min(1.0, end_nebula_reach / max(length(from_island_before), 1e-3));
    float nearest = min(end_nebula_buffer_nearest.y, end_nebula_buffer_nearest.x / max(abs(ray_dir.y), 1e-3));
    float shift = length(camera_moved) / nearest * (0.5 * gbufferProjection[1][1] * rendered.y);

    vec2 place_back = end_nebula_buffer_place_before(texel, center_dir, vec3(0.0));
    vec2 place_front = end_nebula_buffer_place_before(texel, center_dir, camera_moved / nearest);

    vec4 back_before = vec4(0.0);
    vec4 front_before = vec4(0.0);
    float through_before = 1.0;
    float unused;
    float soft;
    bool has_back = end_nebula_buffer_kept(colortex11, place_back, false, back_before, unused, soft);
    bool has_front = shift < end_nebula_buffer_shift_max
        && end_nebula_buffer_kept(colortex12, place_front, true, front_before, through_before, soft);

    // How much of it goes in: less while the camera turns
    vec2 same = vec2(texel) + 0.5;
    float keep_back = mix(end_nebula_buffer_keep.x, end_nebula_buffer_keep.y,
        clamp(0.25 * length(place_back - same), 0.0, 1.0));
    float keep_front = mix(end_nebula_buffer_keep.x, end_nebula_buffer_keep.y,
        clamp(0.25 * length(place_front - same), 0.0, 1.0));

    vec4 back, front;
    float through;
    {
        // (the field's own dither: the screen pixel's, another every frame)
        EndNebulaField field = end_nebula_field();

        {
            float falling;
            back = end_nebula_buffer_far(ray_dir, field, pixel, falling);
            // (v0.8.0) Where it falls into the black hole it moves fastest:
            // less of what was kept goes in there, or it would trail behind
            keep_back *= mix(1.0, end_nebula_buffer_keep_falling, falling);
            if (has_back) back = mix(back, back_before, keep_back);
        }

        {
            // The sea, the canopy over it, the near part over both. The near
            // part's transmittance comes mixed with Photon Original's dark
            // surround, mix(1, transmittance, surround): the sky pass mixes
            // it again itself, so what is kept is the dust's own
            mat2x3 sea = end_nebula_basin(ray_dir, field, pixel);
            mat2x3 canopy = end_nebula_canopy(ray_dir, field, pixel);
            mat2x3 near_part = end_nebula_front(ray_dir, field, pixel);
            float surround = end_nebula_black_hole_surround(ray_dir);
            float dust_through = surround > 1e-4 ? clamp01((near_part[1].r - 1.0 + surround) / surround) : 1.0;
            front = vec4(
                (sea[0] * canopy[1] + canopy[0]) * near_part[1] + near_part[0],
                end_nebula_buffer_depth(dust_through)
            );
            through = sea[1].r * canopy[1].r;
            if (has_front) {
                front = mix(front, front_before, keep_front);
                through = mix(through, through_before, keep_front);
            }
        }
    }

    float mark = 0.0; // (v0.8.1: the debug view is gone; its slot in the alpha stays empty)
    back_kept = end_nebula_buffer_pack_back(back);
    front_kept = end_nebula_buffer_pack_front(front, through, 0.0, mark);
}
#endif

#endif // Temporal Upscaling

#endif // INCLUDE_SKY_END_NEBULA_BUFFER
