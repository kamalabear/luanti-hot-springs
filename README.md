# luanti-hot-springs

Adds warm, hot, and scalding spring water, steam effects, vent blocks, a temperature gradient system, and a custom hot spring biome to Luanti.

---

## Features

- **Temperature Gradient System** — Vent blocks emit heat that dissipates over distance, creating pools with distinct warm, hot, and scalding zones. Each temperature has source and flowing node variants (6 liquid nodes total + the vent block).

---

## Dependencies

- **Required:** `default` (base game water and biome systems)

---

## Documentation

- [User's Guide](USAGE.md) — water types, effects, settings, troubleshooting, migration command
- [Developer's Guide](DEVELOPMENT.md) — file structure, CID architecture, node naming, settings system, test layout

---

## Enhancement History

- ✅ **Temperature Gradient System** — Vent blocks, 3 temperature tiers (warm/hot/scalding), distance-based heat falloff, migration command, position-aware API.
- ✅ **Configurable steam intensity** — Settings for particle amount, size, lifetime, glow, and ABM cadence.
- ✅ **Scalding warning effects** — Pre-damage cues (particles, sound, chat message) when entering dangerous water.
- ✅ **Thermal damage** — Configurable damage per second for each hot spring water type, with drowning toggle.
- ✅ **Variable temperature** — Centralized temperature model with query and classification API, configurable class thresholds.
- ✅ **Healing hot spring water** — Warm water heals at 0.5 HP/s, hot water at 1.0 HP/s, with 1s grace period, configurable rates, and golden glow feedback.

### Near-term Priorities

- **Temperature-based water color** — Tint pool water to reflect temperature.
- **Ambient thermal soundscape** — Play subtle bubbling and hissing sounds near hot and scalding pools.

### Long-term Ideas

- **Geothermal geyser events** — Trigger periodic eruptions that launch steam and water upward.
- **Biome-exclusive resources** — Add rare geothermal materials in hot spring areas.
- **Mineral edge decoration** — Generate mineral-stained blocks around pool rims.
- **Thermal energy gameplay hooks** — Introduce collectors, fuels, or crafting inputs powered by hot spring heat.
- **Terraced pool variants** — Generate layered, multi-level hot spring formations.

---

## License

See [LICENSE](LICENSE).
