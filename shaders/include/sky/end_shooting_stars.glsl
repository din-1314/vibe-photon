#if !defined INCLUDE_SKY_END_SHOOTING_STARS
#define INCLUDE_SKY_END_SHOOTING_STARS

/*
--------------------------------------------------------------------------------

  Photon Cinematic Concept (v0.8.1)

  include/sky/end_shooting_stars:
  Shooting stars in the End's sky (option Shooting Stars, and its Frequency):
  now and then a bright streak crosses the sky, headed downwards, its tail
  fading behind it, and is gone in about a second.

  Nothing is stored: each one is found from the time alone. The time is cut
  into slots, a few seconds each, on a few independent channels (so two can
  cross at once, rarely); a slot holds a shooting star or not, by chance, and
  where it starts, where it heads, how fast and how long are drawn from the
  slot's number. A view direction is then measured against its path (a great
  circle): how far off it, how far behind the head. A handful of arithmetic
  per channel - nothing next to the rest of the sky.

  Drawn by the sky pass over the nebula and the stars, behind the planet and
  the nebula's close wisps; along the direction seen (not bent by the black
  hole: they are near, as the near stars are).

--------------------------------------------------------------------------------
*/

#if defined END_SHOOTING_STARS || defined CONCEPT_OVERWORLD_SHOOTING_STARS

// The channels, and a slot's length (seconds, at Frequency 100%; v0.8.2: what
// was 300%, the developer's choice in game)
const int end_meteor_channels = 3;
const float end_meteor_slot = 7.0 / 3.0;
// The chance a slot holds a shooting star
const float end_meteor_chance = 0.6;
// How long one lasts (seconds), how fast it goes (radians a second), its tail
// (radians), where it can start (elevation, radians)
const vec2 end_meteor_life = vec2(0.6, 1.3);
const vec2 end_meteor_speed = vec2(0.30, 0.65);
const vec2 end_meteor_tail = vec2(0.14, 0.32);
const vec2 end_meteor_start_elevation = vec2(0.20, 1.05);
// Its brightness (the brightest stars of the Enhanced Star Field peak at 6 to
// 14) and colours (v0.8.2: brighter, the head blazing - enough for Photon's
// bloom to catch it - with a soft halo; the tail turning a pale cyan green, as
// a burning meteor's does, instead of a plain white falling)
const float end_meteor_brightness = 14.0;
const float end_meteor_head_flare = 6.0;   // the head's core, over the streak's
const float end_meteor_halo = 0.12;        // its soft halo
const vec3 end_meteor_head_color = vec3(1.00, 0.97, 0.90) * rec709_to_working_color;
const vec3 end_meteor_tail_color = vec3(0.55, 1.00, 0.85) * rec709_to_working_color;

// The shooting stars' light along a view direction.
//   pixel: a pixel's angular size (radians), so a streak is never thinner than
//          about a pixel and a half
//   time:  frameTimeCounter (seconds)
vec3 end_shooting_stars(vec3 dir, float pixel, float time) {
    vec3 light = vec3(0.0);
    float slot_length = end_meteor_slot / max(float(END_SHOOTING_STARS_FREQUENCY) * 0.01, 0.1);
    float width = max(0.7 * pixel, 3e-4);

    for (int channel = 0; channel < end_meteor_channels; ++channel) {
        // This channel's slot, and how far into it
        float t = time + float(channel) * 0.37 * slot_length;
        float slot = floor(t / slot_length);
        float age = t - slot * slot_length;
        vec4 a = hash4(vec3(slot, float(channel) * 17.13 + 3.1, 41.7));
        if (a.x > end_meteor_chance) continue;
        vec4 b = hash4(vec3(slot, float(channel) * 17.13 + 9.7, 83.3));

        float life = mix(end_meteor_life.x, end_meteor_life.y, a.y);
        float since = age - b.w * (slot_length - life);
        if (since < 0.0 || since > life) continue;

        // Its path: from a start, along a great circle, headed downwards
        float azimuth = 6.2831853 * a.z;
        float elevation = mix(end_meteor_start_elevation.x, end_meteor_start_elevation.y, a.w);
        vec3 start = vec3(sin(azimuth) * cos(elevation), sin(elevation), -cos(azimuth) * cos(elevation));
        vec3 across = normalize(cross(start, vec3(0.0, 1.0, 0.0)));
        vec3 down = cross(across, start); // (pointing upwards along the sky; negated below)
        float heading = 1.2 * (b.x - 0.5); // (radians off straight down)
        vec3 travel = -down * cos(heading) + across * sin(heading);
        vec3 axis = cross(start, travel);

        // This direction, measured against it: off its path, and behind its head
        float off = dot(dir, axis);
        if (abs(off) > 30.0 * width) continue;
        vec3 on = dir - axis * off;
        float along = atan(dot(on, travel), dot(on, start));
        float head = mix(end_meteor_speed.x, end_meteor_speed.y, b.y) * since;
        float behind = head - along;
        // (the tail grows from where it started: never longer than its way)
        float tail = min(mix(end_meteor_tail.x, end_meteor_tail.y, b.z), max(head, 1e-3));
        if (behind < -30.0 * width || behind > tail) continue;

        // Bright through most of its life, fading in and out; the tail
        // thinner and dimmer away from the head and turning cyan green, the
        // head a blazing core in a soft halo
        float shown = pow(sin(3.14159265 * since / life), 0.6);
        float along_tail = clamp01(behind / tail);
        float tail_width = width * mix(1.6, 0.8, along_tail);
        float streak = exp(-sqr(off / tail_width))
            * (behind > 0.0 ? pow(1.0 - along_tail, 1.5) : exp(-sqr(behind / width)));
        float from_head = sqr(off) + sqr(behind);
        float core = end_meteor_head_flare * exp(-from_head / sqr(1.5 * width));
        float halo = end_meteor_halo * exp(-from_head / sqr(6.0 * width));
        light += end_meteor_brightness * shown
            * (mix(end_meteor_head_color, end_meteor_tail_color, sqrt(along_tail)) * streak
                + end_meteor_head_color * (core + halo));
    }

    return light;
}

#endif // END_SHOOTING_STARS || CONCEPT_OVERWORLD_SHOOTING_STARS

#endif // INCLUDE_SKY_END_SHOOTING_STARS
