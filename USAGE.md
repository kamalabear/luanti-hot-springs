# Hot Springs — User's Guide

## Overview

Adds hot spring water, boiling water, steam effects, and a custom hot spring biome to Luanti worlds. Generated in hot climate areas with high humidity.

## Water Types

| Node | Where it generates | Surface temperature | Damage |
|---|---|---|---|
| `hot_springs:hot_water_source` | Pool surface (top 2 layers) | Warm — safe | 0 DPS (configurable) |
| `hot_springs:hot_water_flowing` | Flowing edges of pools | Warm — safe | 0 DPS (configurable) |
| `hot_springs:boiling_water_source` | Deep water (below top 2 layers) | Scalding — dangerous | 3.0 DPS (configurable) |

## Effects

- **Steam particles** rise from hot and boiling water when air is above them. Particle amount, size, lifetime, glow, and frequency are adjustable via settings.
- **Scalding warning**: When you enter boiling water, a hiss sound plays, a steam burst appears, and a chat message warns you. This repeats every 10 seconds (configurable) if you stay in. Creative-mode players are exempt.
- **Thermal damage**: Boiling water deals damage per second. Surface hot water is safe by default. Armor reduces damage normally.
- **Drowning**: Drowning works normally in all hot spring pools. A setting can disable drowning.

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
- Damage per second for hot water source, flowing hot water, and boiling water source
- Drowning prevention toggle (default: off — normal drowning)

## Troubleshooting

- If the mod does not load, check the Luanti log for missing node or texture errors.
- If behavior looks wrong after updating, compare your world settings and mod version.
- Worldgen changes should be tested on a fresh world.
