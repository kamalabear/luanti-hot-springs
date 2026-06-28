# Goal

Add a CID-10 post-processing stage to the existing `on_generated` callback that melts surrounding snow and ice, and occasionally grows moss adjacent to warm/hot spring water nodes after temperature-driven replacement.

# Scope

**Included:**
- Melt scan over warm/hot/scalding water nodes (source + flowing) with temperature-class-based radius
- Moss growth scan over warm/hot water nodes with 5-10% probability
- Both effects applied within the current chunk boundaries only
- Only `default:*` namespace nodes modified

**Excluded:**
- Runtime ABMs or globalsteps
- Biome alteration or mapblock rewriting
- Plant growth or tree spawning
- Player-placed block detection (name check only)

# Execution Plan

## Step 1: Define melt target table and radius mapping

- **Description:** Add a local table `THERMAL_MELT_TARGETS` mapping source node names to replacement names. Also add `MELT_RADIUS` table mapping temperature class strings to integer radius values.
- **Purpose:** Centralized constants for the melt scan, easy to review and test.
- **Implements RIDs:** R1, R2
- **Affects CIDs:** CID-10
- **Respects DIDs:** Worldgen-only, default-nodes-only
- **Risks:** None

## Step 2: Add CID-10 melt + moss stage to `on_generated` callback

- **Description:** After the existing Stage 1 node replacement loop in `on_generated`, add a Stage 2 that:
  1. Builds a list of hot spring water positions in the chunk (warm/hot/scalding, source + flowing).
  2. For each position, determines temperature class from node name.
  3. Melt pass: Scans within `MELT_RADIUS[class]` for any node in `THERMAL_MELT_TARGETS` and queues replacement.
  4. Moss pass: For warm/hot only, scans adjacent nodes (radius 1) for `default:stone`/`default:dirt`, applies `math.random()` probability gate, queues conversion.
  5. Applies all queued replacements.
- **Purpose:** The core implementation — all requirements in one cohesive stage.
- **Implements RIDs:** R1, R2, R3, R4, R5, R6
- **Affects CIDs:** CID-10 (new), CID-8 (extends existing callback)
- **Respects DIDs:** Worldgen-only, default-nodes-only, chunk-boundary clipping
- **Risks:** PERF — scanning within small radii (1-3) from each water node is O(n * r³) where n is water nodes and r is radius. For a typical pool of ~50 nodes with r=3, at most ~5,600 neighbors scanned — negligible.

# System Impact Overview

- **CID-8 (Gradient Worldgen):** Extended — the `on_generated` callback gains a Stage 2 after the existing node replacement loop.
- **CID-10 (Thermal Biome Transformation):** New conceptual component. All logic resides in the Stage 2 addition.
- **Unchanged:** CID-1 (config), CID-3 (node definitions), CID-4 (warning/ABM), CID-5 (temperature API), CID-6 (biomes), CID-7 (migration), CID-9 (healing).
- **Behavior change:** Hot spring pools now visibly melt adjacent snow/ice and grow moss during worldgen.

# Traceability Map

```
R1 → Step 1, Step 2 (melt target table + melt scan)
R2 → Step 1, Step 2 (radius mapping + melt scan)
R3 → Step 2 (moss scan)
R4 → Step 2 (skip moss for scalding)
R5 → Step 2 (inside on_generated only)
R6 → Step 2 (only default:* targets)

Step 1 → R1, R2
Step 2 → R1, R2, R3, R4, R5, R6
```

# Validation Plan

- AC-R1: Place warm water source next to `default:snow` in test → snow becomes `air`.
- AC-R2: Place warm water source next to `default:dirt_with_snow` → becomes `default:dirt`.
- AC-R3: Place hot water source next to `default:snowblock` → becomes `default:dirt` within 2 nodes.
- AC-R4: Place scalding water source next to `default:ice` → becomes `default:water_source` within 3 nodes.
- AC-R5: Place warm water source next to `default:stone` → after many trials, ~5-10% become `default:mossycobble`.
- AC-R6: Place scalding water source next to `default:stone` → never converts to moss.
- AC-R7: Verify no ABM or globalstep registered for the effect.

# Risks & Constraints

- **PERF (minor):** The scan loops over each water node and its neighbors within radius 1-3. With ~50 pool nodes and r=3, this is ~5,600 neighbor checks per chunk with a pool — trivial.
- **COMP:** No compatibility risks — only `default:*` nodes are modified, and the scan is purely local to the chunk.

# Dependencies

- **CID-8:** Must complete Stage 1 (temperature-driven replacement) before CID-10 Stage 2 runs.
- **CID-5:** Implicit dependency — the temperature class is read from the node name that CID-8 produced.

# Follow-up Questions

None.
