local game_object = {}

function game_object:new()

	local new_obj = {}

	new_obj.x = 0
	new_obj.y = 0
	new_obj.dir_vec = Vector(-1, 0)
	new_obj.vel_vec = Vector(0, 0)

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

return game_object
