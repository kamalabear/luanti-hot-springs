# Hot Springs — Developer's Guide

## File structure

| File | Purpose |
|---|---|
| `init.lua` | Entry point — node definitions, config, ABMs, warning system, biome registration, migration command |
| `mod.conf` | Mod name, display name, description, depends |
| `settingtypes.txt` | All configurable settings with types, defaults, and safe ranges |
| `textures/` | Water textures (source, flowing, animated variants) and steam particle texture |
| `sounds/` | Sound assets (placeholder — add `hot_springs_hiss.ogg` for the warning sound) |
| `specs/` | Enhancement specifications (status, design, scope per feature) |
| `tests/` | Busted test suites and minetest mock helper |
| `.busted` | Busted test runner configuration |

## Architecture

The mod uses ten conceptual components (CIDs):

| CID | Name | Responsibility |
|---|---|---|
| CID-1 | Mod Config | Reads and validates all settings at init; stores in the `config` table |
| CID-2 | Steam Spawner | Two ABMs that spawn steam particles above source and flowing hot spring water |
| CID-3 | Water Nodes | Defines all 6 hot spring water nodes (warm/hot/scalding, each with source and flowing) and the vent block |
| CID-4 | Warning System | Globalstep-based detection of players in scalding water; dispatches sound, particle, and chat cues with per-player cooldown |
| CID-5 | Temperature API | Position-aware node-to-temperature mapping, `get_pool_temperature(node_name, pos)` and `classify_temperature(temp)` functions with configurable thresholds. When `pos` is provided, checks per-node metadata, nearest vent within `vent_scan_radius` with gradient falloff, then static mapping fallback |
| CID-6 | Biome Registration | Registers the hot spring biome using the current node names |
| CID-7 | Migration Command | Chat command `/hot_springs_migrate` that replaces legacy node names with the current naming scheme |
| CID-8 | Gradient Worldgen | `on_generated` callback that post-processes each chunk: temperature-driven water node replacement via vent falloff |
| CID-9 | Healing System | Globalstep-based health-over-time in warm and hot water with 1s grace period, configurable rates, creative-mode exclusion, and golden glow visual feedback |
| CID-10 | Thermal Biome Transformation | Post-processing stage in the `on_generated` callback that melts snow/ice and grows moss near hot spring water based on temperature class |

## Node naming

| Node | Description |
|---|---|
| `hot_springs:warm_water_source` | Warm spring water (lowest tier, no damage by default) |
| `hot_springs:warm_water_flowing` | Flowing warm spring water (no damage by default) |
| `hot_springs:hot_water_source` | Hot spring water (mid tier, no damage by default) |
| `hot_springs:hot_water_flowing` | Flowing hot spring water (no damage by default) |
| `hot_springs:scalding_water_source` | Scalding spring water (highest tier, 3.0 DPS by default) |
| `hot_springs:scalding_water_flowing` | Flowing scalding spring water (3.0 DPS by default) |
| `hot_springs:vent_block` | Heat source block that emits temperature to nearby water |

## Settings

All setting keys are prefixed with `hot_springs_`. Category groups:

- `hot_springs_steam_*` — Steam particle tuning
- `hot_springs_warning_*` — Scalding warning behavior
- `hot_springs_*_damage` — Damage per second per node type
- `hot_springs_no_drowning` — Drowning prevention toggle
- `hot_springs_temp_*` — Temperature class threshold boundaries
- `hot_springs_temp_gradient` — Temperature lost per node of distance from vent
- `hot_springs_vent_scan_radius` — Radius to search for vent blocks
- `hot_springs_vent_spread_radius` — Wide radius to scan for nearby vents before placing a new one during worldgen
- `hot_springs_vent_max_count` — Maximum vents allowed within that radius
- `hot_springs_heal_*` — Healing rates for warm and hot water

Settings are read at mod init, clamped to safe ranges, and stored in the `config` table. Invalid or missing settings fall back to defaults. Min/max pairs are swapped if inverted.

## Node registration

Water nodes are cloned from `default:water_source` and `default:water_flowing` using a shallow copy to avoid polluting the originals. Each node type gets its own copy so that `damage_per_second`, `drowning`, and `description` are independent.

The vent block is registered independently as a solid node with a `hot = 1` group for temperature gradient scanning.

## Migration

The `/hot_springs_migrate` command performs a bulk node replacement in the world. It scans all loaded blocks and replaces legacy node names with their current equivalents:

| Legacy node | Replacement |
|---|---|
| `hot_springs:hot_water_source` | `hot_springs:warm_water_source` |
| `hot_springs:hot_water_flowing` | `hot_springs:warm_water_flowing` |
| `hot_springs:boiling_water_source` | `hot_springs:scalding_water_source` |

The command reports the total number of replaced nodes. It requires the `server` privilege.

## Test layout

Tests live in `tests/` and use the Busted framework. The mock helper at `tests/helpers/minetest_mock.lua` provides stubs for all Luanti APIs used by the mod.

Run tests:
```bash
busted
```

Total: **111 tests, 0 failures** (all Busted unit tests pass on a mock engine).

### Test files

| File | Coverage |
|---|---|
| `tests/steam_config_spec.lua` | Steam particle settings, ABM cadence, clamping, type coercion (17 tests) |
| `tests/warning_spec.lua` | Warning detection, cooldown, chat toggle, creative skip, multiplayer independence (17 tests) |
| `tests/damage_spec.lua` | Damage values per node, drowning toggle, clamping, load without errors (9 tests) |
| `tests/temperature_spec.lua` | Temperature mapping, classification, thresholds, clamping, API availability, settings declaration (16 tests) |
| `tests/temperature_gradient_spec.lua` | Position-aware temperature, vent gradient falloff, cache invalidation, migration command, vent block registration, gradient worldgen including auto vent placement and integration pipeline (24 tests) |
| `tests/healing_spec.lua` | Warm/hot water healing rates, grace period, scalding exclusion, max health cap, creative exclusion, golden glow visual, leave cleanup (11 tests) |
| `tests/thermal_biome_spec.lua` | Snow/ice melt, dirt_with_snow conversion, radius by temperature class, moss growth probability, scalding exclusion, worldgen-only, non-default protection, flowing water triggering (14 tests) |

## Adding a new setting

1. Add the setting declaration to `settingtypes.txt`
2. Add a default to the `defaults` table (or inline) and a clamp entry to `clamps` if needed
3. Read the setting into `config.*` using `read_float`, `read_int`, or `read_bool`
4. Use `config.*` at the relevant point in the code
5. Add Busted tests for the new setting
6. Update USAGE.md with the new setting
