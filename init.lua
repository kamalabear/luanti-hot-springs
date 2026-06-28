local S = minetest.get_translator("hot_springs")

hot_springs = {}

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
	temp_warm_min = 30,
	temp_hot_min = 50,
	temp_scalding_min = 80,
	temp_gradient = 5.0,
	vent_scan_radius = 20,
	vent_spread_radius = 200,
	vent_max_count = 2,
	heal_warm_rate = 0.5,
	heal_hot_rate = 1.0,
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
	temp_warm_min = {1, nil},
	temp_hot_min = {1, nil},
	temp_scalding_min = {1, nil},
	temp_gradient = {0.1, nil},
	vent_scan_radius = {1, nil},
	vent_spread_radius = {1, 225},
	vent_max_count = {1, nil},
	heal_warm_rate = {0, 20},
	heal_hot_rate = {0, 20},
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

-- Variable Temperature thresholds (CID-1 extended)
config.temp_warm_min = read_float("hot_springs_temp_warm_min", defaults.temp_warm_min, clamps.temp_warm_min[1], clamps.temp_warm_min[2])
config.temp_hot_min = read_float("hot_springs_temp_hot_min", defaults.temp_hot_min, clamps.temp_hot_min[1], clamps.temp_hot_min[2])
config.temp_scalding_min = read_float("hot_springs_temp_scalding_min", defaults.temp_scalding_min, clamps.temp_scalding_min[1], clamps.temp_scalding_min[2])

local t = {config.temp_warm_min, config.temp_hot_min, config.temp_scalding_min}
table.sort(t)
config.temp_warm_min = t[1]
config.temp_hot_min = t[2]
config.temp_scalding_min = t[3]

-- Temperature Gradient settings (CID-1 extended)
config.temp_gradient = read_float("hot_springs_temp_gradient", defaults.temp_gradient, clamps.temp_gradient[1], clamps.temp_gradient[2])
config.vent_scan_radius = read_int("hot_springs_vent_scan_radius", defaults.vent_scan_radius, clamps.vent_scan_radius[1], clamps.vent_scan_radius[2])

-- Vent spread config (CID-1 extended)
config.vent_spread_radius = read_int("hot_springs_vent_spread_radius", defaults.vent_spread_radius, clamps.vent_spread_radius[1], clamps.vent_spread_radius[2])
config.vent_max_count = read_int("hot_springs_vent_max_count", defaults.vent_max_count, clamps.vent_max_count[1], clamps.vent_max_count[2])

-- Healing config (CID-1 extended)
config.heal_warm_rate = read_float("hot_springs_heal_warm_rate", defaults.heal_warm_rate, clamps.heal_warm_rate[1], clamps.heal_warm_rate[2])
config.heal_hot_rate = read_float("hot_springs_heal_hot_rate", defaults.heal_hot_rate, clamps.heal_hot_rate[1], clamps.heal_hot_rate[2])

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

-- Safe bounds for find_nodes_in_area (~129M nodes, under 150M engine limit)
local SCAN_BOUNDS = {
	minp = {x = -500, y = -64, z = -500},
	maxp = {x = 500, y = 64, z = 500},
}

-- Node name lists for worldgen scanning
local WATER_NODE_NAMES = {
    "default:water_source",
    "default:water_flowing",
    "hot_springs:warm_water_source",
    "hot_springs:warm_water_flowing",
    "hot_springs:hot_water_source",
    "hot_springs:hot_water_flowing",
    "hot_springs:scalding_water_source",
    "hot_springs:scalding_water_flowing",
}

-- Shared falloff computation: nearest vent within radius, gradient applied
local function compute_falloff_temp(pos, vent_list, static_temp)
    local best_dist = nil
    local best_temp = nil
    local radius = config.vent_scan_radius
    for _, vent in ipairs(vent_list) do
        local dx = vent.pos.x - pos.x
        local dy = vent.pos.y - pos.y
        local dz = vent.pos.z - pos.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        if dist <= radius then
            if best_dist == nil or dist < best_dist then
                best_dist = dist
                best_temp = vent.temperature
            end
        end
    end
    if best_temp ~= nil then
        return math.max(0, best_temp - best_dist * config.temp_gradient)
    end
    return static_temp
end

-- CID-5: Variable Temperature API
local node_temperatures = {
	["hot_springs:warm_water_source"] = 40,
	["hot_springs:warm_water_flowing"] = 40,
	["hot_springs:hot_water_source"] = 60,
	["hot_springs:hot_water_flowing"] = 60,
	["hot_springs:scalding_water_source"] = 90,
	["hot_springs:scalding_water_flowing"] = 90,
}

local vent_cache = nil

local function rebuild_vent_cache()
	local c = {}
	local vents = minetest.find_nodes_in_area(
		SCAN_BOUNDS.minp,
		SCAN_BOUNDS.maxp,
		{"hot_springs:vent_block"}
	)
	for _, pos in ipairs(vents) do
		local meta = minetest.get_meta(pos)
		c[#c + 1] = {
			pos = pos,
			temperature = meta:get_int("hot_springs_temperature"),
		}
	end
	vent_cache = c
end

function hot_springs.get_pool_temperature(node_name, pos)
	if pos == nil then
		return node_temperatures[node_name]
	end
	local meta = minetest.get_meta(pos)
	local meta_temp = meta:get_int("hot_springs_temperature")
	if meta_temp ~= 0 then
		return meta_temp
	end
	if vent_cache == nil then
		rebuild_vent_cache()
	end
	return compute_falloff_temp(pos, vent_cache or {}, node_temperatures[node_name])
end

function hot_springs.classify_temperature(temp)
	if temp < config.temp_warm_min then return "cool" end
	if temp < config.temp_hot_min then return "warm" end
	if temp < config.temp_scalding_min then return "hot" end
	return "scalding"
end

minetest.register_on_placenode(function(pos, newnode)
	if newnode.name == "hot_springs:vent_block" then
		vent_cache = nil
	end
end)

minetest.register_on_dignode(function(pos, oldnode)
	if oldnode.name == "hot_springs:vent_block" then
		vent_cache = nil
	end
end)

local function shallow_copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end

-- CID-3: Water Nodes

-- vent_block: a non-flowing heat source
minetest.register_node("hot_springs:vent_block", {
	description = S("Hot Spring Vent"),
	tiles = {"hot_springs_vent_block.png"},
	groups = {cracky = 2, hot = 1},
	sounds = default and default.node_sound_stone_defaults() or nil,
})

-- Helper to build a flowing water node definition
local function make_flowing(name, tiles_prefix, alt_source)
	local flowing = shallow_copy(minetest.registered_nodes["default:water_flowing"])
	flowing.description = name
	flowing.liquid_alternative_source = alt_source
	flowing.liquid_alternative_flowing = "hot_springs:" .. tiles_prefix .. "_water_flowing"
	flowing.tiles = {
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_flowing_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	}
	flowing.special_tiles = {
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_flowing_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	}
	flowing.damage_per_second = config.flowing_damage
	flowing.groups = flowing.groups or {}
	flowing.groups.hot_springs_water = 1
	if config.no_drowning then
		flowing.drowning = 0
	end
	return flowing
end

-- Helper to build a source water node definition
local function make_source(name, tiles_prefix, alt_flowing)
	local source = shallow_copy(minetest.registered_nodes["default:water_source"])
	source.description = name
	source.liquid_alternative_source = "hot_springs:" .. tiles_prefix .. "_water_source"
	source.liquid_alternative_flowing = alt_flowing
	source.tiles = {
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	}
	source.special_tiles = {
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_source_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "hot_springs_" .. tiles_prefix .. "_water_source_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	}
	source.damage_per_second = config.hot_damage
	source.groups = source.groups or {}
	source.groups.hot_springs_water = 1
	if config.no_drowning then
		source.drowning = 0
	end
	return source
end

-- Flowing variants
local warm_flowing = make_flowing(S("Warm spring water"), "warm", "hot_springs:warm_water_source")
warm_flowing.damage_per_second = config.flowing_damage
minetest.register_node("hot_springs:warm_water_flowing", warm_flowing)

local hot_flowing = make_flowing(S("Hot spring water"), "hot", "hot_springs:hot_water_source")
hot_flowing.damage_per_second = config.flowing_damage
minetest.register_node("hot_springs:hot_water_flowing", hot_flowing)

local scalding_flowing = make_flowing(S("Scalding spring water"), "scalding", "hot_springs:scalding_water_source")
scalding_flowing.damage_per_second = config.flowing_damage
minetest.register_node("hot_springs:scalding_water_flowing", scalding_flowing)

-- Source variants
local warm_source = make_source(S("Warm spring water"), "warm", "hot_springs:warm_water_flowing")
warm_source.damage_per_second = config.hot_damage
minetest.register_node("hot_springs:warm_water_source", warm_source)

local hot_source = make_source(S("Hot spring water"), "hot", "hot_springs:hot_water_flowing")
hot_source.damage_per_second = config.hot_damage
minetest.register_node("hot_springs:hot_water_source", hot_source)

local scalding_source = make_source(S("Scalding spring water"), "scalding", "hot_springs:scalding_water_flowing")
scalding_source.description = S("Scalding spring water")
scalding_source.damage_per_second = config.boiling_damage
minetest.register_node("hot_springs:scalding_water_source", scalding_source)

-- Steam ABMs (CID-2: Steam Spawner)
minetest.register_abm({
	nodenames = {"hot_springs:hot_water_source", "hot_springs:scalding_water_source"},
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
	nodenames = {"group:hot_springs_water"},
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
local SCALDING_NODE = "hot_springs:scalding_water_source"

minetest.register_globalstep(function(dtime)
	if not config.steam_enabled then return end
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:get_pos()
		if pos then
			local pos_below = {x = pos.x, y = pos.y - 1, z = pos.z}
			local node = minetest.get_node(pos)
			local node_below = minetest.get_node(pos_below)
			local in_scalding = (node and node.name == SCALDING_NODE)
				or (node_below and node_below.name == SCALDING_NODE)
			if in_scalding then
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

-- CID-7: Migration Command
minetest.register_chatcommand("hot_springs_migrate", {
	params = "",
	description = S("Replace old hot spring node names with new variants"),
	privs = {server = true},
	func = function(name)
		local old_to_new = {
			["hot_springs:hot_water_source"] = "hot_springs:warm_water_source",
			["hot_springs:hot_water_flowing"] = "hot_springs:warm_water_flowing",
			["hot_springs:boiling_water_source"] = "hot_springs:scalding_water_source",
		}
		local count = 0
		for old_name, new_name in pairs(old_to_new) do
			local positions = minetest.find_nodes_in_area(
				SCAN_BOUNDS.minp,
				SCAN_BOUNDS.maxp,
				{old_name}
			)
			for _, pos in ipairs(positions) do
				minetest.set_node(pos, {name = new_name})
				count = count + 1
			end
		end
		minetest.chat_send_player(name, S("Migrated @1 nodes to new hot spring variants", count))
	end,
})

-- CID-6: Register hot springs biome
minetest.register_biome({
	name = "hot_spring",
	node_dust = "default:snow",
	node_top = "default:desert_sandstone",
	depth_top = 2,
	node_filler = "default:dirt",
	depth_filler = 1,
	node_water_top = "hot_springs:warm_water_source",
	depth_water_top = 2,
	node_water = "hot_springs:scalding_water_source",
	node_river_water = "hot_springs:warm_water_source",
	depth_top = 2,
	node_riverbed = "default:obsidian",
	depth_riverbed = 1,
	y_max = 1000,
	y_min = -3,
	heat_point = 32,
	humidity_point = 50,
})

-- CID-8: Gradient Worldgen — post-process each chunk to apply vent-driven water node replacement
minetest.register_on_generated(function(minp, maxp)
	local margin = config.vent_scan_radius
	local spread = config.vent_spread_radius
	local max_vents = config.vent_max_count

	-- Place vents at the bottom of hot spring pools if below the vent count limit
	local hs_pool_names = {"hot_springs:warm_water_source", "hot_springs:scalding_water_source"}
	local pool_nodes = minetest.find_nodes_in_area(minp, maxp, hs_pool_names)
	if #pool_nodes > 0 then
		local existing_vents = minetest.find_nodes_in_area(
			{x = minp.x - spread, y = minp.y - spread, z = minp.z - spread},
			{x = maxp.x + spread, y = maxp.y + spread, z = maxp.z + spread},
			{"hot_springs:vent_block"}
		)
		if #existing_vents < max_vents then
			-- Find the lowest water node in the pool
			local lowest = pool_nodes[1]
			for _, pos in ipairs(pool_nodes) do
				if pos.y < lowest.y then lowest = pos end
			end
			-- Place vent below the lowest water node
			local vpos = {x = lowest.x, y = lowest.y - 1, z = lowest.z}
			local below = minetest.get_node(vpos)
			if below.name ~= "air" and below.name ~= "ignore" and below.name:find("^default:") then
				minetest.set_node(vpos, {name = "hot_springs:vent_block"})
				local vent_temp = math.random(config.temp_warm_min, 100)
				minetest.get_meta(vpos):set_int("hot_springs_temperature", vent_temp)
			end
		end
	end

	-- Build vent list (including any just-placed vent)
	local water_positions = minetest.find_nodes_in_area(minp, maxp, WATER_NODE_NAMES)
	if #water_positions == 0 then return end

	local vents = {}
	local vent_raw = minetest.find_nodes_in_area(
		{x = minp.x - margin, y = minp.y - margin, z = minp.z - margin},
		{x = maxp.x + margin, y = maxp.y + margin, z = maxp.z + margin},
		{"hot_springs:vent_block"}
	)
	for _, pos in ipairs(vent_raw) do
		vents[#vents + 1] = {
			pos = pos,
			temperature = minetest.get_meta(pos):get_int("hot_springs_temperature"),
		}
	end

	-- Stage 1: temperature-driven node replacement
	local pending = {}
	for _, pos in ipairs(water_positions) do
		local node = minetest.get_node(pos)
		if node.name ~= "air" and node.name ~= "ignore" then
			local is_flowing = node.name:find("_flowing$")
			local suffix = is_flowing and "_water_flowing" or "_water_source"
			local static_temp = node_temperatures[node.name] or 20
			local temp = compute_falloff_temp(pos, vents, static_temp)
			local class = hot_springs.classify_temperature(temp)

			local new_name
			if class == "cool" then
				new_name = is_flowing and "default:water_flowing" or "default:water_source"
			else
				new_name = "hot_springs:" .. class .. suffix
			end

			if new_name ~= node.name then
				pending[#pending + 1] = {pos = pos, name = new_name}
			end
		end
	end

	for _, entry in ipairs(pending) do
		minetest.set_node(entry.pos, {name = entry.name})
	end
end)

-- CID-9: Healing System
local heal_state = {}

local function is_healing_water(node_name)
	return node_name == "hot_springs:warm_water_source"
		or node_name == "hot_springs:warm_water_flowing"
		or node_name == "hot_springs:hot_water_source"
		or node_name == "hot_springs:hot_water_flowing"
end

local function get_heal_rate(node_name)
	if node_name == "hot_springs:hot_water_source" or node_name == "hot_springs:hot_water_flowing" then
		return config.heal_hot_rate
	end
	return config.heal_warm_rate
end

local HEAL_TICK = 1.0
local GRACE_PERIOD = 1.0
local GLOW_PARTICLES = {}
local GLOW_POS = {}
local GLOW_MOVE_THRESHOLD = 0.5

local function spawn_glow(name, pos)
	if GLOW_PARTICLES[name] then
		minetest.delete_particlespawner(GLOW_PARTICLES[name])
	end
	GLOW_PARTICLES[name] = minetest.add_particlespawner({
		amount = 10,
		time = 0,
		minpos = {x = pos.x - 0.8, y = pos.y + 0.3, z = pos.z - 0.8},
		maxpos = {x = pos.x + 0.8, y = pos.y + 0.8, z = pos.z + 0.8},
		minvel = {x = -0.2, y = 0.3, z = -0.2},
		maxvel = {x = 0.2, y = 0.7, z = 0.2},
		minacc = {x = 0, y = 0.1, z = 0},
		maxacc = {x = 0, y = 0.2, z = 0},
		minexptime = 1.0,
		maxexptime = 1.8,
		minsize = 0.8,
		maxsize = 2.0,
		texture = "hot_springs_heal_glow.png",
		glow = 14,
	})
	GLOW_POS[name] = pos
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		if minetest.check_player_privs(name, {creative = true}) then
			-- skip creative players
		else
			local pos = player:get_pos()
			if pos then
				local node = minetest.get_node(pos)
				local node_below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
				local water_node = nil
				if is_healing_water(node.name) then
					water_node = node.name
				elseif is_healing_water(node_below.name) then
					water_node = node_below.name
				end

				if water_node then
					local state = heal_state[name]
					if not state then
						state = {timer = 0, active = false, accumulator = 0}
						heal_state[name] = state
					end
					local prev_timer = state.timer
					state.timer = state.timer + dtime
					if state.timer >= GRACE_PERIOD then
						local max_hp = player:get_properties().hp_max or 20
						local hp = player:get_hp()

						if hp < max_hp then
							if not state.active then
								state.active = true
								spawn_glow(name, pos)
							elseif not GLOW_PARTICLES[name] then
								spawn_glow(name, pos)
							elseif GLOW_POS[name] then
								local dx = pos.x - GLOW_POS[name].x
								local dz = pos.z - GLOW_POS[name].z
								if dx * dx + dz * dz >= GLOW_MOVE_THRESHOLD * GLOW_MOVE_THRESHOLD then
									spawn_glow(name, pos)
								end
							end
							local rate = get_heal_rate(water_node)
							local active_start = math.max(prev_timer, GRACE_PERIOD)
							local active_dtime = state.timer - active_start
							state.accumulator = state.accumulator + rate * active_dtime
							if state.accumulator >= 1 then
								local heal = math.floor(state.accumulator)
								local new_hp = math.min(hp + heal, max_hp)
								player:set_hp(new_hp)
								state.accumulator = state.accumulator - heal
								if new_hp >= max_hp and GLOW_PARTICLES[name] then
									minetest.delete_particlespawner(GLOW_PARTICLES[name])
									GLOW_PARTICLES[name] = nil
									GLOW_POS[name] = nil
								end
							end
						elseif GLOW_PARTICLES[name] then
							minetest.delete_particlespawner(GLOW_PARTICLES[name])
							GLOW_PARTICLES[name] = nil
							GLOW_POS[name] = nil
						end
					end
				else
					local state = heal_state[name]
					if state then
						if state.active and GLOW_PARTICLES[name] then
							minetest.delete_particlespawner(GLOW_PARTICLES[name])
							GLOW_PARTICLES[name] = nil
							GLOW_POS[name] = nil
						end
						heal_state[name] = nil
					end
				end
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if GLOW_PARTICLES[name] then
		minetest.delete_particlespawner(GLOW_PARTICLES[name])
		GLOW_PARTICLES[name] = nil
		GLOW_POS[name] = nil
	end
	heal_state[name] = nil
end)
