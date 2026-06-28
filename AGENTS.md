# Hot Springs — Agent Guidelines

## Architecture

A Luanti mod. Entry point is `init.lua`; all logic (config, node definitions, ABMs, warning system, biome registration) lives in that single file. See [DEVELOPMENT.md](DEVELOPMENT.md) for the full developer reference: CID architecture, node naming, settings system, and test layout.

**Companion mods:** None. Depends only on the default base-game water and biome systems.

## Build and Test

The mod has an automated Busted test suite:

```bash
busted
```

Validate changes by running the full suite before committing.

## Conventions

**Documentation:** After every code change, review and update [README.md](README.md), [USAGE.md](USAGE.md), [DEVELOPMENT.md](DEVELOPMENT.md), and relevant spec files in `specs/` as needed. These are the canonical references for users and developers.

**Settings:** Any new config knob must be registered in `settingtypes.txt` and documented in [USAGE.md](USAGE.md). Add Busted tests for new settings.

**Node registration:** Always use `shallow_copy()` when cloning from `default:water_source` or `default:water_flowing` to avoid modifying the originals. Set `damage_per_second` and `drowning` on the copy before calling `minetest.register_node`.

**CIDs:** Respect CID boundaries. Config reads belong in CID-1, node definitions in CID-3, runtime effects in CID-2 or CID-4.

**Spec statuses:** When implementing a spec, change its status from `Draft` to `Implemented` and note any scope differences.
