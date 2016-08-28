local game_object = {}

function game_object:new(x, y)

	local new_obj = {}

	new_obj.pos = Vector(x, y)
	new_obj.dir_vec = Vector(0, -1)
	new_obj.vel_vec = Vector(0, 0)

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

return game_object
