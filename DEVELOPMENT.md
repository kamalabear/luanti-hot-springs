# Hot Springs — Developer's Guide

## File structure

| File | Purpose |
|---|---|
| `init.lua` | Entry point — node definitions, config, ABMs, warning system, biome registration |
| `mod.conf` | Mod name, display name, description, depends |
| `settingtypes.txt` | All configurable settings with types, defaults, and safe ranges |
| `textures/` | Water textures (source, flowing, animated variants) and steam particle texture |
| `sounds/` | Sound assets (placeholder — add `hot_springs_hiss.ogg` for the warning sound) |
| `specs/` | Enhancement specifications (status, design, scope per feature) |
| `tests/` | Busted test suites and minetest mock helper |
| `.busted` | Busted test runner configuration |

## Architecture

The mod uses four conceptual components (CIDs):

| CID | Name | Responsibility |
|---|---|---|
| CID-1 | Mod Config | Reads and validates all settings at init; stores in the `config` table |
| CID-2 | Steam Spawner | Two ABMs that spawn steam particles above source and flowing hot water |
| CID-3 | Water Nodes | Defines all hot spring water nodes (hot_water_source, hot_water_flowing, boiling_water_source) |
| CID-4 | Warning System | Globalstep-based detection of players in boiling water; dispatches sound, particle, and chat cues with per-player cooldown |

## Node naming

| Node | Description |
|---|---|
| `hot_springs:hot_water_source` | Surface hot spring water (no damage by default) |
| `hot_springs:hot_water_flowing` | Flowing hot spring water (no damage by default) |
| `hot_springs:boiling_water_source` | Deep boiling water (3.0 DPS by default) |

## Settings

All setting keys are prefixed with `hot_springs_`. Category groups:

- `hot_springs_steam_*` — Steam particle tuning
- `hot_springs_warning_*` — Scalding warning behavior
- `hot_springs_*_damage` — Damage per second per node type
- `hot_springs_no_drowning` — Drowning prevention toggle

Settings are read at mod init, clamped to safe ranges, and stored in the `config` table. Invalid or missing settings fall back to defaults. Min/max pairs are swapped if inverted.

## Node registration

Water nodes are cloned from `default:water_source` and `default:water_flowing` using a shallow copy to avoid polluting the originals. Each node type gets its own copy so that `damage_per_second`, `drowning`, and `description` are independent.

## Test layout

Tests live in `tests/` and use the Busted framework. The mock helper at `tests/helpers/minetest_mock.lua` provides stubs for all Luanti APIs used by the mod.

Run tests:
```bash
busted
```

### Test files

| File | Coverage |
|---|---|
| `tests/steam_config_spec.lua` | Steam particle settings, ABM cadence, clamping, type coercion (17 tests) |
| `tests/warning_spec.lua` | Warning detection, cooldown, chat toggle, creative skip, multiplayer independence (17 tests) |
| `tests/damage_spec.lua` | Damage values per node, drowning toggle, clamping, load without errors (9 tests) |

## Adding a new setting

1. Add the setting declaration to `settingtypes.txt`
2. Add a default to the `defaults` table (or inline) and a clamp entry to `clamps` if needed
3. Read the setting into `config.*` using `read_float`, `read_int`, or `read_bool`
4. Use `config.*` at the relevant point in the code
5. Add Busted tests for the new setting
6. Update USAGE.md with the new setting
