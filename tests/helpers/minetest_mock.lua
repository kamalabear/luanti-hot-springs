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
    get_node = function(pos)
        for _, entry in ipairs(minetest._nodes_in_area) do
            if entry.pos.x == pos.x and entry.pos.y == pos.y and entry.pos.z == pos.z then
                return { name = entry.name }
            end
        end
        return { name = "air" }
    end,

    -- Metadata stub.
    _node_meta = {},
    get_meta = function(pos)
        local key = pos.x .. "," .. pos.y .. "," .. pos.z
        if not minetest._node_meta[key] then
            minetest._node_meta[key] = {}
        end
        local data = minetest._node_meta[key]
        return {
            get_int = function(self, name)
                return data[name] or 0
            end,
            set_int = function(self, name, val)
                data[name] = val
            end,
            get = function(self, name)
                return data[name]
            end,
            set_string = function(self, name, val)
                data[name] = val
            end,
            _data = data,
        }
    end,

    -- Node area search stub.
    _nodes_in_area = {},
    find_nodes_in_area = function(minp, maxp, nodenames)
        local results = {}
        for _, entry in ipairs(minetest._nodes_in_area) do
            local pos = entry.pos
            local name = entry.name
            if pos.x >= minp.x and pos.x <= maxp.x
                and pos.y >= minp.y and pos.y <= maxp.y
                and pos.z >= minp.z and pos.z <= maxp.z then
                for _, nn in ipairs(nodenames) do
                    if name == nn then
                        table.insert(results, {x = pos.x, y = pos.y, z = pos.z})
                        break
                    end
                end
            end
        end
        return results
    end,

    -- Generated chunk stub.
    _on_generated = nil,
    register_on_generated = function(fn)
        minetest._on_generated = fn
    end,

    -- Node placement/dig stubs.
    _on_placenode = nil,
    _on_dignode = nil,
    register_on_placenode = function(fn)
        minetest._on_placenode = fn
    end,
    register_on_dignode = function(fn)
        minetest._on_dignode = fn
    end,

    -- Chat command stub.
    _chatcommands = {},
    register_chatcommand = function(name, def)
        minetest._chatcommands[name] = def
    end,

    -- set_node stub.
    set_node = function(pos, node)
        -- update registered node, or create a placeholder
        minetest.registered_nodes[node.name] = minetest.registered_nodes[node.name] or {name = node.name}
        -- update _nodes_in_area entries
        for i, entry in ipairs(minetest._nodes_in_area) do
            if entry.pos.x == pos.x and entry.pos.y == pos.y and entry.pos.z == pos.z then
                minetest._nodes_in_area[i] = {pos = {x = pos.x, y = pos.y, z = pos.z}, name = node.name}
                return
            end
        end
        table.insert(minetest._nodes_in_area, {pos = {x = pos.x, y = pos.y, z = pos.z}, name = node.name})
    end,
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
    minetest._node_meta = {}
    minetest._nodes_in_area = {}
    minetest._on_placenode = nil
    minetest._on_dignode = nil
    minetest._on_generated = nil
    minetest._chatcommands = {}
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
