# Hot Springs — User's Guide

## Overview

Adds warm, hot, and scalding spring water, steam effects, vent blocks, a temperature gradient system, and a custom hot spring biome to Luanti worlds. Generated in hot climate areas with high humidity.

## Water Types

The mod provides 6 liquid nodes across 3 temperature tiers, plus the vent block heat source:

| Node | Temperature | Damage | Notes |
|---|---|---|---|
| `hot_springs:warm_water_source` | Warm — safe | 0 DPS (configurable) | Pool surface, low heat |
| `hot_springs:warm_water_flowing` | Warm — safe | 0 DPS (configurable) | Flowing edges of warm zones |
| `hot_springs:hot_water_source` | Hot — moderate | 0 DPS (configurable) | Mid-depth pool water |
| `hot_springs:hot_water_flowing` | Hot — moderate | 0 DPS (configurable) | Flowing edges of hot zones |
| `hot_springs:scalding_water_source` | Scalding — dangerous | 3.0 DPS (configurable) | Deep pool water, highest heat |
| `hot_springs:scalding_water_flowing` | Scalding — dangerous | 3.0 DPS (configurable) | Flowing edges of scalding zones |
| `hot_springs:vent_block` | Heat source | — | Emits temperature to nearby water |

## Migration

If you are updating from an older version that used the legacy node names (`hot_springs:hot_water_source`, `hot_springs:hot_water_flowing`, `hot_springs:boiling_water_source`), run the following chat command to migrate existing blocks in your world:

```
/hot_springs_migrate
```

This command scans the world and replaces:
- `hot_springs:hot_water_source` (legacy) → `hot_springs:warm_water_source`
- `hot_springs:hot_water_flowing` (legacy) → `hot_springs:warm_water_flowing`
- `hot_springs:boiling_water_source` (legacy) → `hot_springs:scalding_water_source`

## Effects

- **Steam particles** rise from hot and scalding water source nodes when air is above them. Particle amount, size, lifetime, glow, and frequency are adjustable via settings.
- **Scalding warning**: When you enter scalding water, a hiss sound plays, a steam burst appears, and a chat message warns you. This repeats every 10 seconds (configurable) if you stay in. Creative-mode players are exempt.
- **Thermal damage**: Scalding water deals damage per second. Warm and hot water are safe by default. Armor reduces damage normally.
- **Drowning**: Drowning works normally in all hot spring pools. A setting can disable drowning.
- **Temperature Gradient**: Vent blocks heat nearby water. The temperature falls off linearly with distance: each node away from the vent loses `hot_springs_temp_gradient` degrees. The nearest vent within `hot_springs_vent_scan_radius` determines pool temperature.

## Settings

All settings are declared in `settingtypes.txt` and appear in Luanti's settings menu. They take effect after a server restart.

### Steam Particles
- Master enable/disable toggle
- Min/max amount per spawn, size, expiration time
- Glow level (0–14)
- Separate ABM interval and chance for source and flowing nodes

### Scalding Warning
- Enable/disable the chat message independently
- Cooldown between repeat warnings (seconds, default 10, minimum 1)

### Thermal Damage
- Damage per second for each water node type (warm, hot, scalding — source and flowing)
- Drowning prevention toggle (default: off — normal drowning)

### Variable Temperature
- Temperature class thresholds (warm min, hot min, scalding min)
- Defaults: warm ≥ 30, hot ≥ 50, scalding ≥ 80
- Public API: `hot_springs.get_pool_temperature(node_name, pos)` and `hot_springs.classify_temperature(temp)` available for other mods
- When `pos` is provided, `get_pool_temperature` checks: (1) per-node metadata, (2) nearest vent within `vent_scan_radius` with temperature gradient falloff, (3) static node mapping fallback.

### Temperature Gradient
- `hot_springs_temp_gradient` (float, default 5.0) — Temperature lost per node of distance from the nearest vent block.
- `hot_springs_vent_scan_radius` (int, default 20) — Maximum radius (in nodes) to search for vent blocks when computing pool temperature.
- `hot_springs_vent_spread_radius` (int, default 200, max 225) — Radius to scan for existing vents before placing a new one during worldgen. Scans a 3D volume which must stay under 150M nodes; 225 is the safe maximum with default chunk size.
- `hot_springs_vent_max_count` (int, default 2) — Maximum number of vents allowed within `vent_spread_radius` before new vent placement is skipped.

### Healing
- `hot_springs_heal_warm_rate` (float, default 0.5) — HP per second restored in warm water after a 1-second grace period.
- `hot_springs_heal_hot_rate` (float, default 1.0) — HP per second restored in hot water after a 1-second grace period.

## Troubleshooting

- If the mod does not load, check the Luanti log for missing node or texture errors.
- If behavior looks wrong after updating, run `/hot_springs_migrate` to update legacy nodes, then compare your world settings and mod version.
- Worldgen changes should be tested on a fresh world.
