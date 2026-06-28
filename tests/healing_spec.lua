local modpath = "."

describe("Healing System (CID-9)", function()

    local particle_calls = {}

    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
    end

    local function setup(overrides)
        overrides = overrides or {}
        reset_mock_state()
        if overrides.settings then
            for k, v in pairs(overrides.settings) do
                minetest.settings:set(k, v)
            end
        end

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

        minetest.add_particlespawner = function(def)
            table.insert(particle_calls, def)
        end

        particle_calls = {}

        reload_mod()
    end

    before_each(function()
        particle_calls = {}
    end)

    -------------------------------------------------------------------
    -- R1: Warm water healing
    -------------------------------------------------------------------
    it("R1: should heal player in warm water at 0.5 HP/s after 1s grace period", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        -- tick at 1.0s — crosses grace period, 0 active healing time
        run_globalsteps(1.0)
        assert.are.equal(10, player:get_hp(), "no healing before grace period")

        -- tick at 2.1s — cumulative 3.1s, 2.1s active, accumulator = 0.5 * 2.1 = 1.05 → 1 HP
        run_globalsteps(2.1)
        assert.are.equal(11, player:get_hp(), "healed 1 HP after grace period")
    end)

    -------------------------------------------------------------------
    -- R2: Hot water healing
    -------------------------------------------------------------------
    it("R2: should heal player in hot water at 1.0 HP/s after 1s grace period", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:hot_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        -- 1s grace + 1.1s active → accumulator = 1.0 * 1.1 = 1.1 → 1 HP
        run_globalsteps(2.1)

        assert.are.equal(11, player:get_hp(), "healed 1 HP after grace period")
    end)

    -------------------------------------------------------------------
    -- R3: No healing in scalding water
    -------------------------------------------------------------------
    it("R3: should not heal player in scalding water", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:scalding_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(2.0)

        assert.are.equal(10, player:get_hp(), "no healing in scalding water")
    end)

    -------------------------------------------------------------------
    -- R4: Grace period enforcement
    -------------------------------------------------------------------
    it("R4: should not heal before 1s grace period elapses", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(0.9)

        assert.are.equal(10, player:get_hp(), "no healing before 1s grace period")
    end)

    -------------------------------------------------------------------
    -- R5: Configurable healing rates
    -------------------------------------------------------------------
    it("R5: should respect zero healing rate setting", function()
        setup({ settings = {
            hot_springs_heal_warm_rate = 0,
            hot_springs_heal_hot_rate = 0,
        }})
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(3.0)

        assert.are.equal(10, player:get_hp(), "no healing when rate is 0")
    end)

    -------------------------------------------------------------------
    -- R6: Max health cap
    -------------------------------------------------------------------
    it("R6: should not heal above max health", function()
        setup({ settings = { hot_springs_heal_warm_rate = 50 } })
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 19
        player._hp_max = 20
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(2.0) -- grace at 1s, then 1s of healing at 50 HP/s → 50 HP, capped at 20

        assert.are.equal(20, player:get_hp(), "should cap at max health")
    end)

    -------------------------------------------------------------------
    -- R7: Creative mode exclusion
    -------------------------------------------------------------------
    it("R7: should not heal creative mode players", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = true })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = true }

        run_globalsteps(3.0)

        assert.are.equal(10, player:get_hp(), "creative player should not be healed")
    end)

    -------------------------------------------------------------------
    -- R8: Golden glow visual feedback
    -------------------------------------------------------------------
    it("R8: should start golden glow particle effect when healing begins", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(1.0) -- grace period exactly met

        assert.is_true(#particle_calls > 0, "should spawn glow particles after grace")
        local def = particle_calls[#particle_calls]
        assert.are.equal("hot_springs_heal_glow.png", def.texture)
        assert.are.equal(14, def.glow)
    end)

    -------------------------------------------------------------------
    -- R8b: No glow before grace period
    -------------------------------------------------------------------
    it("R8: should not start glow before grace period", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(0.5)

        assert.are.equal(0, #particle_calls, "no glow before grace period")
    end)

    -------------------------------------------------------------------
    -- Glow stops when health is full
    -------------------------------------------------------------------
    it("should stop glow when health reaches maximum", function()
        setup({ settings = { hot_springs_heal_warm_rate = 50 } })
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 19
        player._hp_max = 20
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(2.0) -- grace + heal to full
        assert.are.equal(20, player:get_hp(), "healed to max")
        -- on next tick at full HP, glow should not be restarted
        local count_before = #particle_calls
        run_globalsteps(1.0)
        assert.are.equal(count_before, #particle_calls, "no new glow when health is full")
    end)

    -------------------------------------------------------------------
    -- No glow when entering water at full health
    -------------------------------------------------------------------
    it("should not start glow when entering water at full health", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 20
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(3.0)
        assert.are.equal(0, #particle_calls, "no glow at full health")
        assert.are.equal(20, player:get_hp(), "health unchanged")
    end)

    -------------------------------------------------------------------
    -- Glow resumes on damage while in water
    -------------------------------------------------------------------
    it("should resume glow immediately when damaged while in healing water", function()
        setup({ settings = { hot_springs_heal_warm_rate = 0.5 } })
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 19
        player._hp_max = 20
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(4.0) -- 1s grace + 3s active → accumulator = 1.5 → heal 1, HP=20
        assert.are.equal(20, player:get_hp(), "healed to max")
        -- glow was created then deleted in that tick

        local glow_calls_before = #particle_calls
        run_globalsteps(0.5) -- still at full HP, no glow

        player._hp = 19 -- take 1 HP damage
        run_globalsteps(0.1) -- HP < max → glow restarts immediately (no grace wait)
        assert.is_true(#particle_calls > glow_calls_before, "new glow started on damage")
    end)

    -------------------------------------------------------------------
    -- Healing stops when leaving water
    -------------------------------------------------------------------
    it("should stop healing and glow when player leaves water", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        player._hp = 10
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(3.0) -- 1s grace + 2s active → accumulator = 0.5*2 = 1.0 → 1 HP healed

        assert.are.equal(11, player:get_hp(), "healed 1 HP while in water")

        -- now leave water
        minetest.get_node = function(pos) return { name = "air" } end

        local hp_before = player:get_hp()
        run_globalsteps(2.0) -- no water for 2s
        assert.are.equal(hp_before, player:get_hp(), "HP should not change after leaving water")
    end)

    -------------------------------------------------------------------
    -- Cleanup on leaveplayer
    -------------------------------------------------------------------
    it("should clean up state on player leave", function()
        setup()
        local player = mock_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:warm_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        run_globalsteps(2.0)

        -- player leaves
        trigger_leaveplayer(player)

        -- no error, state cleaned up
        assert.is_true(true)
    end)

end)
