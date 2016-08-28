-------------------------------
-- External Includes ----------
-------------------------------

require("cupid.debug")

-------------------------------
-- Includes -------------------
-------------------------------

require "defines"

-------------------------------
-- Short Forms ----------------
-------------------------------
local lg = love.graphics
local lw = love.window
local lt = love.timer
local lm = love.mouse
local le = love.event

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
	{name = "other_pillar", fname = "resources/other_pillar.png"}
}

-------------------------------
-- Global game variables! -----
-------------------------------

local camera = Camera(0, 0, 1)
local player = nil

local camera_state = {
	-- mouse position on click, will be used as relative to drag position for camera movement
	last_m_x = 0,
	last_m_y = 0
}

local objects = {}
local resources = {}
local tile_resources = {}

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

end

function setup_game()

	-- load images and such
	load_resources()

	-- ... create player?
	local spritesheet_frames = 15 -- I LOVE ME SOME MAGIC NUMBERS
	local sprite_frame_dim = 32

	local make_quads = function()
		local quads = {}
		for i = 1, spritesheet_frames - 1 do 
			quads[#quads+1] = lg.newQuad((i-1) * 32, 0, sprite_frame_dim, sprite_frame_dim, resources.player_spritesheet:getDimensions())
		end 
		return quads
	end

	local spritesheet = {
		image = resources.player_spritesheet,
		frame_count = spritesheet_frames,
		quads = make_quads()
	}

	-- add all the quads and shit
	player = Player:new(spritesheet)
	objects[#objects+1] = player 

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

-- DRAW ALL THE THINGS
function draw_game()
	draw_map()
end

-- magnitude of difference between positions to get distance
function distance(p1, p2)
	return (p1 - p2):len()
end

-- circle intersection because i am hella lazy
function are_colliding(thing_one, thing_two)

	if thing_one.radius and thing_two.radius then
		return distance(thing_one.pos, thing_two.pos) > (thing_one.radius + thing_two.radius)
	else 
		return false
	end

end

-- derp
function map_index(map, x, y)
	local i = math.floor((y/map.tile_height)) * map.width + math.floor((x/map.tile_width))
	return map.data[i]
end

-- just chest collision for now
function is_tile_collideable(tile)
	return tile == 4 or tile == 5 or tile == 9 or tile == 10
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

	for i=1, #objects do
		objects[i]:update(camera, dt)
	end

end

function love.draw()

	camera:attach()
	
	draw_game()

	for i=1, #objects do
		objects[i]:draw(camera)
	end

	camera:detach()

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
