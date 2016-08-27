-------------------------------
-- External Includes ----------
-------------------------------

require("cupid.debug")

-------------------------------
-- Includes -------------------
-------------------------------

-------------------------------
-- Short Forms ----------------
-------------------------------
local lg = love.graphics
local lw = love.window
local lt = love.timer
local le = love.event

-------------------------------
-- Global game variables! -----
-------------------------------

local objects = {}

-------------------------------
-- Game functions here! -------
-------------------------------

function setup_game()

end

function draw_debug()
	local y = 16
	lg.push()
	lg.translate(love.graphics.getWidth() - 196, y)

	lg.print("FPS: " .. lt.getFPS(), 0, y)
	y = y + 16

	lg.print(string.format("Frametime: %.3f ms", 1000 * lt.getAverageDelta()), 0, y)
	y = y + 16
	
	love.graphics.pop()
end

function draw_game()

end

-------------------------------
-- Love functions go here! ----
-------------------------------

function love.load()
	setup_game()
end

function love.update(dt)
	for i=1, #objects do
		objects[i]:update(dt)
	end
end

function love.draw()
	local lg = love.graphics

	for i=1, #objects do
		objects[i]:draw()
	end

	draw_debug()

end

function love.keypressed(key, scancode, isrepeat)

	if (scancode == "escape") then
		le.quit()
	end

end

function love.mousepressed(x, y, button)

end
