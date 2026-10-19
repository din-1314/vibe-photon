# Photon Cinematic Concept --- Project Rules

## 1. Core rule

Do not restart or recreate the project when an existing implementation
can be corrected or extended.

Prefer targeted, incremental changes.

## 2. Workspace boundaries

The active project is `workspace/`.

The `fail/` directory contains abandoned prototypes. Do not modify,
replace, merge, or borrow code from `fail/` unless explicitly
instructed.

The rest of the project root contains documentation, references, builds,
and backups.

## 3. Before modifying code

For every substantial task:

1.  Inspect the relevant existing files.
2.  Trace how the affected feature is compiled and composed.
3.  Identify the smallest appropriate change.
4.  Check for interactions with existing systems.
5.  Explain important architectural implications before making a large
    refactor.

Do not assume that a file name describes the complete rendering path.

## 4. Preserve working behavior

Do not remove existing functionality merely to make an implementation
simpler.

Do not replace a working subsystem with a new implementation unless
there is a demonstrated reason.

Do not make unrelated formatting or architectural changes during a
focused task.

## 5. One major visual system at a time

Development should proceed in controlled stages.

The current planned order is:

1.  Study the whole project and existing architecture.
2.  Reorganize the Concept menu and Black Hole/Planet scope controls.
3.  Establish the dark/space-black sky variant.
4.  Improve the star field.
5.  Refine Black Hole brightness.
6.  Develop the gravitational shadow/light interaction.
7.  Develop the volumetric nebula.
8.  Integrate and balance all systems.

This order can change if code analysis shows a technical dependency, but
changes to the order should be intentional.

## 6. Black Hole brightness

The supplied IterationT screenshot is the primary visual reference for
this specific feature.

The target is not simply a brighter ring.

The target is a highly intense, almost blinding emission around the
Black Hole, with a strong halo/bloom-like spread that makes the
surrounding space appear affected by the emitted light.

The dark event-horizon region must remain visually distinct from the
luminous region.

## 7. Visual references

IterationT is a reference, not a template to copy.

Use references to understand:

-   visual hierarchy;
-   light behavior;
-   composition;
-   gravitational/lensing appearance;
-   atmosphere;
-   perceived scale.

Do not copy another shader's implementation wholesale.

## 8. Flickering

Flickering is a known risk, especially for future gravitational
shadow/light work.

If a new implementation introduces flickering:

-   stop and diagnose the source;
-   determine whether it is temporal instability, precision, sampling,
    reprojection, accumulation, coordinate instability, or another
    cause;
-   fix the underlying problem rather than hiding it with arbitrary
    smoothing.

Do not stack additional effects on top of an unstable implementation.

## 9. Planet

The existing Planet system is not a current priority.

Do not unnecessarily redesign it while working on unrelated systems.

It should remain compatible with the Black Hole and future atmospheric
effects.

## 10. Integration

New systems must eventually interact coherently.

Avoid treating the Black Hole, stars, nebula, planet, sky and
gravitational effects as unrelated overlays.

The final goal is a single believable environment.

## 11. Configuration

User-facing controls should be clear and logically grouped.

The Concept category should use the project's purple visual identity.

Black Hole and Planet should have independent enable/scope controls.

Where useful, controls should support:

-   End only;
-   Overworld only;
-   Both.

The exact configuration architecture should be confirmed after reviewing
the current Photon settings system.

## 12. Validation

After a meaningful change:

-   verify compilation;
-   verify the affected world(s);
-   verify the feature with relevant toggles;
-   check for regressions in unrelated systems;
-   compare against the intended visual reference.

Do not declare a visual change successful merely because it compiles.

## 13. Communication

When working autonomously, report:

-   what was inspected;
-   what was changed;
-   why it was changed;
-   what files were affected;
-   what remains uncertain;
-   what should be tested next.

If an architectural decision is uncertain, stop and ask rather than
making a large irreversible change.

## 14. Do not destroy history

Never delete previous working states to make room for a new experiment.

Use the project's build/backup workflow.

A failed experiment is information; preserve it when it is useful.

## Learning Mode

This project is also a practical learning environment for the developer.
The developer is a beginner in programming, GLSL, and shader development.

When implementing a change, explain in accessible language:
- what is being changed;
- why the change is necessary;
- what the relevant code does;
- which programming/shader concepts are involved;
- what should be observed during testing.

Do not assume prior knowledge of GLSL, rendering pipelines, coordinate spaces, raymarching, or shader architecture.

The developer may pause an implementation at any point to ask questions or clarify a decision. Stopping and asking is preferred to making an uncertain assumption.

## Visual Reference Requests

Visual references are part of the normal development workflow.

If a visual decision would benefit from a screenshot, reference image, video frame, or other visual example that is not already available in the project/reference folder or current conversation, stop before implementing that visual decision and ask the developer:

> Do you have a visual reference for this? If so, please send it. If not, I can proceed based on the current visual direction.

Ask for a visual reference whenever it would materially improve accuracy, composition, lighting, color, scale, atmosphere, shape, motion, or overall visual matching. Do not invent a precise visual target when a reference would be more appropriate.

This rule applies throughout the project, not only during major visual milestones.

## Build, ZIP, and Testing Workflow

The active workspace is the development source, not the folder used directly for Minecraft testing.

After **every implementation change**, the developer expects a ZIP build immediately. Do not ask the developer to copy the raw `workspace/` folder into Minecraft for testing.

Required workflow:
1. Modify and validate the active project in `workspace/`.
2. Create a ZIP of the current build.
3. Place that ZIP in `builds/testing/`.
4. Give the ZIP a clear versioned name.
5. The developer tests the ZIP in Minecraft.
6. When a version/base is considered stable, preserve it in `builds/stable/`.

A change is not considered delivered for testing until the corresponding ZIP exists in `builds/testing/`.

The raw `workspace/` remains the editable source and should not be treated as the Minecraft test package.

## Versioning

The project uses a simple incremental development version scheme.

The first project version is:

`v0.1`

Small corrections or follow-up changes within the same milestone use an additional patch component:

`v0.1.1` → `v0.1.2` → `v0.1.3` → ...

When the project moves to a new milestone/feature stage, advance the second component:

`v0.2`

and subsequent corrections become:

`v0.2.1` → `v0.2.2` → ...

Likewise:

`v0.3` → `v0.3.1` → `v0.3.2` → ...

Do not use `0.01` or `0.0.1` as the project's versioning scheme.

Every testing ZIP must use the current version in its filename. Stable builds must preserve the same version identifier.

## Optimization Phase

Optimization is an official project phase, not an afterthought.

After the major visual systems are integrated, the project enters a dedicated optimization phase. The goal is:

**strong visual result + reasonable performance**

Optimization should be evidence-based whenever practical:
- measure frame time/FPS before and after meaningful changes;
- identify the actual expensive passes or systems;
- reduce unnecessary samples;
- use early exits where valid;
- avoid unnecessary raymarching/noise;
- reuse existing Photon systems when appropriate;
- consider the resolution at which a pass runs;
- preserve temporal stability and visual quality.

Do not optimize blindly or sacrifice a major visual feature without understanding its cost. If an optimization materially changes the intended visual result, document the trade-off and discuss it before making that trade-off permanent.

The optimization phase happens before declaring a build stable.


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
