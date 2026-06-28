local S = minetest.get_translator("hot_springs")

-- Configurable Steam Intensity (CID-1: Steam Config)
local defaults = {
	steam_enabled = true,
	amount_min = 0.05,
	amount_max = 0.15,
	size_min = 0.5,
	size_max = 7.0,
	exptime_min = 8.0,
	exptime_max = 16.0,
	glow = 3,
	source_interval = 10,
	source_chance = 6,
	flowing_interval = 30,
	flowing_chance = 10,
}

local clamps = {
	steam_enabled = {nil, nil},
	amount_min = {0, nil},
	amount_max = {0, nil},
	size_min = {0, nil},
	size_max = {0, nil},
	exptime_min = {0, nil},
	exptime_max = {0, nil},
	glow = {0, 14},
	source_interval = {1, nil},
	source_chance = {1, nil},
	flowing_interval = {1, nil},
	flowing_chance = {1, nil},
}

local function clamp(val, lo, hi)
	if lo and val < lo then return lo end
	if hi and val > hi then return hi end
	return val
end

local function read_float(key, default, lo, hi)
	local raw = minetest.settings:get(key)
	if raw == nil then return default end
	local n = tonumber(raw)
	if n == nil then return default end
	return clamp(n, lo, hi)
end

local function read_int(key, default, lo, hi)
	local raw = minetest.settings:get(key)
	if raw == nil then return default end
	local n = tonumber(raw)
	if n == nil then return default end
	return clamp(math.floor(n), lo, hi)
end

local function read_bool(key, default)
	local raw = minetest.settings:get_bool(key)
	if raw == nil then return default end
	return raw
end

local config = {}

config.steam_enabled = read_bool("hot_springs_steam_enabled", defaults.steam_enabled)

config.amount_min = read_float("hot_springs_steam_amount_min", defaults.amount_min, clamps.amount_min[1], clamps.amount_min[2])
config.amount_max = read_float("hot_springs_steam_amount_max", defaults.amount_max, clamps.amount_max[1], clamps.amount_max[2])
if config.amount_min > config.amount_max then
	config.amount_min, config.amount_max = config.amount_max, config.amount_min
end

config.size_min = read_float("hot_springs_steam_size_min", defaults.size_min, clamps.size_min[1], clamps.size_min[2])
config.size_max = read_float("hot_springs_steam_size_max", defaults.size_max, clamps.size_max[1], clamps.size_max[2])
if config.size_min > config.size_max then
	config.size_min, config.size_max = config.size_max, config.size_min
end

config.exptime_min = read_float("hot_springs_steam_exptime_min", defaults.exptime_min, clamps.exptime_min[1], clamps.exptime_min[2])
config.exptime_max = read_float("hot_springs_steam_exptime_max", defaults.exptime_max, clamps.exptime_max[1], clamps.exptime_max[2])
if config.exptime_min > config.exptime_max then
	config.exptime_min, config.exptime_max = config.exptime_max, config.exptime_min
end

config.glow = read_int("hot_springs_steam_glow", defaults.glow, clamps.glow[1], clamps.glow[2])
config.source_interval = read_int("hot_springs_steam_source_interval", defaults.source_interval, clamps.source_interval[1], clamps.source_interval[2])
config.source_chance = read_int("hot_springs_steam_source_chance", defaults.source_chance, clamps.source_chance[1], clamps.source_chance[2])
config.flowing_interval = read_int("hot_springs_steam_flowing_interval", defaults.flowing_interval, clamps.flowing_interval[1], clamps.flowing_interval[2])
config.flowing_chance = read_int("hot_springs_steam_flowing_chance", defaults.flowing_chance, clamps.flowing_chance[1], clamps.flowing_chance[2])

config.flowing_amount_min = read_float("hot_springs_steam_flowing_amount_min", 0.05, clamps.amount_min[1], clamps.amount_min[2])
config.flowing_amount_max = read_float("hot_springs_steam_flowing_amount_max", 0.1, clamps.amount_max[1], clamps.amount_max[2])
if config.flowing_amount_min > config.flowing_amount_max then
	config.flowing_amount_min, config.flowing_amount_max = config.flowing_amount_max, config.flowing_amount_min
end

config.flowing_exptime_min = read_float("hot_springs_steam_flowing_exptime_min", 5.0, clamps.exptime_min[1], clamps.exptime_min[2])
config.flowing_exptime_max = read_float("hot_springs_steam_flowing_exptime_max", 10.0, clamps.exptime_max[1], clamps.exptime_max[2])
if config.flowing_exptime_min > config.flowing_exptime_max then
	config.flowing_exptime_min, config.flowing_exptime_max = config.flowing_exptime_max, config.flowing_exptime_min
end

-- Scalding Warning config (CID-1 extended)
config.warning_chat_enabled = read_bool("hot_springs_warning_chat_enabled", true)
config.warning_cooldown = read_float("hot_springs_warning_cooldown", 10.0, 1.0, nil)

-- Thermal Damage config (CID-1 extended)
config.hot_damage = read_float("hot_springs_hot_damage", 0.0, 0.0, nil)
config.flowing_damage = read_float("hot_springs_flowing_damage", 0.0, 0.0, nil)
config.boiling_damage = read_float("hot_springs_boiling_damage", 3.0, 0.0, nil)
config.no_drowning = read_bool("hot_springs_no_drowning", false)

local function shallow_copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

-- Define hot water
local flowing_water = minetest.registered_nodes["default:water_flowing"]
local hot_water_flowing = shallow_copy(flowing_water)
hot_water_flowing.description = "Hot spring water"
hot_water_flowing.liquid_alternative_source = "hot_springs:hot_water_source"
hot_water_flowing.liquid_alternative_flowing = "hot_springs:hot_water_flowing"
hot_water_flowing.tiles = {"hot_springs_water.png"}
hot_water_flowing.special_tiles = {		{
    name = "hot_springs_water_flowing_animated.png",
    backface_culling = false,
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 0.5,
    },
},
{
    name = "hot_springs_water_flowing_animated.png",
    backface_culling = true,
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 0.5,
    },
},
}

hot_water_flowing.damage_per_second = config.flowing_damage
if config.no_drowning then
    hot_water_flowing.drowning = 0
end
minetest.register_node("hot_springs:hot_water_flowing", hot_water_flowing)

local water = minetest.registered_nodes["default:water_source"]
local hot_water = shallow_copy(water)
hot_water.description = "Hot spring water"
hot_water.liquid_alternative_source = "hot_springs:hot_water_source"
hot_water.liquid_alternative_flowing = "hot_springs:hot_water_flowing"
hot_water.tiles = {"hot_springs_water.png"}
hot_water.special_tiles = {		{
    name = "hot_springs_water_source_animated.png",
    backface_culling = false,
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 0.5,
    },
},
{
    name = "hot_springs_water_source_animated.png",
    backface_culling = true,
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 0.5,
    },
},
}

hot_water.damage_per_second = config.hot_damage
if config.no_drowning then
    hot_water.drowning = 0
end
minetest.register_node("hot_springs:hot_water_source", hot_water)

hot_water.description = "Boiling water source"
hot_water.damage_per_second = config.boiling_damage
if config.no_drowning then
    hot_water.drowning = 0
end
minetest.register_node("hot_springs:boiling_water_source", hot_water)

-- Steam ABMs (CID-2: Steam Spawner)
minetest.register_abm({
    nodenames = {"hot_springs:hot_water_source"},
    neighbors = {"air"},
    interval = config.source_interval,
    chance = config.source_chance,
    action = function(pos, node, active_object_count, active_object_count_wider)
        if not config.steam_enabled then return end
        minetest.add_particlespawner({
            amount = math.random(config.amount_min, config.amount_max),
            time = math.random(0, 100),
            minpos = {x=pos.x - 0.5, y=pos.y + 1, z=pos.z - 0.5},
            maxpos = {x=pos.x + 0.5, y=pos.y + 1, z=pos.z + 0.5},
            minvel = {x=0, y=0, z=-0.1},
            maxvel = {x=0.1, y=0.05, z=0.1},
            minacc = {x=0.0,y=-0.01,z=-0},
            maxacc = {x=0.0,y=0,z=-0},
            minexptime = config.exptime_min,
            maxexptime = config.exptime_max,
            minsize = config.size_min,
            maxsize = config.size_max,
            texture = "steam.png",
            glow = config.glow
        })
        end
})

minetest.register_abm({
    nodenames = {"hot_springs:hot_water_flowing"},
    neighbors = {"air"},
    interval = config.flowing_interval,
    chance = config.flowing_chance,
    action = function(pos, node, active_object_count, active_object_count_wider)
        if not config.steam_enabled then return end
        minetest.add_particlespawner({
            amount = math.random(config.flowing_amount_min, config.flowing_amount_max),
            time = math.random(0, 100),
            minpos = {x=pos.x - 0.5, y=pos.y + 1, z=pos.z - 0.5},
            maxpos = {x=pos.x + 0.5, y=pos.y + 1, z=pos.z + 0.5},
            minvel = {x=0, y=0.01, z=-0.1},
            maxvel = {x=0.1, y=0.08, z=0.1},
            minacc = {x=0.0,y=0,z=-0},
            maxacc = {x=0.0,y=0,z=-0},
            minexptime = config.flowing_exptime_min,
            maxexptime = config.flowing_exptime_max,
            minsize = config.size_min,
            maxsize = config.size_max,
            texture = "steam.png",
            glow = config.glow
        })
        end
})

-- CID-4: Scalding Warning System
local warning_cooldowns = {}

local WARNING_INTERVAL = 1.0
local BOILING_NODE = "hot_springs:boiling_water_source"

minetest.register_globalstep(function(dtime)
    if not config.steam_enabled then return end
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        if pos then
            local pos_below = {x = pos.x, y = pos.y - 1, z = pos.z}
            local node = minetest.get_node(pos)
            local node_below = minetest.get_node(pos_below)
            local in_boiling = (node and node.name == BOILING_NODE)
                or (node_below and node_below.name == BOILING_NODE)
            if in_boiling then
                if not minetest.check_player_privs(name, {creative = true}) then
                    local now = minetest.get_us_time()
                    local last = warning_cooldowns[name]
                    if not last or (now - last) >= config.warning_cooldown * 1000000 then
                        warning_cooldowns[name] = now
                        minetest.sound_play("hot_springs_hiss", {
                            to_player = name,
                            gain = 1.0,
                        })
                        minetest.add_particlespawner({
                            amount = 8,
                            time = 0.5,
                            minpos = {x = pos.x - 0.3, y = pos.y - 0.5, z = pos.z - 0.3},
                            maxpos = {x = pos.x + 0.3, y = pos.y + 0.5, z = pos.z + 0.3},
                            minvel = {x = 0, y = 0.5, z = 0},
                            maxvel = {x = 0.5, y = 1.5, z = 0.5},
                            minacc = {x = 0, y = 0, z = 0},
                            maxacc = {x = 0, y = 0, z = 0},
                            minexptime = 1.0,
                            maxexptime = 2.0,
                            minsize = 1,
                            maxsize = 3,
                            texture = "steam.png",
                            glow = 7,
                        })
                        if config.warning_chat_enabled then
                            minetest.chat_send_player(name, S("The water is scalding hot!"))
                        end
                    end
                end
            end
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    warning_cooldowns[name] = nil
end)

-- Register hot springs biome
minetest.register_biome({
    name = "hot_spring",
    node_dust = "default:snow",
    node_top = "default:desert_sandstone",
    depth_top = 2,
    node_filler = "default:dirt",
    depth_filler = 1,
    node_water_top = "hot_springs:hot_water_source",
    depth_water_top = 2,
    node_water = "hot_springs:boiling_water_source",
    node_river_water = "hot_springs:hot_water_source",
    depth_top = 2,
    node_riverbed = "default:obsidian",
    depth_riverbed = 1,
    y_max = 1000,
    y_min = -3,
    heat_point = 32,
    humidity_point = 50,
})
