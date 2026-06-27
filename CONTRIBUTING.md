# Contributing to luanti-hot-springs

Use the workspace-wide guide as primary reference:

- ../CONTRIBUTING.md

This file adds mod-specific agreements.

## Mod-Specific Rules

- Keep node names under the `hot_springs:` namespace.
- Prefer configuration knobs for visuals and damage tuning.
- Avoid noisy logging in recurring callbacks (ABMs/timers).
- Keep steam, damage, healing, and color behavior independently testable.
- Update specs in `specs/` for any behavior or balancing change.

## Mod-Specific Done Checklist

- No startup errors in Luanti logs.
- Hot water and boiling water behavior validated in-game.
- Steam effects tested for both source and flowing nodes.
- Readme/spec updated when behavior or settings change.
- Lua lint passes with .luacheckrc in this mod folder.
- PR uses workspace template at ../.github/PULL_REQUEST_TEMPLATE.md.
