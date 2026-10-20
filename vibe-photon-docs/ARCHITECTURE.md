# Photon Cinematic Concept --- Architecture Notes

## 1. Current source baseline

The active source supplied for the workspace is a full Photon shader
tree.

The relevant top-level areas include:

-   `shaders/world0/`
-   `shaders/world1/`
-   `shaders/world-1/`
-   `shaders/program/`
-   `shaders/include/`
-   `shaders/photonics/`
-   `shaders/image/`
-   `shaders/lang/`
-   `shaders/settings.glsl`
-   `shaders/shaders.properties`

## 2. Existing sky object organization

The current source contains dedicated End sky systems including:

-   `shaders/include/sky/end_black_hole.glsl`
-   `shaders/include/sky/end_planet.glsl`
-   `shaders/include/sky/end_sky_common.glsl`

This is useful because Black Hole and Planet already have separable
implementations.

## 3. Current configuration model

The current settings include a shared world-scope selector named
`SKY_OBJECTS_WORLD`.

Its current choices include:

-   off;
-   End only;
-   Overworld only;
-   Overworld + End.

The current Black Hole and Planet systems also have independent
enable/configuration controls.

The current implementation therefore has two related concepts:

1.  whether sky objects are allowed in a world;
2.  whether an individual object is enabled.

The future Concept menu should make this relationship clearer to the
user.

## 4. Black Hole configuration currently present

The current source contains controls for:

-   enable;
-   intensity;
-   size;
-   disc brightness;
-   warp strength;
-   speed;
-   azimuth;
-   elevation;
-   inclination;
-   raymarch steps.

The exact set should not be assumed to be final.

The first implementation stage should review whether these controls are
still appropriate for the Concept version.

## 5. Planet configuration currently present

The current source contains controls for:

-   enable;
-   size;
-   orbit speed;
-   rotation speed;
-   orbit azimuth;
-   orbit inclination;
-   orbit radius.

The Planet should remain a low-priority area during the initial visual
development.

## 6. Rendering/composition considerations

The current Black Hole implementation contains ray-based/lensing logic
and an accretion-disc system.

The current Planet implementation is analytically rendered from the view
ray and uses its own world-space orbital position.

This means future effects must account for:

-   raw versus lensed ray directions;
-   world-space versus screen-space positioning;
-   composition order;
-   temporal stability;
-   interaction with existing Photon bloom/exposure systems.

Do not assume that a screen-space effect is automatically equivalent to
a world-space effect.

## 7. Bloom/exposure

Photon already contains a multi-stage bloom pipeline in the program
passes.

Future Black Hole brightness work should first determine how the
existing Photon bloom/exposure pipeline responds to the Black Hole's
emitted values before introducing a separate bloom system.

The preferred approach is to integrate with Photon's existing rendering
pipeline when technically appropriate rather than duplicating it.

## 8. Planned future systems

The architecture will eventually need to accommodate:

-   sky color/space variant;
-   dense stars;
-   enhanced Black Hole emission;
-   gravitational shadow/light interaction;
-   volumetric nebula;
-   final cross-system integration.

The exact file locations should be decided after tracing the current
rendering path rather than being predetermined.

## 9. Architecture rule

Do not create a new rendering subsystem simply because an effect can be
implemented in isolation.

First determine whether Photon already provides an appropriate pipeline,
buffer, include or post-processing stage.

New infrastructure should have a clear reason.
