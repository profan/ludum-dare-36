-- locals and shit
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

local player = {}

local movement_speed = 1

function player:new(spritesheet, frame_count)

	local new_obj = Object:new(0, 0)

	-- set the things
	new_obj.spritesheet = spritesheet

	-- current animation frame, 1 is idle, REMEMBER LUA 1 INDEXING OK
	new_obj.frame = 1

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

function player:animate()

	if self.vel == 0 then
		self.frame = 1
	else
		self.frame = ((self.frame + 1) % (#self.spritesheet.quads-1)) + 1
	end

end

function player:move(v)

	self.vel = self.vel + v

end

function player:rotate(rad)

	self.dir_vec = self.dir_vec:rotated(rad)

end

function player:look_at(pos)

	-- i brain wrong, look at something else for a second

	local tmp_vec = pos - self.pos
	self.dir_vec = pos - self.pos 
	self.dir_vec = self.dir_vec:normalized()

	print(self.pos, pos)

end

function player:update(camera, dt)

	-- change movement back to vectors for sideways movement

	if lk.isDown "w" then
		self:move(200 * dt)
	elseif lk.isDown "s" then
		self:move(-200 * dt)
	end

	if lk.isDown "a" then
		self:rotate(-5 * dt)
	elseif lk.isDown "d" then
		self:rotate(5 * dt)
	end

	self:look_at(Vector(camera:worldCoords(lm.getPosition())))

	self:animate()

	self.pos = self.pos + (self.vel * self.dir_vec * movement_speed)

	self.vel = 0

end

function player:draw()

	-- DRAWE ZE FREAMES
	local coord_system = Vector(0, -1)
	lg.draw(self.spritesheet.image, self.spritesheet.quads[self.frame], self.pos.x, self.pos.y, self.dir_vec:angleTo(coord_system), 1, 1, 32/2, 32/2)

end

return player
