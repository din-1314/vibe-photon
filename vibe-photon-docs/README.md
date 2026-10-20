# Photon Cinematic Concept

## Status

Initial documentation baseline.

The active shader source is maintained in the `workspace/` directory at
the project root.

## Project purpose

Photon Cinematic Concept is a visual concept/edit built on top of Photon
Shader.

The project aims to develop a cinematic End/space presentation while
preserving Photon's visual identity where desired and introducing
original visual systems inspired by references such as IterationT.

The IterationT reference is a visual and technical study reference. The
project should not become a copy of IterationT.

## Current baseline

The current workspace already contains:

-   A Black Hole system.
-   A Planet system.
-   Existing Photon integration for these systems.
-   Configuration and menu entries for the existing systems.

These systems are the starting point, not the final result.

## Planned visual direction

The concept currently includes:

1.  Two atmospheric variants:
    -   a dark/space-black variant;
    -   a Photon-purple variant.
2.  A highly luminous, almost blinding Black Hole brightness based on
    the supplied IterationT visual reference.
3.  Dense stars covering the full visible space/sky, including the
    Void-facing area.
4.  A gravitationally stretched shadow/light interaction associated with
    the Black Hole and Planet.
5.  A volumetric 3D nebula integrated through the sky/space and Void.
6.  Strong interaction between all systems so they read as one
    environment instead of independent layers.

## Development philosophy

Development is incremental.

Before implementing a major system, the current codebase and rendering
path should be understood. Existing working systems should be preserved
unless a change explicitly requires modifying them.

The project should be tested after each major stage.

## Project directories

-   `workspace/` --- active shader source.
-   `fail/` --- previous prototype(s) that were abandoned; reference
    only unless explicitly requested.
-   `docs/` --- project documentation.
-   `references/` --- visual and technical references.
-   `builds/` --- generated test and stable builds.
-   `backups/` --- explicit snapshots of stable states.

## Development Workflow

The active source is `workspace/`. Minecraft testing is performed from versioned ZIP builds in `builds/testing/`, never by copying the raw workspace into Minecraft.

Every implementation change produces a new ZIP immediately. Once a version is validated and treated as a stable base, it is preserved under `builds/stable/`.

Versioning starts at `v0.1`. Corrections within the same milestone use `v0.1.1`, `v0.1.2`, etc. A new milestone advances to `v0.2`, then `v0.2.1`, and so on.

The project also operates in Learning Mode: implementation should be accompanied by beginner-friendly explanations, and the developer should be asked for a visual reference whenever an important visual decision cannot be specified accurately from the existing references.

## Development Phases

The project should progress through intentional phases rather than one giant implementation:

1. Project analysis and preparation
2. Concept menu/settings organization
3. Deep Space / dark End sky
4. Dense star field
5. Black Hole visual refinement
6. Gravitational interaction and stability
7. Volumetric nebula
8. Full visual integration
9. **Optimization**
10. Final validation
11. Stable build

The order may change when code dependencies justify it, but changes to the order should be intentional and explained.

Each phase should be developed in small, testable steps. When a phase is working, preserve it before moving on.
