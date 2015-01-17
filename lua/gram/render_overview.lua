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
lib.Overview = object

--[[ Exports:
	Gram.Renderers.Overview:new() =>
		COverview:Setup(x, y, w, h)
		COverview:SetupRender(target_pos)
		
		COverview:PreRenderLayout() : both called inside!
		COverview:PostRenderLayout()
		
		COverview:RenderLayout()
		COverview:DrawBeacons(iterator)
		COverview:PostRender()
		
		COverview:RenderOverview() : internal!
		COverview:UpdateOverviewRendering(entry) : internal!
		COverview:UpdateOverviewOrigin(entry, size) : internal!
		
		COverview:GetOverview() -> ov_entry
		COverview:IsOverviewForced() -> bool
		COverview:ForceOverview(entry) : nil is applicable as well
		COverview:ResetOverview() : undo force
		
		COverview:GetOverviewData() -> data
		COverview:SetOverviewData(data)
		
		COverview:GetDistanceLimits() -> min, max
		COverview:SetDistanceLimits(min, max)
		
		COverview:GetDistance() -> dist
		COverview:SetDistance(dist)
		
		COverview:OnLocationUpdate = function(entry)
]]

local surface, math = surface, math -- some subtles too

--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object:new()
	return setmetatable({
		_x = 0, _y = 0,
		_w = 300, _h = 300,
		
		_distance = 1500,
		_scale = 150/1500,
		
		_pos = Vector(),
		
		_distance_min = 250,
		_distance_max = 16384,
		
	}, self)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:Setup(x, y, w, h)
	base.Setup(self, x, y, w, h)
	
	self:UpdateOverviewRendering(self._ov_entry)
end

function object:SetupRender(target_pos)--, target_rot)
	self._tarpos = target_pos--, target_rot
end


-- Called in case of: entry changed, limits or layout updated
function object:UpdateOverviewRendering(entry)
	if entry == nil then
		local dist_s = self._distance_min + self._distance_max
		self._distance = dist_s/2 -- get average
		self._scale = math.max(self._w, self._h) / dist_s
	else
		local size = Gram.Overview.SizeXY(entry)
		size = size / 2
		
		if size > self._distance_max then
			self._ov_entry_size = size*2
		else
			self._ov_entry_size = nil
			
			self._pos.x = entry.pos_x + size
			self._pos.y = entry.pos_y - size
		end
		
		size = math.Clamp(size, self._distance_min, self._distance_max)
		
		self._distance = size
		self._scale = math.max(self._w, self._h) / (size*2)
	end
end

function object:UpdateOverviewOrigin(entry, size)
	local pos, tarpos = self._pos, self._tarpos
	local distance = self._distance
	
	pos.x = math.Clamp(tarpos.x - entry.pos_x,
		distance, size - distance) + entry.pos_x
	pos.y = -math.Clamp(entry.pos_y - tarpos.y,
		distance, size - distance) + entry.pos_y
end

function object:RenderOverview()
	local pos = self._tarpos
	
	local ov_entry
	
	if self._lastpos == pos then -- some caching...
		if self._ov_entry then
			ov_entry = self._ov_entry
			self:DrawMapTexture(ov_entry, false)
		end
	else
		self._lastpos = pos
		self._pos.z = pos.z
		
		if self._ov_forced then
			ov_entry = self._ov_entry
		else
			ov_entry = Gram.Overview.FindLocation(self._ovdata, pos)
			
			if ov_entry ~= self._ov_entry then
				self:UpdateOverviewRendering(ov_entry)
				
				self:OnLocationUpdate(ov_entry) -- to update your HUD etc
				self._ov_entry = ov_entry
			end
		end
		
		if ov_entry then
			if self._ov_entry_size ~= nil then
				self:UpdateOverviewOrigin(ov_entry, self._ov_entry_size)
			end
			
			self:DrawMapTexture(ov_entry, true)
		end
	end
end

function object:RenderLayout()
	self:PreRenderLayout()
	
	if self._ovdata ~= nil then
		self:RenderOverview()
	end
	if self._ov_entry == nil then
		self._pos = self._tarpos
	end
	
	self:PostRenderLayout()
end

local isWithin = Gram.Overview.IsWithin

function object:DrawBeacons(iterator)
	local pos, scale = self._pos, self._scale
	local center_x, center_y = self._x + self._w/2, self._y + self._h/2
	local data, entry = self._ovdata, self._ov_entry
	
	for beacon in iterator do
		local dx, dy = self:CalcBeaconDeltas(beacon)
		local dw, dh = self._w/2 - math.abs(dx), self._h/2 - math.abs(dy)
		
		if dw < 0 or dh < 0 then continue end
		if data and entry and not isWithin(data, beacon.pos, entry) then continue end
		
		beacon:OnAnimate() -- let the endpoint update before we start drawing
		
		local size = beacon.Size
		
		if beacon.ScaleDependent then
			size = size * scale * 10
			if size < 2 then continue end
		end
		
		if beacon.CanDiminish then
			local delta = math.min(dw, dh)
			if delta < size then
				size = delta < 4 and 4 or delta
			end
		end
		
		local resx = center_x + dx
		local resy = center_y + dy
		
		local ov_ang = self._rotated and 180 or 90
		
		self:RenderBeacon(beacon, resx, resy, size, ov_ang, false)
	end
end


function object:GetOverview()
	return self._ov_entry
end

function object:IsOverviewForced()
	return self._ov_forced
end

function object:ForceOverview(entry)
	if self._ov_entry ~= entry then
		self:UpdateOverviewRendering(entry)
		
		self:OnLocationUpdate(entry)
		self._ov_entry = entry
		
		self._lastpos = nil -- force update
	end
	
	self._ov_forced = true
end
function object:ResetOverview()
	self._ov_forced = false
end

function object:GetDistanceLimits()
	return self._distance_min, self._distance_max
end
function object:SetDistanceLimits(min, max)
	self._distance_min = min
	self._distance_max = max
	
	self:UpdateOverviewRendering(self._ov_entry)
end


--------------------------------
-- Events					  --
--------------------------------

function object:OnLocationUpdate(entry)
	
end
