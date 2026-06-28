# Problem Statement

Hot spring pools appear in cold biomes with snow and ice right up to the water's edge, breaking immersion. The heat from the spring should visibly affect the surrounding environment — melting snow and ice nearby, and occasionally encouraging moss growth on adjacent stone — making the biome feel alive and reactive.

Server admins and world builders want hot springs to integrate naturally into the landscape without manual terraforming.

# User Stories

- As a **player**, I want hot springs in snowy areas to visibly melt surrounding snow and ice so the environment feels physically consistent.
- As a **player**, I want moss patches to occasionally appear near warm pool edges so the area feels aged and organic.
- As a **server admin**, I want both effects to be worldgen-only so there is no runtime performance cost.

# Functional Requirements

**R1 (Melt target mapping):** During worldgen, the mod must replace nodes within the melt radius of warm, hot, or scalding spring water (source and flowing) according to the following mapping:
  - `default:snow` → set to `air`
  - `default:snowblock` → `default:dirt`
  - `default:dirt_with_snow` → `default:dirt`
  - `default:ice` → `default:water_source`

**R2 (Melt radius by temperature):** The mod must apply the melt effect in a radius scaled by water temperature class:
  - Warm water: 1-node radius
  - Hot water: 2-node radius
  - Scalding water: 3-node radius

**R3 (Moss growth):** The mod must, at worldgen time, convert exposed `default:stone` or `default:dirt` nodes adjacent to warm or hot spring water (source or flowing) to `default:mossycobble` or `default:dirt_with_grass` respectively, with a probability of approximately 25%.

**R4 (Scalding exclusion for moss):** The mod must not apply moss growth near scalding water nodes.

**R5 (Worldgen-only):** The mod must only apply melt and moss effects during chunk generation (`on_generated`), not via runtime ABMs or globalsteps.

**R6 (Player-placed protection):** The mod must only modify nodes whose names start with `default:` to avoid altering player-placed or mod-added blocks.

# Non-Functional Requirements

- The combined melt + moss scan must not add more than 5% to the existing `on_generated` execution time.
- The system must behave identically in singleplayer and multiplayer.
- Effects must persist across server restarts and world reloads since they modify mapblocks permanently.

# Acceptance Criteria

**AC-R1:** Given a warm water source node next to `default:snow`, the snow node is set to `air` within 1 node of the water.
**AC-R2:** Given a warm water source node next to `default:dirt_with_snow`, the `dirt_with_snow` is replaced with `default:dirt` within 1 node.
**AC-R3:** Given a hot water source node next to `default:snowblock`, the snowblock is replaced with `default:dirt` within 2 nodes.
**AC-R4:** Given a scalding water source node next to `default:ice`, the ice is replaced with `default:water_source` within 3 nodes.
**AC-R5:** Given a warm water source with adjacent `default:stone`, there is a nonzero chance the stone becomes `default:mossycobble` and less than 100% chance.
**AC-R6:** Given a scalding water source with adjacent `default:stone`, the stone is never converted to moss.
**AC-R7:** Given the effect is triggered during worldgen only, no ABM or globalstep fires these conversions.

**BUSTED_HINT:**
- describe("Thermal Biome Transformation (CID-10)")
  - it("R1: should melt snow adjacent to warm water")
  - it("R1: should convert dirt_with_snow to dirt")
  - it("R1: should convert snowblock to dirt")
  - it("R1: should convert ice to water_source")
  - it("R2: should use radius 1 for warm, 2 for hot, 3 for scalding")
  - it("R3: should grow moss on stone adjacent to warm/hot water at 5-10% prob")
  - it("R4: should not grow moss near scalding water")
  - it("R5: should not fire outside on_generated")
  - it("R6: should not modify non-default nodes")

# Open Questions

(Resolved — all confirmed.)

# Mod Compatibility & Balance Constraints

- The feature modifies worldgen-only, so it cannot conflict with runtime gameplay mods.
- Moss growth is probabilistic and low-density, so it does not affect resource balance.
- Snow-to-dirt conversion is cosmetic and has no gameplay economy impact.
- All node replacements target `default:*` namespaced nodes, ensuring no other mod's custom nodes are affected.
