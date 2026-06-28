local modpath = "."

describe("Variable Temperature", function()

    local captured_abms = {}
    local captured_particles = {}

    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
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

    -------------------------------------------------------------------
    -- AC-R1 / R5: warm_water_source returns 40
    -------------------------------------------------------------------
    it("AC-R1: should return 40 for warm_water_source", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal(40, hot_springs.get_pool_temperature("hot_springs:warm_water_source"))
    end)

    -------------------------------------------------------------------
    -- AC-R1b / R5: hot_water_source returns 60
    -------------------------------------------------------------------
    it("AC-R1b: should return 60 for hot_water_source", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal(60, hot_springs.get_pool_temperature("hot_springs:hot_water_source"))
    end)

    -------------------------------------------------------------------
    -- AC-R1c / R5: scalding_water_source returns 90
    -------------------------------------------------------------------
    it("AC-R1c: should return 90 for scalding_water_source", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal(90, hot_springs.get_pool_temperature("hot_springs:scalding_water_source"))
    end)

    -------------------------------------------------------------------
    -- Flowing variants match their source temperatures
    -------------------------------------------------------------------
    it("should return same temperatures for flowing variants", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal(40, hot_springs.get_pool_temperature("hot_springs:warm_water_flowing"))
        assert.are.equal(60, hot_springs.get_pool_temperature("hot_springs:hot_water_flowing"))
        assert.are.equal(90, hot_springs.get_pool_temperature("hot_springs:scalding_water_flowing"))
    end)

    -------------------------------------------------------------------
    -- AC-R2 / R6: unknown node returns nil
    -------------------------------------------------------------------
    it("AC-R2: should return nil for unknown node names", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_nil(hot_springs.get_pool_temperature("default:dirt"))
        assert.is_nil(hot_springs.get_pool_temperature("air"))
        assert.is_nil(hot_springs.get_pool_temperature(""))
    end)

    -------------------------------------------------------------------
    -- AC-R3 / R3: classify below warm_min as cool
    -------------------------------------------------------------------
    it("AC-R3: should classify temperatures below warm_min as cool", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal("cool", hot_springs.classify_temperature(0))
        assert.are.equal("cool", hot_springs.classify_temperature(15))
        assert.are.equal("cool", hot_springs.classify_temperature(29))
    end)

    -------------------------------------------------------------------
    -- AC-R3b / R3: classify warm range
    -------------------------------------------------------------------
    it("AC-R3b: should classify temperatures in warm range", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal("warm", hot_springs.classify_temperature(30))
        assert.are.equal("warm", hot_springs.classify_temperature(40))
        assert.are.equal("warm", hot_springs.classify_temperature(49))
    end)

    -------------------------------------------------------------------
    -- AC-R3c / R3: classify hot range
    -------------------------------------------------------------------
    it("AC-R3c: should classify temperatures in hot range", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal("hot", hot_springs.classify_temperature(50))
        assert.are.equal("hot", hot_springs.classify_temperature(60))
        assert.are.equal("hot", hot_springs.classify_temperature(79))
    end)

    -------------------------------------------------------------------
    -- AC-R3d / R3: classify scalding range
    -------------------------------------------------------------------
    it("AC-R3d: should classify temperatures in scalding range", function()
        reset_mock_settings({})
        reload_mod()
        assert.are.equal("scalding", hot_springs.classify_temperature(80))
        assert.are.equal("scalding", hot_springs.classify_temperature(90))
        assert.are.equal("scalding", hot_springs.classify_temperature(1000))
    end)

    -------------------------------------------------------------------
    -- AC-R4 / R4: custom thresholds
    -------------------------------------------------------------------
    it("AC-R4: should respect custom threshold settings", function()
        reset_mock_settings({
            hot_springs_temp_warm_min = 35,
            hot_springs_temp_hot_min = 65,
            hot_springs_temp_scalding_min = 90,
        })
        reload_mod()
        assert.are.equal("cool", hot_springs.classify_temperature(34))
        assert.are.equal("warm", hot_springs.classify_temperature(40))
        assert.are.equal("warm", hot_springs.classify_temperature(64))
        assert.are.equal("hot", hot_springs.classify_temperature(65))
        assert.are.equal("hot", hot_springs.classify_temperature(89))
        assert.are.equal("scalding", hot_springs.classify_temperature(90))
    end)

    -------------------------------------------------------------------
    -- AC-R5: Public API available
    -------------------------------------------------------------------
    it("AC-R5: should expose get_pool_temperature and classify_temperature", function()
        reset_mock_settings({})
        reload_mod()
        assert.is_not_nil(hot_springs.get_pool_temperature)
        assert.is_not_nil(hot_springs.classify_temperature)
        assert.are.equal("function", type(hot_springs.get_pool_temperature))
        assert.are.equal("function", type(hot_springs.classify_temperature))
    end)

    -------------------------------------------------------------------
    -- AC-R6: Default temperature distinction preserved
    -------------------------------------------------------------------
    it("AC-R6: should distinguish warm, hot, and scalding with defaults", function()
        reset_mock_settings({})
        reload_mod()
        local warm_class = hot_springs.classify_temperature(
            hot_springs.get_pool_temperature("hot_springs:warm_water_source"))
        local hot_class = hot_springs.classify_temperature(
            hot_springs.get_pool_temperature("hot_springs:hot_water_source"))
        local scalding_class = hot_springs.classify_temperature(
            hot_springs.get_pool_temperature("hot_springs:scalding_water_source"))
        assert.are.equal("warm", warm_class)
        assert.are.equal("hot", hot_class)
        assert.are.equal("scalding", scalding_class)
    end)

    -------------------------------------------------------------------
    -- AC-R7: Settings in settingtypes.txt
    -------------------------------------------------------------------
    it("AC-R7: should have temperature settings in settingtypes.txt", function()
        local f = io.open(modpath .. "/settingtypes.txt", "r")
        assert.is_not_nil(f)
        local content = f:read("*all")
        f:close()
        assert.is_true(content:find("hot_springs_temp_warm_min") ~= nil)
        assert.is_true(content:find("hot_springs_temp_hot_min") ~= nil)
        assert.is_true(content:find("hot_springs_temp_scalding_min") ~= nil)
        assert.is_true(content:find("hot_springs_temp_gradient") ~= nil)
        assert.is_true(content:find("hot_springs_vent_scan_radius") ~= nil)
    end)

    -------------------------------------------------------------------
    -- Boundary: threshold min/max swap
    -------------------------------------------------------------------
    it("should swap inverted temperature thresholds", function()
        reset_mock_settings({
            hot_springs_temp_warm_min = 80,
            hot_springs_temp_hot_min = 50,
            hot_springs_temp_scalding_min = 30,
        })
        reload_mod()
        -- warm_min should be swapped to 30, hot_min to 50, scalding_min to 80
        assert.are.equal("scalding", hot_springs.classify_temperature(80))
        assert.are.equal("hot", hot_springs.classify_temperature(60))
        assert.are.equal("warm", hot_springs.classify_temperature(40))
        assert.are.equal("cool", hot_springs.classify_temperature(20))
    end)

    -------------------------------------------------------------------
    -- Clamp thresholds to minimum 1
    -------------------------------------------------------------------
    it("should clamp temperature thresholds to minimum 1", function()
        reset_mock_settings({
            hot_springs_temp_warm_min = -5,
            hot_springs_temp_hot_min = 5,
            hot_springs_temp_scalding_min = 10,
        })
        reload_mod()
        -- warm_min = -5 clamps to 1, hot_min = 5 stays, scalding_min = 10 stays
        assert.are.equal("cool", hot_springs.classify_temperature(0))
        assert.are.equal("warm", hot_springs.classify_temperature(3))
        assert.are.equal("hot", hot_springs.classify_temperature(7))
        assert.are.equal("scalding", hot_springs.classify_temperature(10))
    end)

    -------------------------------------------------------------------
    -- Load without errors with no temperature settings
    -------------------------------------------------------------------
    it("should load without errors with no temperature settings", function()
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
        assert.has_no_errors(function()
            reload_mod()
        end)
    end)

end)
