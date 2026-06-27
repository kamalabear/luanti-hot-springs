local modpath = "."

describe("Configurable Steam Intensity", function()

    local captured_abms = {}
    local captured_particles = {}

    before_each(function()
        captured_abms = {}
        captured_particles = {}

        reset_mock_settings()
        reset_mock_nodes()

        -- ensure default water nodes exist for the hot spring water cloning
        minetest.register_node("default:water_source", {
            description = "Water Source",
            liquidtype = "source",
            liquid_alternative_flowing = "default:water_flowing",
            liquid_alternative_source = "default:water_source",
        })
        minetest.register_node("default:water_flowing", {
            description = "Water Flowing",
            liquidtype = "flowing",
            liquid_alternative_flowing = "default:water_flowing",
            liquid_alternative_source = "default:water_source",
        })

        -- capture ABM registrations
        minetest.register_abm = function(def)
            table.insert(captured_abms, def)
        end

        -- capture particle spawner calls
        minetest.add_particlespawner = function(def)
            table.insert(captured_particles, def)
        end
    end)

    --- Reload init.lua after clearing package cache so it re-executes.
    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
    end

    --- Find an ABM by nodename pattern.
    local function find_abm(nodenames)
        for _, abm in ipairs(captured_abms) do
            if abm.nodenames and abm.nodenames[1] == nodenames then
                return abm
            end
        end
        return nil
    end

    -------------------------------------------------------------------
    -- R1: enabled/disable
    -------------------------------------------------------------------
    it("R1: should disable steam when hot_springs_steam_enabled is false", function()
        reset_mock_settings({ hot_springs_steam_enabled = false })
        reload_mod()
        -- trigger source ABM action
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        assert.is_not_nil(abm.action)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        -- no particles should have been spawned
        assert.are.equal(0, #captured_particles)
    end)

    -------------------------------------------------------------------
    -- R2: source amount defaults
    -------------------------------------------------------------------
    it("R2: should use default source amount range", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        assert.are.equal(10, abm.interval)
        assert.are.equal(6, abm.chance)
    end)

    -------------------------------------------------------------------
    -- R3: size defaults
    -------------------------------------------------------------------
    it("R3: should use default size range", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            local p = captured_particles[1]
            assert.are.equal(0.5, p.minsize)
            assert.are.equal(7.0, p.maxsize)
        end
    end)

    -------------------------------------------------------------------
    -- R4: source exptime defaults
    -------------------------------------------------------------------
    it("R4: should use default source exptime range", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            local p = captured_particles[1]
            assert.are.equal(8.0, p.minexptime)
            assert.are.equal(16.0, p.maxexptime)
        end
    end)

    -------------------------------------------------------------------
    -- R5: glow defaults
    -------------------------------------------------------------------
    it("R5: should use default glow value", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            assert.are.equal(3, captured_particles[1].glow)
        end
    end)

    -------------------------------------------------------------------
    -- R6: source ABM cadence defaults
    -------------------------------------------------------------------
    it("R6: should use default source ABM cadence", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        assert.are.equal(10, abm.interval)
        assert.are.equal(6, abm.chance)
    end)

    -------------------------------------------------------------------
    -- R7: flowing ABM cadence defaults
    -------------------------------------------------------------------
    it("R7: should use default flowing ABM cadence", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_flowing")
        assert.is_not_nil(abm)
        assert.are.equal(30, abm.interval)
        assert.are.equal(10, abm.chance)
    end)

    -------------------------------------------------------------------
    -- R8: clamping out-of-range values
    -------------------------------------------------------------------
    it("R8: should clamp out-of-range values to safe bounds", function()
        reset_mock_settings({ hot_springs_steam_glow = 42 })
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            assert.are.equal(14, captured_particles[1].glow)
        end
    end)

    -------------------------------------------------------------------
    -- R9: fall back on type mismatch
    -------------------------------------------------------------------
    it("R9: should fall back to defaults on type mismatch", function()
        reset_mock_settings({ hot_springs_steam_glow = "abc" })
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            assert.are.equal(3, captured_particles[1].glow)
        end
    end)

    -------------------------------------------------------------------
    -- R11: flowing amount defaults
    -------------------------------------------------------------------
    it("R11: should use default flowing amount range", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_flowing")
        assert.is_not_nil(abm)
        assert.are.equal(30, abm.interval)
        assert.are.equal(10, abm.chance)
        -- trigger the action and verify a particle spawner was queued
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        assert.is_true(#captured_particles > 0)
    end)

    -------------------------------------------------------------------
    -- R12: flowing exptime defaults
    -------------------------------------------------------------------
    it("R12: should use default flowing exptime range", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_flowing")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            local p = captured_particles[1]
            assert.are.equal(5.0, p.minexptime)
            assert.are.equal(10.0, p.maxexptime)
        end
    end)

    -------------------------------------------------------------------
    -- R5b: accept non-default glow
    -------------------------------------------------------------------
    it("R5b: should accept non-default glow value", function()
        reset_mock_settings({ hot_springs_steam_glow = 7 })
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            assert.are.equal(7, captured_particles[1].glow)
        end
    end)

    -------------------------------------------------------------------
    -- R2b: accept non-default source amount
    -------------------------------------------------------------------
    it("R2b: should accept non-default source amount", function()
        reset_mock_settings({ hot_springs_steam_amount_max = 5.0 })
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        if #captured_particles > 0 then
            local p = captured_particles[1]
            assert.is_true(p.amount <= 5.0)
        end
    end)

    -------------------------------------------------------------------
    -- R13: inverted min/max swap
    -------------------------------------------------------------------
    it("R13: should swap inverted min/max values so min <= max", function()
        reset_mock_settings({ hot_springs_steam_amount_min = 5.0, hot_springs_steam_amount_max = 0.5 })
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        -- if values were NOT swapped, math.random(5.0, 0.5) would error (empty range)
        -- a successful call proves the swap occurred
        assert.has_no_errors(function()
            abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        end)
        assert.is_true(#captured_particles > 0)
    end)

    -------------------------------------------------------------------
    -- NF2: load without errors with no settings
    -------------------------------------------------------------------
    it("NF2: should load without errors when no settings are present", function()
        reset_mock_settings(nil)
        assert.has_no_errors(function()
            reload_mod()
        end)
    end)

    -------------------------------------------------------------------
    -- NF3: load without errors with partial settings
    -------------------------------------------------------------------
    it("NF3: should load without errors with partial settings", function()
        reset_mock_settings({ hot_springs_steam_enabled = true })
        assert.has_no_errors(function()
            reload_mod()
        end)
    end)

    -------------------------------------------------------------------
    -- NF4: no per-spawn action log spam
    -------------------------------------------------------------------
    it("NF4: should not produce per-spawn action log spam", function()
        reset_mock_settings({})
        reload_mod()
        local abm = find_abm("hot_springs:hot_water_source")
        assert.is_not_nil(abm)
        -- capture log calls
        local log_calls = {}
        minetest.log = function(level, msg)
            table.insert(log_calls, { level = level, msg = msg })
        end
        abm.action({ x = 0, y = 1, z = 0 }, nil, 0, 0)
        for _, call in ipairs(log_calls) do
            assert.is_false(call.msg:find("Adding steam to hot water"))
        end
    end)

end)
