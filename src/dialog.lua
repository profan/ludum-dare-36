--lg
local lg = love.graphics

local dialog = {}

function dialog:new(options)

	local new_obj = {}

	new_obj.options = options

	-- decided by... popular vote?
	new_obj.visible = false

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

function dialog:on_hover()

	print("dialog was hoevertedeaasd!")

end

function dialog:update(camera, dt)

end

function dialog:draw(camera)

	-- ????????
	-- BUNCHA TEXT
	
	if self.visible then

		-- derp
		local x, y = 240, 320

		for i, option_text in pairs(self.options) do
			lg.print(option_text, x, y)
			y = y + 24 -- font size, should twerk
		end

	end

end

return dialog
