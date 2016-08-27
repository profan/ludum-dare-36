-------------------------------
-- External Includes ----------
-------------------------------

require("cupid.debug")

-------------------------------
-- Includes -------------------
-------------------------------

local Camera = require "hump.camera"
local Vector = require "hump.vector"

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
		idle = "resources/player_idle.png"
	}
}

local tiles = {
	[0] = {name = "void"},
	{name = "dirt", fname = "resources/dirt.png"},
	{name = "rock", fname = "resources/rock.png"},
	{name = "sandstone", fname = "resources/sandstone_maybe.png"}
}

-------------------------------
-- Global game variables! -----
-------------------------------

local camera = Camera(0, 0, 1)

local player_state = {

	-- mouse position on click, will be used as relative to drag position for camera movement
	last_m_x = 0,
	last_m_y = 0

}

local objects = {}
local tile_resources = {}

local map_data = require "data/level"

-- process map data, awful place but fuck it

-- WOW FUCKING LUA AND 1 INDEXING YES
local layer = map_data.layers[1]
local tileset = map_data.tilesets[1]

local tile_map = {

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

-------------------------------
-- Game functions here! -------
-------------------------------

function setup_game()

	-- load the tiles and shit
	for id, tile in pairs(tiles) do
		if tile.fname then
			print ("loaded resource: " .. tile.fname)
			tile_resources[id] = lg.newImage(tile.fname)
		end
	end

end

function print_thing(thing, y)
	lg.print(thing, 0, y)
	return y + 16
end

function draw_debug()

	local y = 16

	lg.push()
	lg.translate(love.graphics.getWidth() - 196, y)
	y = print_thing(string.format("FPS: %d", lt.getFPS()), y)
	y = print_thing(string.format("Frametime: %.3f ms", 1000 * lt.getAverageDelta()), y)
	y = print_thing(string.format("Mouse Last X: %d, Y: %d", player_state.last_m_x, player_state.last_m_y), y)
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
			-- purge the demons this is awful
			math.randomseed(i)
			local r = math.random()
			local rotation = ((r < 0.25 and math.pi * 0.5) or (r < 0.5 and math.pi) or math.pi * 1.5)
			lg.draw(res, x, y, rotation)
		end

	end

end

-- DRAW ALL THE THINGS
function draw_game()

	draw_map()

end

-------------------------------
-- Love functions go here! ----
-------------------------------

function love.load()

	-- load resources
	setup_game()

end

function love.update(dt)

	local m_x, m_y = lm.getPosition()
	local mouse_dx = player_state.last_m_x - m_x
	local mouse_dy = player_state.last_m_y - m_y

	if lm.isDown(3) then
		camera:move(mouse_dx, mouse_dy)
		player_state.last_m_x, player_state.last_m_y = m_x, m_y
	end

	for i=1, #objects do
		objects[i]:update(dt)
	end

end

function love.draw()

	camera:attach()

	for i=1, #objects do
		objects[i]:draw()
	end

	draw_game()
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
		player_state.last_m_x, player_state.last_m_y = x, y
	end

end
