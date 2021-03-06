-------------------------------
-- External Includes ----------
-------------------------------

require("cupid.debug")

-------------------------------
-- Includes -------------------
-------------------------------

require "defines"
local EventHandler = require "event"

-------------------------------
-- Short Forms ----------------
-------------------------------
local lg = love.graphics
local lw = love.window
local lt = love.timer
local lm = love.mouse
local le = love.event
local li = love.image

-------------------------------
-- Resources ---------
-------------------------------

local resources = {
	player = {
		animation = {}
	}
}

local tiles = {
	[0] = {name = "void"},
	{name = "dirt", fname = "resources/dirt.png"},
	{name = "rock", fname = "resources/rock.png"},
	{name = "sandstone", fname = "resources/sandstone_maybe.png"},
	{name = "chest", fname = "resources/chest.png"},
	{name = "chest_open", fname = "resources/chest_open.png"},
	{name = "ornate_tile", fname = "resources/ornate_tile.png"},
	{name = "floor_tile", fname = "resources/floor_tile.png"},
	{name = "floor_pillar", fname = "resources/floor_pillar.png"},
	{},
	{name = "sandstone_wall", fname = "resources/sandstone_wall.png"},
	{name = "other_pillar", fname = "resources/other_pillar.png"},
	{name = "bench", fname = "resources/bench.png"},
	{},
	{},
	{name = "pillar_thing", fname = "resources/pillar_thing.png"},
	{name = "lamp", fname = "resources/lamp.png"}
}

-------------------------------
-- Global game variables! -----
-------------------------------

-- HUE HUE UHE IS GLOBAL
event_handler = EventHandler:new()

local camera = Camera(0, 0, 1)
local player = nil

local camera_state = {
	-- mouse position on click, will be used as relative to drag position for camera movement
	last_m_x = 0,
	last_m_y = 0
}

local objects = {}
local ui_objects = {}
local resources = {}
local tile_resources = {}
local lighting_imagedata = {}
local lighting_image = {}
local default_font = {}

local map_data = require "data/level"

-- process map data, awful place but fuck it

-- WOW FUCKING LUA AND 1 INDEXING YES
local layer = map_data.layers[1]
local tileset = map_data.tilesets[1]

local tile_map = {

	-- fuck you tiled ok
	tile_width = tileset.tilewidth,
	tile_height = tileset.tileheight,

	data = layer.data,
	width = layer.width,
	height = layer.height

}

-------------------------------
-- Game object definitions ----
-------------------------------

local Object = require "object"
local Player = require "player"
local Wiseman = require "wiseman"
local Dialog = require "dialog"
local Mouse = require "mouse"

-------------------------------
-- Game functions here! -------
-------------------------------

function load_resources()

	-- load the tiles and shit
	for id, tile in pairs(tiles) do
		if tile.fname then
			print ("loaded resource: " .. tile.fname)
			tile_resources[id] = lg.newImage(tile.fname)
		end
	end

	resources.player_spritesheet = lg.newImage("resources/professor_octopus.png")
	resources.wiseman_spritesheet = lg.newImage("resources/wiseman.png")
	resources.dialog_font = lg.newFont("resources/VolterGoldfish.ttf", 24)
	default_font = lg.getFont()

end

function setup_game()

	-- load images and such
	load_resources()

	-- ... create player?
	local spritesheet_frames = 15 -- I LOVE ME SOME MAGIC NUMBERS
	local sprite_frame_dim = 32

	local make_quads = function(frame_count, spritesheet)
		local quads = {}
		for i = 1, frame_count - 1 do
			quads[#quads+1] = lg.newQuad((i-1) * 32, 0, sprite_frame_dim, sprite_frame_dim, spritesheet:getDimensions())
		end 
		return quads
	end

	local spritesheet = {
		image = resources.player_spritesheet,
		frame_count = spritesheet_frames,
		quads = make_quads(spritesheet_frames, resources.player_spritesheet)
	}

	-- add all the quads and shit
	player = Player:new(spritesheet, 176, 176)
	event_handler:subscribe("on_approach", function(event) player:on_event(event) end)
	objects[#objects+1] = player

	-- MORE MAGIC FUCK
	local wiseman_frames = 14

	-- wiseman spritesheet
	local wiseman_spritesheet = {
		image = resources.wiseman_spritesheet,
		frame_count = wiseman_frames,
		quads = make_quads(wiseman_frames, resources.wiseman_spritesheet)
	}

	-- add wiseman... where? :I
	local wiseman = Wiseman:new(wiseman_spritesheet, 523, 508)
	event_handler:subscribe("on_approach", function(event) wiseman:on_event(event) end)
	objects[#objects+1] = wiseman

	-- wiseman first dialog box
	local box = Dialog:new({"hello, world"})
	wiseman.dialog_box = box -- violence

	ui_objects[#ui_objects+1] = box
	ui_objects[#ui_objects+1] = Mouse:new()

	-- set camera position to start where player is
	camera:lookAt(player.pos.x, player.pos.y)

	-- set up texture to use for lighting data
	local im_w, im_h = tile_map.width, tile_map.height
	lighting_imagedata = li.newImageData(im_w, im_h)
	lighting_image = lg.newImage(lighting_imagedata)
	lighting_image:setFilter("nearest")

	-- collect all light sources on map
	light_sources = collect_light_sources(tile_map)

	-- reset imagedata to all black
	lighting_imagedata:mapPixel(function(x, y, r, g, b, a)
		return r, g, b, 255
	end)

end

function draw_debug()

	function print_thing(thing, y)
		lg.print(thing, 0, y)
		return y + 16
	end

	local y = 16

	lg.push()
	lg.translate(lg.getWidth() - 196, y)
	y = print_thing(string.format("FPS: %d", lt.getFPS()), y)
	y = print_thing(string.format("Frametime: %.3f ms", 1000 * lt.getAverageDelta()), y)
	y = print_thing(string.format("Mouse Last X: %d, Y: %d", camera_state.last_m_x, camera_state.last_m_y), y)
	y = print_thing(string.format("Camera X: %d, Y: %d", camera.x, camera.y), y)
	lg.pop()

end

function draw_map()

	for i=1, #tile_map.data do

		-- this is not even
		local x = (i % tile_map.width) * tile_map.tile_width
		local y = (i / tile_map.height) * tile_map.tile_height

		local res = tile_resources[tile_map.data[i]]

		if res then
			-- still awful
			lg.draw(res, x, y)
		end

	end

end

-- DRAW ALL THE LIGHTINGS, fast and dirty, MAPULON COMETH
-- needs to be aware of collidable tiles to not propagate light through walls
-- turn this into one that uses a queue if it ends up igniting the stack, hopefully it's not consuming that much stack space

local last_tile_x = 0
local last_tile_y = 0

function collect_light_sources(map)

	-- tile id for light source
	local light_source = 15

	local light_sources = {}

	for t_i=1, #map.data do
		if map.data[t_i] == light_source then
			light_sources[#light_sources+1] = t_i
		end
	end

	return light_sources

end

function draw_lighting()

	local imd = lighting_imagedata

	-- light intensity is passed along
	function flood_fill(x, y, t, lit)

		-- return when no more light to spread
		if not (lit > 0) then
			return
		end

		-- if out of bounds, geddafuckoutothere
		if x > tile_map.width or x < 0 or y > tile_map.height or y < 0 then
			return
		end

		-- AUGH
		local r, g, b, a = imd:getPixel(x, y)
		if a == 0 then return end
		if t < (255 - a) then return end

		-- set alpha and shit
		imd:setPixel(x, y, r, g, b, 255 - lit)
		local new_it = lit - 12.5

		-- do not propagate light through the void and not through solid tiles either (should be sane? RETS HOPE SO)
		--  however, do light these blocks, just don't *send* light through them
		local tile = map_index(tile_map, x * tile_map.tile_width, y * tile_map.tile_height)
		if is_tile_collideable(tile) or tile == 0 then
			return
		end

		-- pray to the stack gods
		flood_fill(x, y - 1, lit, new_it)
		flood_fill(x, y + 1, lit, new_it)
		flood_fill(x - 1, y, lit, new_it)
		flood_fill(x + 1, y, lit, new_it)

	end

	-- start from player position
	local tile_x, tile_y = math.floor(player.pos.x / tile_map.tile_width), math.floor(player.pos.y / tile_map.tile_height)
	local tile = map_index(tile_map, player.pos.x, player.pos.y)
	if (tile_x ~= last_tile_x or tile_y ~= last_tile_y) and not is_tile_collideable(tile) then
		last_tile_x, last_tile_y = tile_x, tile_y

		lighting_imagedata:mapPixel(function(x, y, r, g, b, a)
			return r, g, b, 255
		end)

		flood_fill(tile_x, tile_y, 0, 145)

		-- for each visible light source, do another flood fill (RIP FRAMERATE I MISSED YOU SO)
		--  check if tile is close enough to edge of viewport, (add max light propagation distance to calculation)

		--[[

		for i, source in pairs(light_sources) do

			-- wel this isnt.. quite righ
			print(source)
			local tile_x = math.floor((source % tile_map.width))
			local tile_y = math.floor((source / tile_map.height))

			print(tile_x, tile_y)
			if inside_viewport(camera, tile_x, tile_y) then
				flood_fill(tile_x, tile_y, 0, 85)
			end

		end

		]]--

		-- recreate texture from buffer now that it is changed (probably, we havent.. checked for now)
		lighting_image:refresh()

	end

	-- somehow scale texture, as it is just one real pixel per tile currently
	local s_x = tile_map.width
	lg.draw(lighting_image, 0, 0, 0, tile_map.tile_width, tile_map.tile_height)

end

-- well lol
function inside_viewport(camera, x, y)
	return true
end

-- DRAW ALL THE THINGS
function draw_game()

	draw_map()

	for i=1, #objects do
		objects[i]:draw(camera)
	end

	draw_lighting()

end

function draw_ui()

	for i=1, #ui_objects do
		ui_objects[i]:draw(camera)
	end

end

-- magnitude of difference between positions to get distance
function distance(p1, p2)
	return (p1 - p2):len()
end

-- circle intersection because i am hella lazy
function are_colliding(thing_one, thing_two)

	if thing_one.radius and thing_two.radius then
		return distance(thing_one.pos, thing_two.pos) < (thing_one.radius + thing_two.radius)
	else 
		return false
	end

end

-- alert distance
function is_nearby(thing_one, thing_two)

	if thing_one.alert_radius then
		return distance(thing_one.pos, thing_two.pos) < thing_one.alert_radius
	else
		return false
	end

end

-- derp, oh fuck it takes world positions not tile positions
function map_index(map, x, y)
	local i = math.floor((y/map.tile_height)) * map.width + math.floor((x/map.tile_width))
	return map.data[i]
end

-- just chest collision for now
function is_tile_collideable(tile)
	return (tile == 2) or (tile == 4) or (tile == 5) or (tile == 10) or (tile == 11) or (tile == 12)
end

function point_inside_box(pos, x, y, w, h)
	return pos.x < x + w and pos.x > x and pos.y > y and pos.y < y + h
end

-------------------------------
-- Love functions go here! ----
-------------------------------

function love.load()

	-- load resources
	setup_game()

end

function love.update(dt)

	-- check last x, y when mouse was clicked or held, use as delta for camera movement
	local m_x, m_y = lm.getPosition()
	local mouse_dx = camera_state.last_m_x - m_x
	local mouse_dy = camera_state.last_m_y - m_y

	if lm.isDown(3) then
		camera:move(mouse_dx, mouse_dy)
		camera_state.last_m_x, camera_state.last_m_y = m_x, m_y
	end

	-- handle collidable tiles... mostly simpler?
	for i=1, #objects do
		if objects[i].collidable then
			local map = tile_map.data
			local tile = map_index(tile_map, objects[i].pos.x, objects[i].pos.y)
			if is_tile_collideable(tile) then
				-- oh
				objects[i]:collided(tile, true)
			end
		end
	end

	-- handle collisions between objects here
	for o_i=1, #objects do
		for i_i=1, #objects do
			local o_o = objects[o_i]
			local i_o = objects[i_i]
			if o_i ~= i_i and are_colliding(o_o, i_o) then
				objects[o_i].collided(i_o)
				objects[i_i].collided(o_o)
			end
		end
	end

	-- ui object collisions
	for o_i=1, #ui_objects do
		for i_i=1, #ui_objects do
		end
	end

	-- gonna have millions of events, fix that later :D
	-- actually for player just check  every other object, no need to go both ways for now
	for i=1, #objects do
		local obj = objects[i]
		if obj ~= player and is_nearby(obj, player) then
			event_handler:push({approachee = player, subject = obj}, "on_approach")
		end
	end

	event_handler:update(camera, dt)
	
	for i=1, #objects do
		objects[i]:update(camera, dt)
	end

end

function love.draw()

	camera:attach()
	draw_game()
	camera:detach()

	lg.setFont(resources.dialog_font)
	draw_ui()

	lg.setFont(default_font)
	draw_debug()

end

function love.keypressed(key, scancode, isrepeat)

	if scancode == "escape" then
		le.quit()
	end

end

function love.mousepressed(x, y, button, istouch)

	if button == 3 then
		camera_state.last_m_x, camera_state.last_m_y = x, y
	end

end
