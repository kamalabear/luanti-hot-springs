local modpath = "."

describe("Scalding Warning Effects", function()

    local captured_globalstep = nil
    local captured_leaveplayer = nil
    local sound_play_calls = {}
    local particle_calls = {}
    local chat_calls = {}

    local function reload_mod()
        package.loaded["hot_springs"] = nil
        dofile(modpath .. "/init.lua")
    end

    local function create_player(name, pos, privs)
        privs = privs or {}
        return {
            _name = name or "test_player",
            _pos = pos or { x = 0, y = 0, z = 0 },
            _privs = privs,
            get_player_name = function(self) return self._name end,
            get_pos = function(self) return self._pos end,
            is_player = function(self) return true end,
            set_pos = function(self, p) self._pos = p end,
        }
    end

    local function setup_basic_warning_env(overrides)
        overrides = overrides or {}
        reset_mock_state()
        if overrides.settings then
            for k, v in pairs(overrides.settings) do
                minetest.settings:set(k, v)
            end
        end

        -- register default water nodes so hot spring node cloning doesn't error
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

        -- capture registrations
        minetest.register_globalstep = function(fn)
            captured_globalstep = fn
        end
        minetest.register_on_leaveplayer = function(fn)
            captured_leaveplayer = fn
        end
        minetest.sound_play = function(name, params)
            table.insert(sound_play_calls, { name = name, params = params })
        end
        minetest.add_particlespawner = function(def)
            table.insert(particle_calls, def)
        end
        minetest.chat_send_player = function(name, msg)
            table.insert(chat_calls, { name = name, msg = msg })
        end

        sound_play_calls = {}
        particle_calls = {}
        chat_calls = {}

        reload_mod()
    end

    before_each(function()
        captured_globalstep = nil
        captured_leaveplayer = nil
        sound_play_calls = {}
        particle_calls = {}
        chat_calls = {}
    end)

    -------------------------------------------------------------------
    -- R1: Non-creative player in boiling water receives warning cues
    -------------------------------------------------------------------
    it("R1: should warn non-creative player in boiling_water_source", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        -- trigger one globalstep tick
        captured_globalstep(1.0)

        assert.is_true(#sound_play_calls > 0, "sound should play")
        assert.is_true(#particle_calls > 0, "particles should spawn")
        assert.is_true(#chat_calls > 0, "chat message should be sent")
    end)

    -------------------------------------------------------------------
    -- R1b: Hot water does NOT trigger warning
    -------------------------------------------------------------------
    it("R1b: should NOT warn player in hot_water_source", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:hot_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.are.equal(0, #sound_play_calls)
        assert.are.equal(0, #particle_calls)
        assert.are.equal(0, #chat_calls)
    end)

    -------------------------------------------------------------------
    -- R1c: Creative player does NOT receive warning
    -------------------------------------------------------------------
    it("R1c: should NOT warn creative player in boiling water", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = true }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.are.equal(0, #sound_play_calls)
        assert.are.equal(0, #particle_calls)
        assert.are.equal(0, #chat_calls)
    end)

    -------------------------------------------------------------------
    -- R2: Sound cue (implicitly tested via R1)
    -------------------------------------------------------------------
    it("R2: should play sound for warned player", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.are.equal("hot_springs_hiss", sound_play_calls[1].name)
        assert.are.equal("test1", sound_play_calls[1].params.to_player)
    end)

    -------------------------------------------------------------------
    -- R3: Particle burst (implicitly tested via R1)
    -------------------------------------------------------------------
    it("R3: should spawn particles near player", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 5, y = 3, z = -2 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.is_true(#particle_calls > 0)
        local p = particle_calls[1]
        -- particle centers near player feet (pos.y - 0.5)
        assert.is_true(p.minpos.x <= 5 and p.maxpos.x >= 5)
        assert.is_true(p.minpos.y <= 3 and p.maxpos.y >= 3)
        assert.is_true(p.minpos.z <= -2 and p.maxpos.z >= -2)
    end)

    -------------------------------------------------------------------
    -- R4: Chat message
    -------------------------------------------------------------------
    it("R4: should send chat message to warned player", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.are.equal("test1", chat_calls[1].name)
        assert.is_true(#chat_calls[1].msg > 0)
    end)

    -------------------------------------------------------------------
    -- R5: Cooldown prevents duplicate warnings
    -------------------------------------------------------------------
    it("R5: should not warn again within cooldown period", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        -- tick 1: warning fires at t=0
        minetest._us_time = 0
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- tick 2: still in water, only 5s passed (< default 10s cooldown)
        minetest._us_time = 5 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls, "no second warning within cooldown")
    end)

    it("R5b: should warn again after cooldown expires", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        minetest._us_time = 0
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- 15s later >> 10s cooldown
        minetest._us_time = 15 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(2, #sound_play_calls, "warning should fire after cooldown")
    end)

    -------------------------------------------------------------------
    -- R6: Chat message can be disabled via setting
    -------------------------------------------------------------------
    it("R6: should suppress chat message when setting is false", function()
        setup_basic_warning_env({ settings = { hot_springs_warning_chat_enabled = false } })

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        -- sound and particles still fire
        assert.is_true(#sound_play_calls > 0, "sound should still play")
        assert.is_true(#particle_calls > 0, "particles should still spawn")
        -- but no chat
        assert.are.equal(0, #chat_calls, "chat should be suppressed")
    end)

    -------------------------------------------------------------------
    -- R7: Cooldown duration is configurable
    -------------------------------------------------------------------
    it("R7: should respect custom cooldown setting", function()
        setup_basic_warning_env({ settings = { hot_springs_warning_cooldown = 3 } })

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }

        minetest._us_time = 0
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- 2s later (< 3s cooldown) — should NOT fire
        minetest._us_time = 2 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- 4s later (> 3s cooldown) — should fire
        minetest._us_time = 4 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(2, #sound_play_calls)
    end)

    -------------------------------------------------------------------
    -- R8: Leaveplayer cleans up cooldown state
    -------------------------------------------------------------------
    it("R8: should clean up cooldown state on player leave", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- player leaves
        captured_leaveplayer(player)

        -- rejoin (reset cooldown by cleanup)
        minetest._us_time = 2 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(2, #sound_play_calls, "warning should fire again after leave+rejoin")
    end)

    -------------------------------------------------------------------
    -- NF3: Multiplayer independence (two players independently warned)
    -------------------------------------------------------------------
    it("NF3: should independently warn two players", function()
        setup_basic_warning_env()

        local p1 = create_player("p1", { x = 0, y = 1, z = 0 }, { creative = false })
        local p2 = create_player("p2", { x = 5, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { p1, p2 } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["p1"] = { creative = false }
        minetest._player_privs["p2"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        -- each player should have sound + particle + chat
        local p1_calls = 0
        local p2_calls = 0
        for _, c in ipairs(sound_play_calls) do
            if c.params.to_player == "p1" then p1_calls = p1_calls + 1 end
            if c.params.to_player == "p2" then p2_calls = p2_calls + 1 end
        end
        assert.are.equal(1, p1_calls)
        assert.are.equal(1, p2_calls)
    end)

    -------------------------------------------------------------------
    -- NF1: No per-tick log spam
    -------------------------------------------------------------------
    it("NF1: should not produce per-tick action log messages", function()
        setup_basic_warning_env()

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        -- capture log calls
        local log_calls = {}
        minetest.log = function(level, msg)
            table.insert(log_calls, { level = level, msg = msg })
        end

        captured_globalstep(1.0)

        -- any warning-related prefix is fine; we just check no action-level spam
        for _, call in ipairs(log_calls) do
            assert.is_false(call.msg:find("Scalding warning triggered for"))
        end
    end)

    -------------------------------------------------------------------
    -- NF4: Graceful degradation when sound file is missing (engine handles it)
    -------------------------------------------------------------------
    it("NF4: should not error when sound is missing or unplayable", function()
        setup_basic_warning_env()
        -- Simulate: sound_play returns nil (engine behavior when file missing)
        -- This shouldn't error the globalstep
        local sound_errored = false
        minetest.sound_play = function(name, params)
            sound_errored = true
            return nil
        end

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        assert.has_no_errors(function()
            captured_globalstep(1.0)
        end)

        -- other cues should still fire
        assert.is_true(#particle_calls > 0, "particles should still spawn")
        assert.is_true(#chat_calls > 0, "chat should still be sent")
    end)

    -------------------------------------------------------------------
    -- Steam disabled: no warnings
    -------------------------------------------------------------------
    it("should not warn when steam is disabled", function()
        setup_basic_warning_env({ settings = { hot_springs_steam_enabled = false } })

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)

        assert.are.equal(0, #sound_play_calls)
        assert.are.equal(0, #particle_calls)
        assert.are.equal(0, #chat_calls)
    end)

    -------------------------------------------------------------------
    -- Cooldown minimum clamp (R7)
    -------------------------------------------------------------------
    it("R7: should clamp cooldown to minimum 1 second", function()
        setup_basic_warning_env({ settings = { hot_springs_warning_cooldown = 0 } })

        local player = create_player("test1", { x = 0, y = 1, z = 0 }, { creative = false })
        minetest.get_connected_players = function() return { player } end
        minetest.get_node = function(pos) return { name = "hot_springs:boiling_water_source" } end
        minetest._player_privs["test1"] = { creative = false }
        minetest._us_time = 0

        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- 0.5s later (< 1s clamped cooldown) — should NOT fire
        minetest._us_time = 0.5 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(1, #sound_play_calls)

        -- 1.5s later (> 1s clamped cooldown) — should fire
        minetest._us_time = 1.5 * 1000000
        captured_globalstep(1.0)
        assert.are.equal(2, #sound_play_calls)
    end)

    -------------------------------------------------------------------
    -- Load without errors (NF2)
    -------------------------------------------------------------------
    it("NF2: should load without errors with no warning-specific settings", function()
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
