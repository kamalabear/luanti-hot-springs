# System Overview

The Thermal Biome Transformation system makes hot springs interact with their environment during world generation. It scans newly generated chunks for hot spring water nodes and, based on their temperature class, melts surrounding snow and ice and occasionally grows moss on adjacent stone or dirt. Both effects are purely worldgen-time operations within the existing `on_generated` callback.

# Core Components

## CID-10: Thermal Biome Transformation

**Responsibility:** Apply melt and moss effects during chunk generation after water node replacement.

**Owns:**
- Melt radius mapping (temperature class → radius)
- Melt target node mapping (snow/ice → replacement)
- Moss growth probability gate
- The post-replacement scan over hot spring water positions

**Does NOT own:**
- Temperature classification (delegated to CID-5 API)
- Water node placement or replacement (delegated to CID-8)
- Vent placement or gradient computation (CID-8)
- Runtime effects or ABMs

# System Boundaries

**Inside the system:**
- Scanning of hot spring water nodes within the currently generating chunk
- Replacement of snow, snowblock, dirt_with_snow, ice within the melt radius
- Conversion of stone/dirt to mossy variants at low probability

**Outside the system:**
- Nodes outside the currently generating chunk (not modified)
- Player-placed or non-`default:` nodes (not modified)
- Runtime gameplay or ABMs (never triggered)

# Data Flow

1. **Input:** The set of hot spring water node positions within the chunk, after temperature-driven replacement (CID-8 Stage 1).
2. **Temperature classification:** Each node's replacement name (e.g. `hot_springs:warm_water_source`) implicitly encodes its temperature class, extracted by string parsing. No additional temperature computation needed since replacement is already done.
3. **Melt pass:** For each warm/hot/scalding water node, scan nodes within the class-specific radius. Match nodes against the melt target mapping. Collect replacements.
4. **Moss pass:** For each warm/hot water node, scan adjacent nodes (radius 1). For `default:stone` and `default:dirt`, apply probability gate. Collect replacements.
5. **Output:** Batch node replacements applied via `minetest.set_node`.

# Control Flow

```
on_generated callback triggers
  ↓
CID-8 Stage 0: Vent placement (unchanged)
  ↓
CID-8 Stage 1: Temperature-driven water node replacement (unchanged)
  ↓
CID-10 Stage 2: Thermal Biome Transformation
  ├─ Stage 2a: Melt scan
  │   For each warm/hot/scalding water node in chunk:
  │     Determine melt_radius from temperature class
  │     Find nodes within melt_radius matching melt targets
  │     Queue replacements per R1 mapping
  │
  └─ Stage 2b: Moss scan
      For each warm/hot water node in chunk:
        Find adjacent default:stone / default:dirt nodes
        Apply 5-10% probability gate
        Queue replacements for selected positions
  ↓
Apply all queued node replacements (batch)
```

All stages run sequentially within the single `on_generated` call. No ABMs, no globalsteps, no timers.

# Persistence Model

- **Transient:** None — all state is local to the `on_generated` call.
- **Persistent:** Modified nodes are baked into the map database via `set_node`, surviving server restarts and world reloads automatically.

# Integration Points

- **CID-8 (Gradient Worldgen):** CID-10 runs as a post-processing stage within the same `on_generated` callback, after CID-8 completes its node replacements. It reads the result of CID-8's work (hot spring water positions).
- **CID-5 (Temperature API):** CID-10 uses the node name (which encodes the temperature class after replacement) rather than calling the temperature API, since the replacement has already determined the class.
- **Luanti engine:** Uses `minetest.find_nodes_in_area` for scanning and `minetest.set_node` for modifications, both standard engine APIs already used by CID-8.

# Failure Modes

- **Partial degradation:** If no hot spring water exists in the chunk, CID-10 is a no-op — the system degrades gracefully.
- **Missing default nodes:** If `default:snow`, `default:ice`, etc. are not registered (mod not present), `find_nodes_in_area` returns empty results and no replacement occurs — safe.
- **Max scan volume:** The melt pass scans at most (3 × number_of_water_positions × 3² × 4/3 × π) nodes, which for a typical pool of ~50 water nodes with radius 3 scans at most ~5,600 positions — well within performance bounds.

# Tradeoffs

- **Chunk-boundary clipping (simplicity vs edge perfection):** Melt/moss effects are limited to the generating chunk boundary. A pool at the edge of a chunk may show clipped melt radius. Accepting this keeps the scan simple and avoids modifying already-generated terrain.
- **Post-replacement scan (simplicity vs efficiency):** Scanning all hot spring water nodes after replacement is simpler than integrating into the replacement loop. The overhead is negligible since melt/moss radii are small (1-3 nodes).

# Open Questions

None resolved during architecture.
