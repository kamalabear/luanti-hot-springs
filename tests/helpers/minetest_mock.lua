-- Minimal minetest API mock for busted unit tests.
-- Loaded automatically via the `helper` field in .busted config.
--
-- Tests can call reset_mock_settings() and reset_mock_nodes() between cases,
-- or override specific stubs directly on _G.minetest.

_G.minetest = {
    LIGHT_MAX = 14,

    -- Swallow logs by default. Set to `print` to debug test runs.
    log = function(level, msg) end,

    -- Settings stub. Use reset_mock_settings({key=val}) to set test values.
    settings = {
        _data = {},
        get = function(self, key)
            return self._data[key]
        end,
        get_bool = function(self, key, default)
            local v = self._data[key]
            if v == nil then return default end
            return v
        end,
        set = function(self, key, value)
            self._data[key] = value
        end,
    },

    -- Translation: returns an identity function.
    get_translator = function(modname)
        return function(s) return s end
    end,

    -- Node registry stubs.
    registered_nodes = {},
    registered_ores  = {},
    register_node    = function(name, def)
        minetest.registered_nodes[name] = def
    end,
    register_abm     = function(def) end,
    register_biome   = function(def) end,
    register_on_mods_loaded = function(fn) fn() end,

    -- Player stubs.
    get_connected_players = function() return {} end,

    -- Particle stub.
    add_particlespawner = function(def) end,

    -- Chat stubs.
    chat_send_player = function(name, msg) end,
    chat_send_all    = function(msg) end,

    -- Globalstep stub.
    register_globalstep = function(fn) end,

    -- Leaveplayer stub.
    register_on_leaveplayer = function(fn) end,

    -- Sound stub.
    sound_play = function(name, params) end,

    -- Time stub (microseconds since arbitrary epoch).
    _us_time = 0,
    get_us_time = function() return minetest._us_time end,

    -- Privilege stub: checks against _player_privs[name].
    _player_privs = {},
    check_player_privs = function(name, privs)
        local p = minetest._player_privs[name] or {}
        for k, v in pairs(privs) do
            if p[k] ~= v then return false end
        end
        return true
    end,

    -- Node query stubs.
    get_node = function(pos) return { name = "air" } end,
}

--- Reset settings data between tests.
function reset_mock_settings(data)
    minetest.settings._data = data or {}
end

--- Reset registered node table between tests.
function reset_mock_nodes()
    minetest.registered_nodes = {}
    minetest.registered_ores  = {}
end

--- Reset all mock state (settings, nodes, privs, time).
function reset_mock_state()
    minetest.settings._data = {}
    minetest.registered_nodes = {}
    minetest.registered_ores  = {}
    minetest._player_privs = {}
    minetest._us_time = 0
end

--- Create a mock player object for testing.
-- @param name Player name
-- @param pos Position table {x,y,z} (default {0,0,0})
-- @param privs Table of privilege overrides (default {creative=false})
-- @return player object
function mock_player(name, pos, privs)
    privs = privs or {}
    return {
        _name = name or "test_player",
        _pos = pos or { x = 0, y = 0, z = 0 },
        _privs = privs,
        get_player_name = function(self) return self._name end,
        get_pos = function(self) return self._pos end,
        is_player = function(self) return true end,
        set_pos = function(self, p) self._pos = p end,
        set_privs = function(self, p) self._privs = p end,
    }
end
