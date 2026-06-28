# luanti-hot-springs

Adds hot spring water, boiling water, steam effects, and a custom hot spring biome to Luanti.

---

## Dependencies

- **Required:** `default` (base game water and biome systems)

---

## Documentation

- [User's Guide](USAGE.md) — water types, effects, settings, troubleshooting
- [Developer's Guide](DEVELOPMENT.md) — file structure, CID architecture, node naming, settings system, test layout

---

## Enhancement History

- ✅ **Configurable steam intensity** — Settings for particle amount, size, lifetime, glow, and ABM cadence.
- ✅ **Scalding warning effects** — Pre-damage cues (particles, sound, chat message) when entering dangerous water.
- ✅ **Thermal damage** — Configurable damage per second for each hot spring water type, with drowning toggle.

### Near-term Priorities

- **Ambient thermal soundscape** — Play subtle bubbling and hissing sounds near hot and boiling pools.
- **Variable temperature** — Assign each pool a temperature value that varies between pools.
- **Temperature-based water color** — Tint pool water to reflect temperature.
- **Healing + heat damage balancing** — Implement healing and very-hot damage together, with rates tuned as one risk/reward system.

### Long-term Ideas

- **Geothermal geyser events** — Trigger periodic eruptions that launch steam and water upward.
- **Biome-exclusive resources** — Add rare geothermal materials in hot spring areas.
- **Mineral edge decoration** — Generate mineral-stained blocks around pool rims.
- **Thermal energy gameplay hooks** — Introduce collectors, fuels, or crafting inputs powered by hot spring heat.
- **Terraced pool variants** — Generate layered, multi-level hot spring formations.

---

## License

See [LICENSE](LICENSE).
