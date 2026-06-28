# Problem Statement

Hot spring pools can grow arbitrarily large when a high-temperature vent meets a low gradient, creating pools that stretch across hundreds of blocks. These oversized pools look unnatural and dominate the landscape instead of appearing as localized thermal features. Players and world builders need predictable, contained pool sizes.

# User Stories

- As a **player**, I want hot spring pools to be visibly contained near their vent so they feel like localized geothermal features rather than continent-spanning biomes.
- As a **server admin**, I want to control the maximum pool radius so I can tune world generation to my preferred scale.

# Functional Requirements

**R1 (Pool radius limit):** During worldgen, the mod must not convert water nodes to hot spring variants if they are more than `hot_springs_pool_max_radius` nodes from the nearest vent block.

**R2 (Configurable radius):** The mod must read the pool radius limit from a setting (`hot_springs_pool_max_radius`) with a default value of 25, a minimum of 1, and no maximum.

**R3 (Migration unaffected):** The `/hot_springs_migrate` chat command must continue to convert all legacy nodes regardless of distance from any vent.

# Non-Functional Requirements

- The distance check must add negligible overhead to the existing `on_generated` callback (the vent-to-water distance is already computed for temperature falloff).
- The setting must appear in Luanti's settings UI via `settingtypes.txt`.

# Acceptance Criteria

**AC-R1:** Given a vent at temperature 100°C, a gradient of 0.1, and a pool max radius of 25, water 30 blocks from the vent is not converted to any hot spring variant.
**AC-R2:** Given a vent and water within 25 blocks, the water is still classified by temperature as before (the radius cap does not override the gradient logic, only limits its range).
**AC-R3:** Given `/hot_springs_migrate` is run, water beyond the pool radius is still migrated.

**BUSTED_HINT:**
- describe("Pool size limit")
  - it("R1: should not convert water beyond pool_max_radius")
  - it("R1: should still convert water within pool_max_radius")
  - it("R2: should read pool_max_radius from settings")
  - it("R3: should not affect migration command")

# Open Questions

None.

# Mod Compatibility & Balance Constraints

- The limit only affects newly generated chunks; existing pools are unchanged.
- The setting allows server admins to increase the radius if desired, maintaining backward compatibility for worlds with larger pools.
- No gameplay balance impact — pool size is cosmetic.
