-- locals and shit
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

local event_handler = {}

function event_handler:new()

	local new_obj = {}

	new_obj.subscribers = {}
	new_obj.events = {}

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

function event_handler:subscribe(e_type, fn)
	
	if not self.subscribers[e_type] then
		self.subscribers[e_type] = {}
		self.events[e_type] = {}
	end

	self.subscribers[e_type][#self.subscribers[e_type]+1] = fn

end

function event_handler:push(event, e_type)
	self.events[e_type][#self.events[e_type]+1] = event
end

-- it helps if you call this, i assure you
function event_handler:update(camera, dt)

	for e_type, events in pairs(self.events) do
		for e_i, event in pairs(self.events[e_type]) do
			for s_i, subscriber in pairs(self.subscribers[e_type]) do
				subscriber(event)
			end
		end
		self.events[e_type] = {}
	end

end

function event_handler:draw(camera)

end

return event_handler
