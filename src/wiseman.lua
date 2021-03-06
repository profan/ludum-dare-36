-- require it
require "derp_math"

-- locals and shit
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

local wiseman = {}

local max_speed = 1
local running_speed = 2
local movement_speed = 75
local turn_speed = 0.05 * math.pi -- RADIANS

function wiseman:new(spritesheet, x, y)

	local new_obj = Object:new(x, y)

	-- things
	new_obj.radius = 12
	new_obj.alert_radius = 64

	-- looking at thingy
	new_obj.looking_at = nil

	-- set the things
	new_obj.spritesheet = spritesheet

	-- current animation frame, 1 is idle, REMEMBER LUA 1 INDEXING OK
	new_obj.frame = 1
	new_obj.time = 0

	-- is collidable
	new_obj.collidable = true

	setmetatable(new_obj, self)
	self.__index = self

	return new_obj

end

function wiseman:animate(dt)

	local frames_per_second = 0.1
	local cur_speed = self.vel_vec:len()
	local speed_scale = cur_speed / max_speed

	self.time = (self.time + dt) * speed_scale
	local vel = self.vel_vec:len()

	if vel < 0.05 then
		self.frame = 1
	elseif self.time > 0.1 then
		self.frame = ((self.frame + 1) % (#self.spritesheet.quads-1)) + 1
		self.time = 0
	end

end

function wiseman:collided(obj, is_tile)
	if is_tile then
		self.vel_vec = self.vel_vec:rotated(math.pi) * 10 -- ... good enough :V
	else
		print("i collided with something!")
	end
end

function wiseman:move(v)

	-- yay
	local ang = self.dir_vec:angleTo(Vector(0, -1))
	self.vel_vec = self.vel_vec + v:rotated(ang)

	local mag = self.vel_vec:len()
	if mag > max_speed then
		self.vel_vec = self.vel_vec * (max_speed / mag)
	end

end

function wiseman:rotate(rad)

	-- next, clamp turning speed
	self.dir_vec = self.dir_vec:rotated(rad)

end

function wiseman:look_at(pos)

	local tmp_vec = pos - self.pos
	self.target_dir_vec = pos - self.pos 
	self.target_dir_vec = self.target_dir_vec:normalized()

	-- DERPPPPPPPPPPPPPPPPPPPPPPPPPP
	local cpd = self.target_dir_vec:cross(self.dir_vec)

	-- ARCSIN YES
	local as = math.asin(cpd)
	local ca = clamp(as, -turn_speed, turn_speed)
	self:rotate(-ca)

end

function wiseman:on_event(event)

	if (event.subject == self) then
		self.looking_at = event.approachee
		self.dialog_box.visible = true
	end

end

function wiseman:update(camera, dt)

	self:animate(dt) -- gotta regulate by game speed

	-- not nil
	if self.looking_at then
		if distance(self.pos, self.looking_at.pos) < self.alert_radius then
			self:look_at(self.looking_at.pos)
		end
	end

	self.pos = self.pos + self.vel_vec
	self.vel_vec = self.vel_vec * 0.85

end

function wiseman:draw(camera)

	-- DRAWE ZE FREAMES
	local coord_system = Vector(0, -1)

	-- quad width/height... not spritesheet
	local x, y, w, h = self.spritesheet.quads[1]:getViewport()
	lg.draw(self.spritesheet.image, self.spritesheet.quads[self.frame], self.pos.x, self.pos.y, self.dir_vec:angleTo(coord_system), 1, 1, w/2, h/2)

end

return wiseman
