local S = minetest.get_translator("hot_springs")

-- local is_glow_coal = minetest.settings:get_bool("is_glow_coal")
-- local coal_glow_level = tonumber(minetest.settings:get("coal_glow_level"))
-- if is_glow_coal then
--     --Redefine coal ore
--     ore = minetest.registered_nodes["default:stone_with_coal"]
--     description = ore.description
--     tiles = ore.tiles
--     groups = ore.groups
--     drop = ore.drop
--     is_ground_content = ore.is_ground_content
--     local paramtype = ore.paramtype
--     local use_texture_alpha = ore.use_texture_alpha
--     local drawtype = ore.drawtype
--     local sunlight_propagates = ore.sunlight_propagates
--     minetest.register_node(":default:stone_with_coal", {
--         description = description,
--         tiles = tiles,
--         groups = groups,
--         drop = drop,
--         is_ground_content = is_ground_content,
--         light_source = coal_glow_level,
--         paramtype = paramtype,
--         use_texture_alpha = use_texture_alpha,
--         drawtype = drawtype,
--         sunlight_propagates = sunlight_propagates,
--     })
-- end    

-- Define hot water
local flowing_water = minetest.registered_nodes["default:water_flowing"]
local hot_water_flowing = flowing_water
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

minetest.register_node("hot_springs:hot_water_flowing", hot_water_flowing)

local water = minetest.registered_nodes["default:water_source"]
local hot_water = water
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

minetest.register_node("hot_springs:hot_water_source", hot_water)

hot_water.description = "Boiling water source"
hot_water.damage_per_second = 5.0
hot_water.drowning = 0

minetest.register_node("hot_springs:boiling_water_source", hot_water)

minetest.register_abm({
    nodenames = {"hot_springs:hot_water_source"},
    neighbors = {"air"},
    interval = 10,
    chance = 6,
    action = function(pos, node, active_object_count, active_object_count_wider)
        minetest.log("action", "Adding steam to hot water at position "  .. pos.x .. ", " .. pos.y .. ", " .. pos.z )
        local p = pos
        minetest.add_particlespawner({
            amount = math.random(0.05, 0.15),
            time = math.random(0, 100),
            minpos = {x=pos.x - 0.5, y=pos.y + 1, z=pos.z - 0.5},
            maxpos = {x=pos.x + 0.5, y=pos.y + 1, z=pos.z + 0.5},
            minvel = {x=0, y=0, z=-0.1},
            maxvel = {x=0.1, y=0.05, z=0.1},
            minacc = {x=0.0,y=-0.01,z=-0},
            maxacc = {x=0.0,y=0,z=-0},
            minexptime = 8,
            maxexptime = 16,
            minsize = 0.5,
            maxsize = 7,
            texture = "steam.png",
            glow = 3
        })
        end
})

minetest.register_abm({
    nodenames = {"hot_springs:hot_water_flowing"},
    neighbors = {"air"},
    interval = 30,
    chance = 10,
    action = function(pos, node, active_object_count, active_object_count_wider)
        minetest.log("action", "Adding steam to hot water at position "  .. pos.x .. ", " .. pos.y .. ", " .. pos.z )
        local p = pos
        minetest.add_particlespawner({
            amount = math.random(0.05, 0.1),
            time = math.random(0, 100),
            minpos = {x=pos.x - 0.5, y=pos.y + 1, z=pos.z - 0.5},
            maxpos = {x=pos.x + 0.5, y=pos.y + 1, z=pos.z + 0.5},
            minvel = {x=0, y=0.01, z=-0.1},
            maxvel = {x=0.1, y=0.08, z=0.1},
            minacc = {x=0.0,y=0,z=-0},
            maxacc = {x=0.0,y=0,z=-0},
            minexptime = 5,
            maxexptime = 10,
            minsize = 0.5,
            maxsize = 7,
            texture = "steam.png",
            glow = 3
        })
        end
})

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