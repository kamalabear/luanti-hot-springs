# luanti-hot-springs
A hot springs mod for Luanti

## User Guide

### What It Does

Adds hot spring water, boiling water, steam effects, and a custom hot spring biome.

### Install And Enable

1. Copy the mod folder into Luanti's `mods` directory.
2. Enable the mod in your world.
3. Make sure the required base game content is available.

### How To Use

- Explore generated hot spring biomes to find the custom water nodes.
- Hot water provides the themed spring visual effect.
- Boiling water is dangerous and deals damage.

### Settings And Tuning

All tunable behavior is exposed in `settingtypes.txt` and appears in Luanti's settings menu:

**Steam particles:** amount, size, lifetime, glow, ABM cadence, and a master toggle.
**Scalding warning:** enable/disable chat message, cooldown duration.
**Thermal damage:** damage per second for hot water, flowing water, and boiling water; drowning prevention toggle.

### Compatibility Notes

- This mod depends on the default base-game water and biome systems.
- Worldgen changes should be tested on a fresh world and an existing world.

### Troubleshooting

- If the mod does not load, check the Luanti log for missing node or texture errors.
- If behavior looks wrong after updating, compare your world settings and mod version.

## Contributing

- See CONTRIBUTING.md for coding standards and workflow agreements.

## Future Enhancements

Natural hot spring biome generation already exists. Future work should focus on richer interactions, visuals, and gameplay around those generated areas.

### Enhancement History

- ✅ **Configurable steam intensity** — Settings for particle amount, size, lifetime, glow, and ABM cadence.
- ✅ **Scalding warning effects** — Pre-damage cues (particles, sound, chat message) when entering dangerous water.
- ✅ **Thermal damage** — Configurable damage per second for each hot spring water type, with drowning toggle.

### Near-term Priorities

- **Ambient thermal soundscape** — Play subtle bubbling and hissing sounds near hot and boiling pools.
- **Variable temperature** — Assign each pool a temperature value that varies between pools.
- **Temperature-based water color** — Tint pool water to reflect temperature (e.g. cool blue -> warm green -> hot orange/red), using one or more distinct color variants.
- **Healing + heat damage balancing** — Implement healing and very-hot damage together, with rates tuned as one risk/reward system.

### Long-term Ideas

- **Geothermal geyser events** — Trigger periodic eruptions that launch steam and water upward for dramatic, dynamic pools.
- **Biome-exclusive resources** — Add rare geothermal materials that generate in hot spring areas to reward exploration.
- **Mineral edge decoration** — Generate mineral-stained blocks around pool rims for stronger visual identity.
- **Thermal energy gameplay hooks** — Introduce collectors, fuels, or crafting inputs powered by hot spring heat.
- **Terraced pool variants** — Generate layered, multi-level hot spring formations for more varied terrain.
