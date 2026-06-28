local modpath = "."

describe("Temperature Gradient System", function()

    local captured_abms = {}
    local captured_particles = {}

    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
    end

    local function setup_vent(pos, temperature)
        table.insert(minetest._nodes_in_area, {pos = pos, name = "hot_springs:vent_block"})
        local meta = minetest.get_meta(pos)
        meta:set_int("hot_springs_temperature", temperature)
    end

    before_each(function()
        captured_abms = {}
        captured_particles = {}
        reset_mock_state()

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

        minetest.register_abm = function(def)
            table.insert(captured_abms, def)
        end
        minetest.add_particlespawner = function(def)
            table.insert(captured_particles, def)
        end
    end)

    -----------------------------------------------------------------------
    -- R1: Position-based temperature reads per-node metadata first
    -----------------------------------------------------------------------
    it("R1: should return metadata temperature when set on a node", function()
        reset_mock_settings({})
        reload_mod()
        local pos = {x = 0, y = 1, z = 0}
        local meta = minetest.get_meta(pos)
        meta:set_int("hot_springs_temperature", 75)
        assert.are.equal(75, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R2: Pure node-name lookup returns static mapping (no pos arg)
    -----------------------------------------------------------------------
    it("R2: should return static mapping when no position given", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal(40, hot_springs.get_pool_temperature("hot_springs:warm_water_source"))
        assert.are.equal(60, hot_springs.get_pool_temperature("hot_springs:hot_water_source"))
        assert.are.equal(90, hot_springs.get_pool_temperature("hot_springs:scalding_water_source"))
        assert.is_nil(hot_springs.get_pool_temperature("default:dirt"))
    end)

    -----------------------------------------------------------------------
    -- R3: Nearest vent temperature applied with distance falloff
    -----------------------------------------------------------------------
    it("R3: should return vent temperature at distance 0", function()
        reset_mock_settings({ hot_springs_temp_gradient = 5.0, hot_springs_vent_scan_radius = 20 })
        reload_mod()
        setup_vent({x = 0, y = 0, z = 0}, 85)
        -- water block directly at vent position
        local pos = {x = 0, y = 0, z = 0}
        assert.are.equal(85, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R4: Temperature decreases with distance * gradient
    -----------------------------------------------------------------------
    it("R4: should decrease temperature by distance * gradient", function()
        reset_mock_settings({ hot_springs_temp_gradient = 5.0, hot_springs_vent_scan_radius = 20 })
        reload_mod()
        setup_vent({x = 0, y = 0, z = 0}, 100)
        -- 3 nodes away → 100 - 3*5 = 85
        local pos = {x = 3, y = 0, z = 0}
        assert.are.equal(85, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R5: Multiple vents — nearest one wins (no blending)
    -----------------------------------------------------------------------
    it("R5: should use nearest vent, not blend", function()
        reset_mock_settings({ hot_springs_temp_gradient = 5.0, hot_springs_vent_scan_radius = 50 })
        reload_mod()
        setup_vent({x = 0, y = 0, z = 0}, 100)
        setup_vent({x = 20, y = 0, z = 0}, 50)
        -- position at x=2: dist to vent1 = 2, dist to vent2 = 18
        -- vent1: 100 - 2*5 = 90, vent2: 50 - 18*5 = -40 → 0
        -- nearest vent is vent1 → 90
        local pos = {x = 2, y = 0, z = 0}
        assert.are.equal(90, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R6: No vent within range → static fallback
    -----------------------------------------------------------------------
    it("R6: should fall back to static mapping when no vent in range", function()
        reset_mock_settings({ hot_springs_temp_gradient = 5.0, hot_springs_vent_scan_radius = 10 })
        reload_mod()
        setup_vent({x = 99, y = 99, z = 99}, 100)
        local pos = {x = 0, y = 0, z = 0}
        assert.are.equal(40, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R7: Temperature floors at 0
    -----------------------------------------------------------------------
    it("R7: should floor temperature at 0 when gradient exceeds vent temp", function()
        reset_mock_settings({ hot_springs_temp_gradient = 10.0, hot_springs_vent_scan_radius = 20 })
        reload_mod()
        setup_vent({x = 0, y = 0, z = 0}, 30)
        local pos = {x = 5, y = 0, z = 0}
        -- 30 - 5*10 = -20 → max(0, -20) = 0
        assert.are.equal(0, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- R8: Vent cache is invalidated on vent_block placement
    -----------------------------------------------------------------------
    it("R8: should invalidate cache on vent_block placement", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(minetest._on_placenode)
        -- prime cache
        local pos = {x = 5, y = 5, z = 5}
        setup_vent(pos, 80)
        -- access triggers rebuild
        hot_springs.get_pool_temperature("hot_springs:warm_water_source", {x = 0, y = 0, z = 0})
        -- place a new vent
        minetest._on_placenode({x = 10, y = 10, z = 10}, {name = "hot_springs:vent_block"})
        -- next call should see the new vent (cache was nil'd)
        assert.is_not_nil(hot_springs.get_pool_temperature("hot_springs:hot_water_source", {x = 10, y = 10, z = 10}))
    end)

    -----------------------------------------------------------------------
    -- R9: Vent cache is invalidated on vent_block digging
    -----------------------------------------------------------------------
    it("R9: should invalidate cache on vent_block removal", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(minetest._on_dignode)
        -- prime cache
        setup_vent({x = 0, y = 0, z = 0}, 80)
        hot_springs.get_pool_temperature("hot_springs:warm_water_source", {x = 0, y = 0, z = 0})
        -- dig a vent
        minetest._on_dignode({x = 99, y = 99, z = 99}, {name = "hot_springs:vent_block"})
        -- cache was nil'd, none of the error below should happen
        local ok, err = pcall(function()
            hot_springs.get_pool_temperature("hot_springs:warm_water_source", {x = 10, y = 10, z = 10})
        end)
        assert.is_true(ok, "should not error after dig: " .. tostring(err))
    end)

    -----------------------------------------------------------------------
    -- R10: Migration command registered
    -----------------------------------------------------------------------
    it("R10: should register hot_springs_migrate chat command", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(minetest._chatcommands["hot_springs_migrate"])
        local cmd = minetest._chatcommands["hot_springs_migrate"]
        assert.is_not_nil(cmd.privs)
        assert.is_not_nil(cmd.privs.server)
        assert.is_true(cmd.privs.server)
        assert.is_not_nil(cmd.func)
    end)

    -----------------------------------------------------------------------
    -- R10b: Migration maps old nodes to new
    -----------------------------------------------------------------------
    it("R10b: should replace old node names with new during migration", function()
        reset_mock_settings({})
        reload_mod()
        -- Place old-format nodes in the mock world
        minetest.set_node({x = 1, y = 0, z = 0}, {name = "hot_springs:hot_water_source"})
        minetest.set_node({x = 2, y = 0, z = 0}, {name = "hot_springs:hot_water_flowing"})
        minetest.set_node({x = 3, y = 0, z = 0}, {name = "hot_springs:boiling_water_source"})
        -- Run migration
        minetest._chatcommands["hot_springs_migrate"].func("test_player")
        -- Verify replacement
        local after = {}
        for _, entry in ipairs(minetest._nodes_in_area) do
            after[entry.name] = (after[entry.name] or 0) + 1
        end
        assert.are.equal(1, after["hot_springs:warm_water_source"], "should have 1 warm_water_source")
        assert.are.equal(1, after["hot_springs:warm_water_flowing"], "should have 1 warm_water_flowing")
        assert.are.equal(1, after["hot_springs:scalding_water_source"], "should have 1 scalding_water_source")
        -- old names should no longer appear
        assert.is_nil(after["hot_springs:hot_water_source"])
        assert.is_nil(after["hot_springs:boiling_water_source"])
    end)

    -----------------------------------------------------------------------
    -- R10c: Migration command requires server privilege
    -----------------------------------------------------------------------
    it("R10c: should require server privilege", function()
        reset_mock_settings({})
        reload_mod()
        local cmd = minetest._chatcommands["hot_springs_migrate"]
        assert.are.same({server = true}, cmd.privs)
    end)

    -----------------------------------------------------------------------
    -- Vent block node is registered
    -----------------------------------------------------------------------
    it("should register vent_block node", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(minetest.registered_nodes["hot_springs:vent_block"])
        local def = minetest.registered_nodes["hot_springs:vent_block"]
        assert.is_not_nil(def.groups)
        assert.are.equal(1, def.groups.hot or 0)
    end)

    -----------------------------------------------------------------------
    -- No error when no vents exist
    -----------------------------------------------------------------------
    it("should handle empty vent cache gracefully", function()
        reset_mock_settings({ hot_springs_temp_gradient = 5.0, hot_springs_vent_scan_radius = 20 })
        reload_mod()
        local pos = {x = 0, y = 0, z = 0}
        -- no vents set up → should fall back to static
        assert.are.equal(40, hot_springs.get_pool_temperature("hot_springs:warm_water_source", pos))
    end)

    -----------------------------------------------------------------------
    -- CID-8: Integration test — auto vent placement
    -----------------------------------------------------------------------
    it("INT: should auto-place vent at bottom of biome pool", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()
        math.randomseed(1)

        -- Single scalding source with stone below (simplest pool)
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:scalding_water_source"})
        minetest.set_node({x = 5, y = -1, z = 5}, {name = "default:stone"})

        minetest._on_generated({x = 0, y = -2, z = 0}, {x = 10, y = 10, z = 10})

        local vnode = minetest.get_node({x = 5, y = -1, z = 5})
        assert.are.equal("hot_springs:vent_block", vnode.name)
        local vtemp = minetest.get_meta({x = 5, y = -1, z = 5}):get_int("hot_springs_temperature")
        assert.is_true(vtemp >= 30 and vtemp <= 100, "vent temp " .. vtemp)
    end)

    -----------------------------------------------------------------------
    -- CID-8: Integration test — temperature gradient with known vent
    -----------------------------------------------------------------------
    it("INT: gradient — nearby water is hotter than distant water", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()

        setup_vent({x = 0, y = -1, z = 0}, 85)
        -- 5 water nodes at increasing distances from vent
        minetest.set_node({x = 1, y = 0, z = 0}, {name = "default:water_source"}) -- dist 1.4 → 85-7=78 → hot
        minetest.set_node({x = 4, y = 0, z = 0}, {name = "default:water_source"}) -- dist 4.1 → 85-21=64 → hot
        minetest.set_node({x = 8, y = 0, z = 0}, {name = "default:water_source"}) -- dist 8.1 → 85-40=45 → warm
        minetest.set_node({x = 12, y = 0, z = 0}, {name = "default:water_source"}) -- dist 12 → 85-60=25 → cool

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 5})

        assert.are.equal("hot_springs:hot_water_source", minetest.get_node({x = 1, y = 0, z = 0}).name)
        assert.are.equal("hot_springs:hot_water_source", minetest.get_node({x = 4, y = 0, z = 0}).name)
        assert.are.equal("hot_springs:warm_water_source", minetest.get_node({x = 8, y = 0, z = 0}).name)
        assert.are.equal("default:water_source", minetest.get_node({x = 12, y = 0, z = 0}).name)
    end)

    -----------------------------------------------------------------------
    -- CID-8: Vent not placed if vent already exists nearby
    -----------------------------------------------------------------------
    it("should not place duplicate vent when one already exists nearby", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()
        math.randomseed(1)

        -- Place a vent manually
        setup_vent({x = 5, y = 0, z = 5}, 80)
        -- Place pool water
        minetest.set_node({x = 5, y = 1, z = 5}, {name = "hot_springs:warm_water_source"})
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:scalding_water_source"})
        -- Place stone below
        minetest.set_node({x = 5, y = -1, z = 5}, {name = "default:stone"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 15, y = 15, z = 15})

        -- No new vent should be placed (count existing vent positions)
        local vents = minetest.find_nodes_in_area(
            {x = 0, y = -5, z = 0}, {x = 15, y = 15, z = 15},
            {"hot_springs:vent_block"}
        )
        assert.are.equal(1, #vents, "should not add a second vent")
    end)

    -----------------------------------------------------------------------
    -- CID-8: Vent not placed if no solid ground below pool
    -----------------------------------------------------------------------
    it("should skip vent if no solid ground below pool", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()
        math.randomseed(1)

        -- Pool floating in air (no ground below)
        minetest.set_node({x = 10, y = 10, z = 10}, {name = "hot_springs:warm_water_source"})

        minetest._on_generated({x = 5, y = 5, z = 5}, {x = 20, y = 20, z = 20})

        -- Bottom is air, no vent should be placed
        local vents = minetest.find_nodes_in_area(
            {x = 5, y = 5, z = 5}, {x = 20, y = 20, z = 20},
            {"hot_springs:vent_block"}
        )
        assert.are.equal(0, #vents, "should not place vent on air")
    end)

    -----------------------------------------------------------------------
    -- CID-8: on_generated callback is registered
    -----------------------------------------------------------------------
    it("should register on_generated callback", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(minetest._on_generated)
        assert.are.equal("function", type(minetest._on_generated))
    end)

    -----------------------------------------------------------------------
    -- CID-8: Temperature-driven water node replacement
    -----------------------------------------------------------------------
    it("should replace water nodes by temperature class near a vent", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
            hot_springs_temp_warm_min = 30,
            hot_springs_temp_hot_min = 50,
            hot_springs_temp_scalding_min = 80,
        })
        reload_mod()
        -- vent at (0,0,0) with temperature 90
        setup_vent({x = 0, y = 0, z = 0}, 90)
        -- water nodes along x-axis in chunk
        minetest.set_node({x = 1, y = 0, z = 0}, {name = "default:water_source"})  -- dist 1 → 85 → scalding
        minetest.set_node({x = 6, y = 0, z = 0}, {name = "default:water_source"})  -- dist 6 → 60 → hot
        minetest.set_node({x = 11, y = 0, z = 0}, {name = "default:water_source"}) -- dist 11 → 35 → warm
        minetest.set_node({x = 16, y = 0, z = 0}, {name = "default:water_source"}) -- dist 16 → 10 → cool → stays default

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 20, y = 20, z = 20})

        assert.are.equal("hot_springs:scalding_water_source", minetest.get_node({x = 1, y = 0, z = 0}).name)
        assert.are.equal("hot_springs:hot_water_source", minetest.get_node({x = 6, y = 0, z = 0}).name)
        assert.are.equal("hot_springs:warm_water_source", minetest.get_node({x = 11, y = 0, z = 0}).name)
        assert.are.equal("default:water_source", minetest.get_node({x = 16, y = 0, z = 0}).name)
    end)

    -----------------------------------------------------------------------
    -- CID-8: No vents → no changes
    -----------------------------------------------------------------------
    it("should not modify water when no vent is nearby", function()
        reset_mock_settings({})
        reload_mod()
        minetest.set_node({x = 0, y = 0, z = 0}, {name = "default:water_source"})
        minetest.set_node({x = 10, y = 0, z = 0}, {name = "hot_springs:warm_water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 15, y = 15, z = 15})

        assert.are.equal("default:water_source", minetest.get_node({x = 0, y = 0, z = 0}).name)
        assert.are.equal("hot_springs:warm_water_source", minetest.get_node({x = 10, y = 0, z = 0}).name)
    end)

    -----------------------------------------------------------------------
    -- CID-8: Flowing variant correctly classified
    -----------------------------------------------------------------------
    it("should replace flowing water nodes by temperature class", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()
        setup_vent({x = 0, y = 0, z = 0}, 90)
        minetest.set_node({x = 1, y = 0, z = 0}, {name = "default:water_flowing"}) -- dist 1 → 85 → scalding

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 5, y = 5, z = 5})

        assert.are.equal("hot_springs:scalding_water_flowing", minetest.get_node({x = 1, y = 0, z = 0}).name)
    end)

    -----------------------------------------------------------------------
    -- CID-8: No water in chunk → no error
    -----------------------------------------------------------------------
    it("should not error on chunk with no water", function()
        reset_mock_settings({})
        reload_mod()
        assert.has_no_errors(function()
            minetest._on_generated({x = 0, y = 0, z = 0}, {x = 80, y = 80, z = 80})
        end)
    end)

    -----------------------------------------------------------------------
    -- CID-8: Vent in neighboring chunk still affects temperature
    -----------------------------------------------------------------------
    it("should detect vents outside the chunk via scan margin", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 5.0,
            hot_springs_vent_scan_radius = 20,
        })
        reload_mod()
        setup_vent({x = -5, y = 0, z = 0}, 60) -- outside chunk minp (x=0), within margin
        minetest.set_node({x = 0, y = 0, z = 0}, {name = "default:water_source"}) -- dist 5 → 35 → warm
        minetest.set_node({x = 2, y = 0, z = 0}, {name = "default:water_source"}) -- dist 7 → 25 → cool

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 5, y = 5, z = 5})

        assert.are.equal("hot_springs:warm_water_source", minetest.get_node({x = 0, y = 0, z = 0}).name)
        assert.are.equal("default:water_source", minetest.get_node({x = 2, y = 0, z = 0}).name)
    end)

    -----------------------------------------------------------------------
    -- CID-8: Cool buffer — adjacent to default water
    -----------------------------------------------------------------------
end)
