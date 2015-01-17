--[[
	Gram is a map framework for Garry's Mod
	Copyright (C) 2015 GIG <bigig@live.ru>
--
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local lib = Gram.Renderers

local base = lib.Base
local object = setmetatable({}, base)
lib.Radar = object

--[[ Exports:
	Gram.Renderers.Radar:new() =>
		CRadar:Setup(x, y, w, h)
		CRadar:SetupRender(target_pos, target_rot)
		
		CRadar:PreRenderLayout() : both called inside!
		CRadar:PostRenderLayout()
		
		CRadar:RenderLayout()
		CRadar:DrawBeacons(iterator)
		CRadar:PostRender()
		
		CRadar:DrawMapTexture(ov_entry, pos_changed) : internal!
		
		CRadar:GetOverviewData() -> data
		CRadar:SetOverviewData(data)
		
		CRadar:GetDistance() -> dist
		CRadar:SetDistance(dist)
]]

local surface, math = surface, math -- some subtles too

--------------------------------
-- Utilities				  --
--------------------------------

--[[local function generateCircle(center_x, center_y, radius, num)
	local verts = {}
	
	for i = 0, num - 1 do
		local ang = math.pi*2 * i/num
		verts[i + 1] = {
			x = center_x + math.cos(ang)*radius,
			y = center_y + math.sin(ang)*radius
		}
	end
	
	return verts
end]]

local function generateCircleBase(radius, num)
	local verts = {}
	
	for i = 0, num - 1 do
		local ang = math.pi*2 * i/num
		local cos_r, sin_r = math.cos(ang), math.sin(ang)
		
		verts[i + 1] = {
			_x = cos_r * radius,
			_y = sin_r * radius,
			_u = cos_r * 0.5,
			_v = sin_r * 0.5
		}
	end
	
	return verts
end

local function updateCircleUV(verts, u, v, mul)
	for i = 1, #verts do
		local vert = verts[i]
		vert.u = vert._u*mul + u
		vert.v = vert._v*mul + v
	end
end

local function updateCircleXY(verts, center_x, center_y, ang)
	local cos_r, sin_r = math.cos(ang), math.sin(ang)
	
	for i = 1, #verts do
		local vert = verts[i]
		vert.x = center_x + vert._x*cos_r - vert._y*sin_r
		vert.y = center_y + vert._x*sin_r + vert._y*cos_r
	end
end


--------------------------------
-- Assets					  --
--------------------------------

local tex_circle = Gram.AssetTextureID("circle")
local tex_ring = Gram.AssetTextureID("ring")


--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object:new()
	return setmetatable({
		_x = 0, _y = 0,
		_size = 300,
		
		_distance = 1500,
		_scale = 150/1500,
		
	}, self)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:Setup(x, y, w, h)
	self._x, self._y = x, y
	self._size = w
	
	self._scale = w/(self._distance * 2)
	
	--local size_d2 = w/2
	--self._circle_verts = generateCircle(x + size_d2, y + size_d2, size_d2, 16)
	self._circle_verts = generateCircleBase(w/2 - 1, 16)
	
	-- Force vertices' update
	self._lastpos = nil
	self._lastang = nil
end


function object:DrawMapTexture(ov_entry, pos_changed)
	local pos, yaw = self._pos, self._ang
	
	if pos_changed then
		local ov_size = Gram.Overview.SizeXY(ov_entry)
		
		local u = (pos.x - ov_entry.pos_x) / ov_size
		local v = (ov_entry.pos_y - pos.y) / ov_size
		
		local mul = self._distance*2 / ov_size
		
		updateCircleUV(self._circle_verts, u, v, mul)
	end
	
	if self._lastang ~= yaw then
		self._lastang = yaw
		
		local center_x = self._x + self._size/2
		local center_y = self._y + self._size/2
		
		local ang = math.rad(yaw - 90)
		
		updateCircleXY(self._circle_verts, center_x, center_y, ang)
	end
	
	surface.SetDrawColor(color_white)
	surface.SetTexture(ov_entry.texture_id)
	surface.DrawPoly(self._circle_verts)
end


function object:PreRenderLayout()
	surface.SetDrawColor(color_white)
	surface.SetTexture(tex_circle)
	surface.DrawTexturedRect(
		self._x - self._size*(8/256), self._y - self._size*(8/256),
		self._size*(256/240), self._size*(256/240)
	)
end
function object:PostRenderLayout()
	surface.SetDrawColor(color_white)
	surface.SetTexture(tex_ring)
	surface.DrawTexturedRect(
		self._x - self._size*(8/256), self._y - self._size*(8/256),
		self._size*(256/240), self._size*(256/240)
	)
end

local isWithin = Gram.Overview.IsWithin

function object:DrawBeacons(iterator)
	local pos, ang = self._pos, self._ang
	local distance, scale = self._distance, self._scale
	
	local center_x, center_y = self._x + self._size/2, self._y + self._size/2
	local data, entry = self._ovdata, self._ov_entry
	
	local cos_r, sin_r = math.cos(math.rad(ang)), math.sin(math.rad(ang))
	local offset = Vector()
	
	for beacon in iterator do
		local bpos = beacon.pos
		
		offset.x, offset.y = pos.y - bpos.y, pos.x - bpos.x
		local length = offset:Length2D()
		
		local overflow = false
		
		if length > distance then
			if beacon.ShouldRemain then
				overflow = true
				offset:Mul(distance/length)
			else
				continue
			end
		end
		
		beacon:OnAnimate() -- let the endpoint update before we start drawing
		
		local size = beacon.Size
		
		if beacon.ScaleDependent then
			size = size * scale * 10
			if size < 2 then continue end
		end
		
		if beacon.CanDiminish then
			local delta = (distance - length) * scale
			if delta < size then
				size = delta < 4 and 4 or delta
			end
		end
		
		local alpha
		if data and entry and not isWithin(data, bpos, entry) then
			alpha = beacon.Color.a
			beacon.Color.a = math.floor(alpha / 2) -- what if color_white?
		end
		
		--local vec_r = offset.x*ib + offset.y*jb
		
		local resx = center_x + (offset.x*cos_r - offset.y*sin_r) * scale
		local resy = center_y + (offset.x*sin_r + offset.y*cos_r) * scale
		
		self:RenderBeacon(beacon, resx, resy, size, ang, overflow)
		
		if alpha then
			beacon.Color.a = alpha
		end
	end
end


function object:SetDistance(dist)
	self._distance = dist
	self._scale = self._size/(dist*2)
	
	self._lastpos = nil -- force update
end
