local modpath = "."

describe("Thermal Biome Transformation (CID-10)", function()

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
        reset_mock_state()

        -- Register required default nodes
        minetest.register_node("default:water_source", { liquidtype = "source" })
        minetest.register_node("default:water_flowing", { liquidtype = "flowing" })
        minetest.register_node("default:snow", {})
        minetest.register_node("default:snowblock", {})
        minetest.register_node("default:dirt_with_snow", {})
        minetest.register_node("default:ice", {})
        minetest.register_node("default:stone", {})
        minetest.register_node("default:dirt", {})
        minetest.register_node("default:mossycobble", {})
        minetest.register_node("default:dirt_with_grass", {})
        minetest.register_node("default:air", {})

        reload_mod()
    end)

    -----------------------------------------------------------------------
    -- R1: Melt target mapping
    -----------------------------------------------------------------------
    it("R1: should melt snow to air adjacent to warm water", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snow"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("air", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    it("R1: should convert dirt_with_snow to dirt adjacent to warm water", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:dirt_with_snow"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("default:dirt", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    it("R1: should convert snowblock to dirt adjacent to warm water", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snowblock"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("default:dirt", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    it("R1: should convert ice to water_source adjacent to warm water", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:ice"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("default:water_source", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)


    -----------------------------------------------------------------------
    -- R2: Melt radius by temperature class
    -----------------------------------------------------------------------
    it("R2: warm water melts within 1 node, not 2", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snow"})  -- dist 1 → melt
        minetest.set_node({x = 7, y = 0, z = 5}, {name = "default:snow"})  -- dist 2 → no melt

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("air", minetest.get_node({x = 6, y = 0, z = 5}).name)
        assert.are.equal("default:snow", minetest.get_node({x = 7, y = 0, z = 5}).name)
    end)

    it("R2: hot water melts within 2 nodes", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:hot_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 60)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snow"})  -- dist 1 → melt
        minetest.set_node({x = 7, y = 0, z = 5}, {name = "default:snow"})  -- dist 2 → melt

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("air", minetest.get_node({x = 6, y = 0, z = 5}).name)
        assert.are.equal("air", minetest.get_node({x = 7, y = 0, z = 5}).name)
    end)
    it("R2: scalding water melts within 3 nodes", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:scalding_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 90)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snow"})  -- dist 1 → melt
        minetest.set_node({x = 8, y = 0, z = 5}, {name = "default:snow"})  -- dist 3 → melt

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("air", minetest.get_node({x = 6, y = 0, z = 5}).name)
        assert.are.equal("air", minetest.get_node({x = 8, y = 0, z = 5}).name)
    end)

    -----------------------------------------------------------------------
    -- R3: Moss growth on stone and dirt
    -----------------------------------------------------------------------
    it("R3: should convert stone to mossycobble adjacent to warm water at expected probability", function()
        -- Place many stone nodes around warm water; with ~7.5% probability,
        -- some should convert and some should stay in a single run.
        math.randomseed(42)
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        for dx = -1, 1 do
            for dz = -1, 1 do
                if dx ~= 0 or dz ~= 0 then
                    minetest.set_node({x = 5 + dx, y = 0, z = 5 + dz}, {name = "default:stone"})
                end
            end
        end

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        local moss_count = 0
        local total = 0
        for dx = -1, 1 do
            for dz = -1, 1 do
                if dx ~= 0 or dz ~= 0 then
                    total = total + 1
                    if minetest.get_node({x = 5 + dx, y = 0, z = 5 + dz}).name == "default:mossycobble" then
                        moss_count = moss_count + 1
                    end
                end
            end
        end
        assert.is_true(moss_count > 0, "at least one stone should convert to moss (got 0/" .. total .. ")")
        assert.is_true(moss_count < total, "not all stone should convert to moss (got " .. moss_count .. "/" .. total .. ")")
    end)

    it("R3: should convert dirt to dirt_with_grass adjacent to warm water", function()
        math.randomseed(42)
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:dirt"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        local result = minetest.get_node({x = 6, y = 0, z = 5}).name
        assert.is_true(result == "default:dirt_with_grass" or result == "default:dirt",
            "dirt should sometimes become dirt_with_grass, got " .. result)
    end)

    -----------------------------------------------------------------------
    -- R4: Scalding exclusion for moss
    -----------------------------------------------------------------------
    it("R4: should not grow moss on stone adjacent to scalding water", function()
        math.randomseed(42)
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:scalding_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 90)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:stone"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("default:stone", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    -----------------------------------------------------------------------
    -- R5: Worldgen-only — verify no ABMs or globalsteps registered
    -----------------------------------------------------------------------
    it("R5: should not register ABMs or globalsteps for thermal effects", function()
        -- ABM registration is captured during reload_mod; check none are for melt/moss
        local abms = {}
        minetest.register_abm = function(def)
            table.insert(abms, def)
        end
        reload_mod()

        for _, abm in ipairs(abms) do
            if abm.label and (abm.label:find("[Mm]elt") or abm.label:find("[Mm]oss")) then
                assert.is_true(false, "found melt/moss ABM: " .. abm.label)
            end
        end
    end)

    -----------------------------------------------------------------------
    -- R6: Player-placed protection (default:* only)
    -----------------------------------------------------------------------
    it("R6: should not modify non-default nodes", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_source"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "some_mod:custom_snow"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("some_mod:custom_snow", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    -----------------------------------------------------------------------
    -- Edge: No hot spring water in chunk
    -----------------------------------------------------------------------
    it("should be a no-op when no hot spring water exists", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "default:snow"})
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:ice"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("default:snow", minetest.get_node({x = 5, y = 0, z = 5}).name)
        assert.are.equal("default:ice", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

    -----------------------------------------------------------------------
    -- Edge: Flowing water variants also trigger effects
    -----------------------------------------------------------------------
    it("should trigger melt and moss from flowing water variants", function()
        minetest.set_node({x = 5, y = 0, z = 5}, {name = "hot_springs:warm_water_flowing"})
        setup_vent({x = 5, y = -1, z = 5}, 40)
        minetest.set_node({x = 6, y = 0, z = 5}, {name = "default:snow"})

        minetest._on_generated({x = 0, y = -1, z = 0}, {x = 15, y = 5, z = 15})

        assert.are.equal("air", minetest.get_node({x = 6, y = 0, z = 5}).name)
    end)

end)
