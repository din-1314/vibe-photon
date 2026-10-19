# Photon Cinematic Concept --- Changelog

All entries below describe the documented baseline of the project.

## Unreleased --- Documentation Baseline

### Added

-   Established the Photon Cinematic Concept project identity.
-   Established `workspace/` as the active source directory.
-   Established `fail/` as reference-only storage for abandoned
    prototypes.
-   Defined the initial visual direction.
-   Defined the two planned sky variants: dark space and Photon purple.
-   Defined the IterationT Black Hole brightness reference.
-   Defined the planned star-field, gravitational shadow/light, and
    volumetric nebula systems.
-   Defined incremental development and anti-rewrite rules.
-   Documented the current Black Hole and Planet configuration
    architecture.
-   Documented the need to integrate with Photon's existing
    bloom/exposure pipeline where appropriate.

### Current baseline

The supplied workspace already contains a working Black Hole system and
a Planet system.

These systems are considered the starting point for further development.

### Next planned work

1.  Full project/codebase study.
2.  Concept menu reorganization.
3.  Independent world-scope controls for Black Hole and Planet.
4.  Dark space sky variant.
5.  Dense star field.
6.  Black Hole brightness refinement.
7.  Gravitational shadow/light system.
8.  Volumetric nebula.
9.  Full visual integration.

No implementation from these future stages should be considered complete
until tested in-game.

## Documentation Update — Workflow Rules

Added project-wide rules for:
- Learning Mode and beginner-friendly explanations;
- stopping to request visual references whenever a precise visual target is needed;
- mandatory ZIP creation after every implementation change;
- testing through `builds/testing/` rather than the raw workspace;
- promoting validated versions to `builds/stable/`;
- versioning beginning at `v0.1`, followed by `v0.1.1`, `v0.1.2`, etc., with new milestones using `v0.2`, `v0.3`, and so on.

## Documentation update

- Added Optimization as an official development phase.
- Added the phase sequence from analysis through stable validation.
- Optimization is performed after visual integration and before a build is considered stable.

## v0.4.2 --- Promoted to stable (Star Field phase closed)

`builds/testing/photon-cinematic-v0.4.2.zip` was manually tested in-game
by the developer and promoted, unchanged, to
`builds/stable/photon-cinematic-v0.4.2.zip` (byte-for-byte copy, not a
rebuild).

- SHA-256 (testing and stable, identical):
  `a4a553e5a56565df18babcdf15e430654a979f745dcb542b162e302222b7f755`
- Previous stable builds kept unchanged: `photon-cinematic-v0.2.1.zip`
  (Cinematic Void) and `photon-cinematic-v0.3.3.zip` (Black Hole
  brightness and broad halo).

Star Field phase (v0.4 → v0.4.2), now closed:

-   v0.4: first dense star field (Cinematic Void only).
-   v0.4.1: Enhanced Star Field in `include/sky/end_stars.glsl` for both
    sky styles, one ON/OFF option (OFF = exactly the v0.3.3 stars);
    full-sphere coverage including the Void below; stars stretched by
    the Black Hole's lensing; per-layer drift and pulled stars circling
    the Black Hole; exact, arc-oriented cell search (star cost about 60%
    lower than v0.4).
-   v0.4.2: small-star visibility (brightness lift of 0.006), clearly
    perceptible twinkle (+-35%, 4--10 s per star) and slightly faster
    pulled stars (0.042 rad/s). No performance change.

Possible future refinement (not reopened now): reassess the twinkle of
the larger stars once the nebula and the final End integration exist.

Next phase: v0.5 --- Black Hole Illumination (investigation first).

## v0.5.4.2 --- Promoted to stable (Black Hole Illumination and Planet interaction phase closed)

`builds/testing/photon-cinematic-v0.5.4.2.zip` was manually tested in-game
by the developer and promoted, unchanged, to
`builds/stable/photon-cinematic-v0.5.4.2.zip` (byte-for-byte copy, not a
rebuild).

- SHA-256 (testing and stable, identical):
  `7e3a5182917055642e0d855bcb1f7664906db02f5b0a45e2bd8a1c3703d18a0b`
- Previous stable builds kept unchanged: `photon-cinematic-v0.2.1.zip`,
  `photon-cinematic-v0.3.3.zip` and `photon-cinematic-v0.4.2.zip`.

Black Hole Illumination and Planet phase (v0.5 → v0.5.4.2), now closed:

-   v0.5.1 → v0.5.1.3: the Black Hole becomes the End's directional light
    (Environmental Light option): Photon's own lighting, shadow map (any
    resolution) and fog read its direction and a fixed cool-white colour;
    entity shadows, Cinematic Void ambient and AO in sunlight adapted.
-   v0.5.2: planet orbit aligned to pass through the Black Hole, with an
    Orbit Phase option.
-   v0.5.3 → v0.5.4: planet eclipses the Black Hole's light (luminous-disc
    source, per-point visibility on terrain, broad halo and fog dimmed);
    planet lit by the Black Hole with its own red-brown surface and a
    light-driven atmosphere; orbit inclination 15 degrees.
-   v0.5.4.1: atmosphere visible at full phase (air along the grazing line
    of sight), surface fading into its air at the limb.
-   v0.5.4.2: atmosphere front scattering calibrated (0.35 → 0.20).

Possible future refinements (not reopened now): cap of the forward
scattering in partial eclipse phases; planetshine on the terrain.

Next phase: Nebula (architecture and research first).

## v0.6.7.4 --- Promoted to stable (Nebula phase closed)

`builds/testing/photon-cinematic-v0.6.7.4.zip` was manually tested in-game
by the developer and promoted, unchanged, to
`builds/stable/photon-cinematic-v0.6.7.4.zip` (byte-for-byte copy, not a
rebuild).

- SHA-256 (testing and stable, identical):
  `ff8abf61c6f54a21490e9b54a7fd049ddf2e07aee1c1034de9ca3bfbb75c98e8`
- Previous stable builds kept unchanged: `photon-cinematic-v0.2.1.zip`,
  `photon-cinematic-v0.3.3.zip`, `photon-cinematic-v0.4.2.zip` and
  `photon-cinematic-v0.5.4.2.zip`.

Nebula phase (v0.6.0 → v0.6.7.4), now closed:

-   v0.6.0 → v0.6.2: procedural Nebula in the End sky (`include/sky/end_nebula.glsl`):
    far, middle and near layers on spheres around the island (parallax, no
    raymarch), Eagle Nebula (M16) inspired palette and density hierarchy,
    Intensity / Coverage / Motion options; Nebula off is identical to v0.5.4.2.
-   v0.6.3 → v0.6.5: motion, cosmic dust and Dragon experiments (the
    rigid rotation and the v0.6.5 Dragon layer and dust were rejected and
    removed).
-   v0.6.6 → v0.6.7.1: anchored composition, an inner layer (1 500 blocks),
    the Dragon as a 3D spine raising the existing field, near/inner dust
    layers, concentrated blue nuclei, world-space Cosmic Dust particles.
-   v0.6.7.2 → v0.6.7.4: form shading from the Black Hole's direction (lit
    and shadowed sides of every mass), deep blue nuclei, close dust grains
    from 12 blocks, the Dragon's neck and head, and a dark surround behind
    the Black Hole in Photon Original.

Next phase: v0.6.8 --- Plans 6–9 (Stars refinement + Nebula integration,
Black Hole → Nebula lighting, Black Hole lensing → Nebula + Stars,
Environment Motion).

## v0.8.0 --- Promoted to stable (Cinematic End phase closed)

`builds/testing/photon-cinematic-v0.8.0.zip` was tested in-game by the
developer (2026-10-17: "essa versao ficou boa") and promoted, unchanged, to
`builds/stable/photon-cinematic-v0.8.0.zip` (byte-for-byte copy).

- SHA-256 (testing and stable, identical):
  `a855743b2c5dbb98d260ac3d5ff2b663bfa03db56a0077ec422d5a6491291191`
- Previous stable builds kept unchanged.

v0.6.8 → v0.8.0, now closed:

-   v0.6.8 → v0.7.1: intermediate and near stars, the nebula rebuilt as the
    Eagle (M16) in the Hubble palette with a marched far and near part, the
    young cluster lighting it, the Nebula Sea below the island and its
    Canopy above, the close wisps.
-   v0.7.2: the nebula and the stars flow towards the black hole and fall
    into it through its lens (option Pull Speed: Off / Slow / Normal /
    Fast), the black hole's light on the nebula; Black Hole Size 0.80 and
    ACES tonemap by default.
-   v0.7.3: End Portal anomaly experiments - rejected and removed (the
    portal is postponed).
-   v0.7.4 → v0.7.6: exact optimizations (planet first, nothing drawn in the
    black hole's shadow, early stops), colour options.
-   v0.7.5 → v0.7.8: lower-resolution and temporal-upscaling experiments for
    the nebula - replaced (they softened it, or saved nothing on the
    developer's RX 6500 XT).
-   v0.7.9 → v0.8.0: Frame Accumulation (the nebula averaged over the last
    frames, following the camera: its dither no longer shows while moving,
    which had read as a lower resolution), no trail where it falls into the
    black hole, option Nebula Quality (30-100 %).
-   Colour screens in the style of Photon's water coefficients: Nebula
    Colour, Sea Colour, Black Hole Colour (which also colours its light on
    the world).
-   Colored Lights and Colored Light Shafts on by default.

## v0.8.1 --- Testing

-   Shooting Stars (option, with Frequency): now and then a streak crosses
    the End's sky (`include/sky/end_shooting_stars.glsl`).
-   Black Hole Rays (option, with Intensity): the black hole's light through
    a thin haze round the main island, in beams between the pillars
    (`include/fog/end_fog_vl.glsl`; needs Environmental Light).
-   The debug option Show Frame Accumulation removed from the menu.

## v0.8.2 / v0.8.3 --- Testing

-   v0.8.2: defaults set to the developer's in-game choice (Shooting Star
    Frequency 100 % = the former 300 %, Black Hole Ray Intensity 100 % = the
    former 200 %); brighter shooting stars - a blazing head with a small
    halo, a tail turning pale cyan green.
-   v0.8.3: the End's cave light. Photon gave the End no light where the sky
    light is 0 (under the main island, inside End cities): with the black
    hole's light blocked too, the hand and everything there went pure black.
    The Overworld's faint cave light now applies in the End too, in the End
    ambient's colour (option Cave Lighting), and Night Vision works there.

## v0.8.4 --- Testing

-   The black rectangle under the main island: one invalid pixel (NaN or
    infinite) was spread by the TAA and the bloom's downsampling into a big
    solid black block. The deferred shading and the layer blending now turn
    any invalid pixel black before it leaves them (one pixel, filled by the
    TAA), so it can no longer grow into a rectangle.

## v0.8.5 --- Testing

-   Cinematic End Portal (new option, on): the End portal and gateway keep
    Minecraft's own look - layers of small square specks, each turned and
    drifting its own way, a cloudy deepest layer - in our End's colours
    (near-black, the nebula's brown, blue, orange and amber, the black
    hole disc's warm white). The layers sit at real depths under the
    surface (parallax), twinkle, a few flare now and then (glints through
    the bloom), and the portal breathes slowly. Works in every world
    (include/misc/end_portal_concept.glsl). Off: Photon's portal.

## v0.8.6 --- Testing

-   Portal Light and Mist (new option, on; Intensity 25-300 %; needs
    Colored Lights): the shadow pass now marks the End portal's blocks (a
    block entity) in Colored Lights' voxel map, so the portal lights the
    room in our End's warm light and glows in Colored Lights' fog; from the
    same map a mist in the nebula's orange and blue rises out of it (about
    two blocks high), with glints rising and fading (c0,
    include/fog/end_portal_mist.glsl). Other block entities are still left
    out of the shadow map unless Block Entity Shadows is on.
-   v0.8.6 in game: nothing changed - Iris does not draw the portal
    (a block entity) in the shadow pass. v0.8.6.1: that marking removed;
    Colored Lights' floodfill finds the portal from its frame instead (an
    empty voxel with a frame with an eye within 3 blocks in all four
    directions), lights it and flags it in the light volume's alpha for the
    mist. Works for stronghold portals (the End's exit portal and gateways
    have no frame). In game: the room lit, the mist and glints showing.
-   v0.8.6.2: the mist was grainy and the glints big balls. The mist is now
    marched finely only over the 7 blocks of the ray round the portal
    (found by a coarse walk), its edges read through the volume's linear
    filter (smooth instead of blocky); the glints are a few times smaller
    and warmer.

## v0.8.7 --- Promoted to stable (End phase closed)

-   Tested in game and approved by the developer (2026-10-19); the stable
    build is byte-identical to the testing one (SHA-256 081c0beb...64198).

-   Sky style Photon Original renamed Photon Concept (Photon's purple End
    with the Concept's black hole, planet, nebula and stars) and made the
    default; Cinematic Void keeps its name. Internal names unchanged, so
    saved settings keep working.
-   Portal Light and Mist on the End's exit portal too: it has no frame,
    but its place and shape are fixed (the 20 blocks within 2.5 of the
    bedrock pillar at x = z = 0, on the bedrock floor, inside the rim), so
    the floodfill recognises them there. While the dragon lives the empty
    podium passes too.
-   Colored Lights' compute shaders (floodfill) now validated as well.
-   The Concept's menu renamed Din Concept (was Cinematic Concept).

## v0.9.0 --- Testing (Overworld phase)

-   Planet as Moon (new option, on; Size 100-500 % of Photon's moon,
    250): our planet takes the moon's place in the Overworld - where the
    moon is, lit from where Photon's moon is lit in each phase, so it rises,
    sets and waxes and wanes with it (draw_end_planet_at() in
    include/sky/end_planet.glsl). Shader moon only.
-   Black Hole in the Overworld (new option, on; Size 20-100 %, 40): fixed
    among the stars in Photon's celestial frame, about 50 degrees from the
    moon, so it rises and sets with them; bends the stars round it; fades
    out by day. Does not light the world.
-   Shooting Stars in the Overworld (new option, on): the End's shooting
    stars at night, dimmer, behind the atmosphere and clouds.

## v0.9.1 --- Testing

-   World choice per object, in place of v0.9.0's separate Overworld
    toggles: Black Hole World, Planet World and Shooting Stars World - End
    Only / Overworld Only / Both (default Both), in the black hole's and
    planet's screens and next to the shooting stars. In the Overworld the
    planet is the moon (no longer its End orbit); the Overworld sizes moved
    to the black hole's and planet's screens.

## v0.9.2 --- Testing

-   The black hole has the End's size in the Overworld too (v0.9.0's
    smaller Overworld size removed: it looked too far away). The planet as
    the moon keeps its own size.

## v0.9.3 --- Testing

-   The black hole has the End's place in the Overworld's sky too (its
    Azimuth and Elevation options): v0.9.0 - v0.9.2 placed it among the
    stars, turning with them, which put it too high. Still at night only.

## v0.9.4 --- Testing

-   The black hole by day in the Overworld too: fainter (45 %), its light
    seen through the blue of the air laid over it, as the moon by day.
-   Enhanced Star Field in the Overworld: new World option (End Only /
    Overworld Only / Both, default Both); in the Overworld it takes the
    place of Photon's stars at night, dimmed to their brightness, turning
    with the sky and bent by the black hole.
-   Milky Way (new option, on; Intensity 25-300 %): a band across the
    Overworld's night sky in the nebula's colours - an amber bulge, bluish
    ends, star clouds, a broken dust rift - fixed among the stars, at night
    only (include/sky/overworld_milky_way.glsl, value noise, no texture).

## v0.9.5 --- Testing

-   The Milky Way 2.5 times brighter at 100 % (too faint in game).

## v0.9.6 --- Testing

-   Menu: a new Stars screen in Din Concept with the star field (and its
    World), the Milky Way (and its Intensity) and the shooting stars (and
    their Frequency and World).

## v0.9.7 --- Testing

-   A grander Milky Way: about twice as wide, a big glowing amber bulge
    round its core, star clouds and dust on a larger scale; 100 % is now
    v0.9.5's 200 %.

## v0.9.8 --- Testing

-   Milky Way: its bulge about 35 % dimmer (it lit the clouds like a dawn)
    and its core a neutral warm white instead of orange.
-   The black hole by day in the Overworld: its disc nearly as bright as
    at night (85 %), and its shadow now darkens the sky's light behind it
    (65 %): a dark hole in the blue, the clouds passing in front.

## v1.0.0 --- Promoted to stable (Din Concept 1.0)

-   Approved by the developer (2026-10-19); builds/stable/Din-Concept-v1.0.0.zip
    is byte-identical to the testing build (SHA-256 8481e726...c10).

-   Updated to the latest Photon main (2026-10-17, for Minecraft 26.3):
    three-way merge (old Photon, ours, new Photon) - 18 files updated, 1
    removed (spherical_harmonics_fallback.glsl); the only conflict, the
    quality profiles, keeps Photon's new SHADER_AO setting and our Colored
    Lights on High. Photon's fixes also make 6 programs compile that did
    not before (gbuffers_skytextured, gbuffers_weather). photon/photon-main.zip
    is the new baseline (the old one kept as photon-main-2026-07.zip).
-   Named Din Concept 1.0: menu header "Din Concept 1.0 (Photon)" / "Photon
    by SixthSurge"; README with what it adds and the credits (Photon by
    SixthSurge, IterationT, made with Claude and ChatGPT). Photon's LICENSE
    kept.
