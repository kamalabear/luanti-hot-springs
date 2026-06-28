# Issues Summary

2 ambiguity issues, 1 missing edge case, 1 AC gap.

# Ambiguity Issues

## Issue 1: R1 — "underlying bare block" undefined for `default:snow`

`default:snow` is a thin overlay node that occupies its own position above a ground node (e.g. `default:dirt_with_snow` is the ground, `default:snow` is above it). "Replace with underlying bare block" is ambiguous:

- Does it mean look at the node BELOW the snow and copy its bare variant?
- Does it mean just delete the snow node (set to air)?
- Or does it mean replace the entire `default:dirt_with_snow` ground node at a *different* position?

The spec example (`default:dirt_with_snow → default:dirt`) suggests the ground block gets replaced, but `default:snow` as a separate node isn't addressed.

**Recommendation:** Resolve by specifying exact mappings for each target node name.

## Issue 2: R4 overlaps with R1

R4 repeats the snow/snowblock handling already described in R1, but uses a different fallback rule ("default:dirt" vs "underlying bare block"). These conflict and must be consolidated into a single definitive mapping.

# Missing Edge Cases

## Issue 3: `default:dirt_with_snow` not listed

The spec example explicitly shows `default:dirt_with_snow → default:dirt` as a melt target, but no RID covers it. This node will be the most common snow-covered ground adjacent to hot springs and must be addressed.

# Acceptance Criteria Gaps

## Issue 4: AC-R1 conflates multiple node types

AC-R1 says "snow is replaced with `default:dirt`" but doesn't distinguish between `default:snow` (overlay), `default:snowblock`, and `default:dirt_with_snow`. These need separate, unambiguous criteria.

## Issue 5: No AC for flowing water nodes

The spec says "water source nodes" — should the effect also trigger adjacent to flowing hot spring water? If yes, add AC. If no, state explicitly.

# Compatibility Risks

None identified. The `default:*` namespace guard and worldgen-only timing are appropriate.

# Balance Risks

None identified. Cosmetic-only changes with low moss probability.

# Recommendations (optional)

1. Consolidate R1+R4 into a single melt mapping requirement with exact replacement rules per node name.
2. Add RID for `default:dirt_with_snow`.
3. State explicitly whether flowing water variants are included.
4. Resolve Open Question 1 before implementation.
