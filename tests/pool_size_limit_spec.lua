local modpath = "."

describe("Pool size limit", function()

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
    -- R1: Water beyond pool_max_radius is forced cool even if gradient says otherwise
    -----------------------------------------------------------------------
    it("R1: should force cool beyond pool_max_radius when gradient alone would not", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_vent_scan_radius = 50,
            hot_springs_pool_max_radius = 25,
        })
        reload_mod()

        setup_vent({x = 0, y = 0, z = 0}, 100)

        -- dist 26: gradient gives 100-26 = 74 → hot, but pool_max_radius=25 forces cool
        minetest.set_node({x = 26, y = 0, z = 0}, {name = "default:water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 30, y = 5, z = 5})

        assert.are.equal("default:water_source", minetest.get_node({x = 26, y = 0, z = 0}).name,
            "water beyond pool_max_radius should remain default")
    end)

    -----------------------------------------------------------------------
    -- R1: Water within pool_max_radius is still converted
    -----------------------------------------------------------------------
    it("R1: should still convert water within pool_max_radius", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_vent_scan_radius = 50,
            hot_springs_pool_max_radius = 25,
        })
        reload_mod()

        setup_vent({x = 0, y = 0, z = 0}, 100)

        -- dist 20: gradient gives 100-20 = 80 → scalding
        minetest.set_node({x = 20, y = 0, z = 0}, {name = "default:water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 30, y = 5, z = 5})

        assert.are.equal("hot_springs:scalding_water_source", minetest.get_node({x = 20, y = 0, z = 0}).name,
            "water within pool_max_radius should be converted")
    end)

    -----------------------------------------------------------------------
    -- R1: Water at boundary (dist == pool_max_radius) is still converted
    -----------------------------------------------------------------------
    it("R1: should convert water at exactly pool_max_radius distance", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_vent_scan_radius = 50,
            hot_springs_pool_max_radius = 25,
        })
        reload_mod()

        setup_vent({x = 0, y = 0, z = 0}, 100)

        -- dist 25: gradient gives 100-25 = 75 → hot (>= 50, < 80)
        minetest.set_node({x = 25, y = 0, z = 0}, {name = "default:water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 30, y = 5, z = 5})

        assert.are.equal("hot_springs:hot_water_source", minetest.get_node({x = 25, y = 0, z = 0}).name,
            "water at pool_max_radius boundary should be converted")
    end)

    -----------------------------------------------------------------------
    -- Regression: water beyond vent_scan_radius but within pool_max_radius
    -- should still convert (common scenario with defaults: vent_scan=20, pool=25)
    -----------------------------------------------------------------------
    it("R1: should convert water beyond vent_scan_radius but within pool_max_radius", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_vent_scan_radius = 20,
            hot_springs_pool_max_radius = 25,
        })
        reload_mod()

        setup_vent({x = 0, y = 0, z = 0}, 100)

        -- dist 22: beyond vent_scan_radius (20) but within pool_max_radius (25)
        -- effective gradient radius = max(20, 25) = 25 → temp = 100-22 = 78 → hot
        minetest.set_node({x = 22, y = 0, z = 0}, {name = "default:water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 30, y = 5, z = 5})

        assert.are.equal("hot_springs:hot_water_source", minetest.get_node({x = 22, y = 0, z = 0}).name,
            "water within pool_max_radius should convert even if beyond vent_scan_radius")
    end)

    -----------------------------------------------------------------------
    -- R2: Should read pool_max_radius from settings
    -----------------------------------------------------------------------
    it("R2: should respect custom pool_max_radius setting", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_vent_scan_radius = 50,
            hot_springs_pool_max_radius = 10,
        })
        reload_mod()

        setup_vent({x = 0, y = 0, z = 0}, 100)

        -- dist 11: area gradient gives 100-11 = 89 → scalding, but pool_max_radius=10 forces cool
        minetest.set_node({x = 11, y = 0, z = 0}, {name = "default:water_source"})
        -- dist 9: within radius
        minetest.set_node({x = 9, y = 0, z = 0}, {name = "default:water_source"})

        minetest._on_generated({x = 0, y = 0, z = 0}, {x = 20, y = 5, z = 5})

        assert.are.equal("default:water_source", minetest.get_node({x = 11, y = 0, z = 0}).name,
            "water beyond custom pool_max_radius=10 should be default")
        assert.are.equal("hot_springs:scalding_water_source", minetest.get_node({x = 9, y = 0, z = 0}).name,
            "water within custom pool_max_radius=10 should be converted")
    end)

    -----------------------------------------------------------------------
    -- R3: Migration is not affected by pool_max_radius
    -----------------------------------------------------------------------
    it("R3: should not affect migration command", function()
        reset_mock_settings({
            hot_springs_temp_gradient = 1.0,
            hot_springs_pool_max_radius = 5,
        })
        reload_mod()

        -- Warm water placed far from any vent (simulating migration scenario)
        minetest.set_node({x = 100, y = 0, z = 100}, {name = "hot_springs:hot_water_source"})
        minetest.set_node({x = 200, y = 0, z = 200}, {name = "hot_springs:hot_water_flowing"})

        minetest._chatcommands["hot_springs_migrate"].func("test_player")

        -- Migration maps old to new names regardless of distance
        local after = {}
        for _, entry in ipairs(minetest._nodes_in_area) do
            after[entry.name] = (after[entry.name] or 0) + 1
        end
        assert.are.equal(1, after["hot_springs:warm_water_source"], "should have migrated hot_water_source")
        assert.are.equal(1, after["hot_springs:warm_water_flowing"], "should have migrated hot_water_flowing")
        assert.is_nil(after["hot_springs:hot_water_source"], "old hot_water_source should be gone")
        assert.is_nil(after["hot_springs:hot_water_flowing"], "old hot_water_flowing should be gone")
    end)

end)
