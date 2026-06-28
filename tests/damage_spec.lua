local modpath = "."

describe("Thermal Damage", function()

    local registered_damage = {}

    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
    end

    before_each(function()
        registered_damage = {}
        reset_mock_state()

        -- register default water nodes for the hot spring node cloning
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

        -- capture damage/drowning at registration time for hot spring nodes
        local orig_register = minetest.register_node
        minetest.register_node = function(name, def)
            if name:find("^hot_springs:") then
                registered_damage[name] = {
                    damage_per_second = def.damage_per_second,
                    drowning = def.drowning,
                }
            end
            orig_register(name, def)
        end
    end)

    -------------------------------------------------------------------
    -- R1: Hot water source damage default
    -------------------------------------------------------------------
    it("R1: should default to 0 DPS for hot_water_source", function()
        reset_mock_settings({})
        reload_mod()
        local d = registered_damage["hot_springs:hot_water_source"]
        assert.is_not_nil(d)
        assert.are.equal(0, d.damage_per_second)
    end)

    -------------------------------------------------------------------
    -- R2: Hot water flowing damage default
    -------------------------------------------------------------------
    it("R2: should default to 0 DPS for hot_water_flowing", function()
        reset_mock_settings({})
        reload_mod()
        local d = registered_damage["hot_springs:hot_water_flowing"]
        assert.is_not_nil(d)
        assert.are.equal(0, d.damage_per_second)
    end)

    -------------------------------------------------------------------
    -- R3: Scalding water source damage default
    -------------------------------------------------------------------
    it("R3: should default to 3.0 DPS for scalding_water_source", function()
        reset_mock_settings({})
        reload_mod()
        local d = registered_damage["hot_springs:scalding_water_source"]
        assert.is_not_nil(d)
        assert.are.equal(3.0, d.damage_per_second)
    end)

    -------------------------------------------------------------------
    -- R1/R2/R3: Custom damage values applied
    -------------------------------------------------------------------
    it("R1/R2/R3: should apply custom damage values from settings", function()
        reset_mock_settings({
            hot_springs_hot_damage = 1.5,
            hot_springs_flowing_damage = 2.0,
            hot_springs_boiling_damage = 8.0,
        })
        reload_mod()
        assert.are.equal(1.5, registered_damage["hot_springs:hot_water_source"].damage_per_second)
        assert.are.equal(2.0, registered_damage["hot_springs:hot_water_flowing"].damage_per_second)
        assert.are.equal(8.0, registered_damage["hot_springs:scalding_water_source"].damage_per_second)
    end)

    -------------------------------------------------------------------
    -- Clamp negative damage to 0
    -------------------------------------------------------------------
    it("should clamp negative damage to 0", function()
        reset_mock_settings({
            hot_springs_hot_damage = -5,
            hot_springs_boiling_damage = -1,
        })
        reload_mod()
        assert.are.equal(0, registered_damage["hot_springs:hot_water_source"].damage_per_second)
        assert.are.equal(0, registered_damage["hot_springs:scalding_water_source"].damage_per_second)
    end)

    -------------------------------------------------------------------
    -- R4: Drowning default (false = normal drowning)
    -------------------------------------------------------------------
    it("R4: should allow normal drowning by default", function()
        reset_mock_settings({})
        reload_mod()
        -- no_drowning = false means drowning is NOT set to 0
        -- the field may be nil or 1 depending on the template copy
        local d = registered_damage["hot_springs:scalding_water_source"]
        assert.is_not_nil(d)
        -- should NOT have drowning = 0
        assert.is_not_equal(0, d.drowning)
    end)

    -------------------------------------------------------------------
    -- R4: Drowning prevention enabled
    -------------------------------------------------------------------
    it("R4: should disable drowning when hot_springs_no_drowning is true", function()
        reset_mock_settings({ hot_springs_no_drowning = true })
        reload_mod()
        -- all six nodes should have drowning = 0
        for _, name in ipairs({
            "hot_springs:warm_water_source",
            "hot_springs:warm_water_flowing",
            "hot_springs:hot_water_source",
            "hot_springs:hot_water_flowing",
            "hot_springs:scalding_water_source",
            "hot_springs:scalding_water_flowing",
        }) do
            assert.are.equal(0, registered_damage[name].drowning,
                "drowning should be 0 for " .. name)
        end
    end)

    -------------------------------------------------------------------
    -- Flowing and source damage independent (AC-R10)
    -------------------------------------------------------------------
    it("AC-R10: flowing and source damage are independent", function()
        reset_mock_settings({
            hot_springs_hot_damage = 2.0,
            hot_springs_flowing_damage = 1.0,
        })
        reload_mod()
        assert.are.equal(2.0, registered_damage["hot_springs:hot_water_source"].damage_per_second)
        assert.are.equal(1.0, registered_damage["hot_springs:hot_water_flowing"].damage_per_second)
        assert.are.equal(2.0, registered_damage["hot_springs:warm_water_source"].damage_per_second)
        assert.are.equal(1.0, registered_damage["hot_springs:warm_water_flowing"].damage_per_second)
    end)

    -------------------------------------------------------------------
    -- Load without errors with no settings
    -------------------------------------------------------------------
    it("should load without errors when no settings are present", function()
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
        -- reset the capture mock
        local orig_register = minetest.register_node
        minetest.register_node = function(name, def)
            if name:find("^hot_springs:") then
                registered_damage[name] = {
                    damage_per_second = def.damage_per_second,
                    drowning = def.drowning,
                }
            end
            orig_register(name, def)
        end
        assert.has_no_errors(function()
            reload_mod()
        end)
    end)

end)
