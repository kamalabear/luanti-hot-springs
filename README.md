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

- Steam behavior and future balance changes should be controlled through settings when added.
- See `settingtypes.txt` if new configurable behavior is introduced.

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

### Near-term Priorities

- **Configurable steam intensity** — Add settings for particle amount, size, and frequency so servers can tune visuals and performance.
- **Scalding warning effects** — Add pre-damage cues (particles, sounds, or status feedback) when players enter dangerous water.
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
