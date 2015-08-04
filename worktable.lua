local material = {
	"cloud", -- Only used for the formspec display.
	"wood", "junglewood", "pinewood", "acacia_wood",
	"tree", "jungletree", "pinetree", "acacia_tree",
	"cobble", "mossycobble", "desert_cobble",
	"stone", "sandstone", "desert_stone", "obsidian",
	"stonebrick", "sandstonebrick", "desert_stonebrick", "obsidianbrick",
	"snowblock", "coalblock", "copperblock", "steelblock", "goldblock", 
	"bronzeblock", "mese", "diamondblock",
	"brick", "cactus", "clay", "ice", "meselamp",
	"glass", "obsidian_glass"
}

local def = { -- Node name, yield, nodebox shape.
	{"nanoslab", "16", {-0.5, -0.5, -0.5, 0, -0.4375, 0}},
	{"micropanel", "16", {-0.5, -0.5, -0.5, 0.5, -0.4375, 0}},
	{"microslab", "8", {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}},
	{"panel", "4", {-0.5, -0.5, -0.5, 0.5, 0, 0}},
	{"slab", "2", {-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
	{"outerstair", "1", {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}, {-0.5, 0, 0, 0, 0.5, 0.5}}},
	{"stair", "1", {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}, {-0.5, 0, 0, 0.5, 0.5, 0.5}}},
	{"innerstair", "1", {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}, {-0.5, 0, 0, 0.5, 0.5, 0.5}, {-0.5, 0, -0.5, 0, 0.5, 0}}}
}

local function xconstruct(pos)
	local meta = minetest.get_meta(pos)

	local nodebtn = {}
	for i=1, #def do
		nodebtn[#nodebtn+1] = "item_image_button["..(i-1)..
				",0.5;1,1;xdecor:"..def[i][1].."_cloud;"..def[i][1]..";]"
	end
	nodebtn = table.concat(nodebtn)

	meta:set_string("formspec", "size[8,7;]"..xdecor.fancy_gui..
		"label[0,0;Cut your material into...]"..
		nodebtn..
		"label[0,1.5;Input]"..
		"list[current_name;input;0,2;1,1;]"..
		"image[1,2;1,1;xdecor_saw.png]"..
		"label[2,1.5;Output]"..
		"list[current_name;output;2,2;1,1;]"..
		"label[5,1.5;Tool]"..
		"list[current_name;tool;5,2;1,1;]"..
		"image[6,2;1,1;xdecor_anvil.png]"..
		"label[6.8,1.5;Hammer]]"..
		"list[current_name;hammer;7,2;1,1;]"..
		"list[current_player;main;0,3.25;8,4;]")
	meta:set_string("infotext", "Work Table")

	local inv = meta:get_inventory()
	inv:set_size("output", 1)
	inv:set_size("input", 1)
	inv:set_size("tool", 1)
	inv:set_size("hammer", 1)
end

local function xfields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local inputstack = inv:get_stack("input", 1)
	local outputstack = inv:get_stack("output", 1)
	local outputcount = outputstack:get_count()
	local inputname = inputstack:get_name()
	local shape, get = {}, {}
	local anz = 0

	for _, d in pairs(def) do
		local nb, anz = d[1], d[2]
		if outputcount < 99 and fields[nb] then
			shape = "xdecor:"..nb.."_"..string.sub(inputname, 9)
			get = shape.." "..anz

			if not minetest.registered_nodes[shape] then return end
			inv:add_item("output", get)
			inputstack:take_item()
			inv:set_stack("input", 1, inputstack)
		end
	end
end

local function xdig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	if not inv:is_empty("input") or not inv:is_empty("output") or not
			inv:is_empty("hammer") or not inv:is_empty("tool") then
		return false
	end
	return true
end

local function xput(pos, listname, index, stack, player)
	local stackname = stack:get_name()
	local count = stack:get_count()

	if listname == "output" then return 0 end
	if listname == "input" then
		if string.find(stackname, "default:") then return count
			else return 0 end
	end
	if listname == "hammer" then
		if not (stackname == "xdecor:hammer") then return 0 end
	end
	if listname == "tool" then
		local tdef = minetest.registered_tools[stackname]
		local twear = stack:get_wear()
		if not (tdef and twear > 0) then return 0 end
	end

	return count
end

xdecor.register("worktable", {
	description = "Work Table",
	groups = {cracky=2},
	sounds = xdecor.wood,
	tiles = {
		"xdecor_worktable_top.png", "xdecor_worktable_top.png",
		"xdecor_worktable_sides.png", "xdecor_worktable_sides.png",
		"xdecor_worktable_front.png", "xdecor_worktable_front.png"
	},
	on_construct = xconstruct,
	on_receive_fields = xfields,
	can_dig = xdig,
	allow_metadata_inventory_put = xput
})

for _, m in pairs(material) do
for n=1, #def do
	local w = def[n]
	local nodename = "default:"..m
	local ndef = minetest.registered_nodes[nodename]
	if not ndef then return end

	xdecor.register(w[1].."_"..m, {
		description = string.sub(string.upper(w[1]), 0, 1)..string.sub(w[1], 2),
		light_source = ndef.light_source,
		sounds = ndef.sounds,
		tiles = ndef.tiles,
		groups = {snappy=3, not_in_creative_inventory=1},
		node_box = {
			type = "fixed",
			fixed = w[3]
		},
		on_place = minetest.rotate_node
	})
end
end

minetest.register_abm({
	nodenames = {"xdecor:worktable"},
	interval = 3, chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local tool = inv:get_stack("tool", 1)
		local hammer = inv:get_stack("hammer", 1)
		local wear = tool:get_wear()
		local wear2 = hammer:get_wear()

		local repair = -500 -- Tool's repairing factor (0-65535 -- 0 = new condition).
		local wearhammer = 250 -- Hammer's wearing factor (0-65535 -- 0 = new condition).

		if tool:is_empty() or hammer:is_empty() or wear == 0 then return end

		tool:add_wear(repair)
		hammer:add_wear(wearhammer)

		inv:set_stack("tool", 1, tool)
		inv:set_stack("hammer", 1, hammer)
	end
})
