local mouse = {}

function mouse:new()

	local new_obj = {}

	self.radius = 1
	self.pos = Vector(0, 0)

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

function mouse:update(camera, dt)

	local x, y = love.mouse.getPosition()
	self.pos.x, self.pos.y = x, y

end

function mouse:draw()

end

return mouse
