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

local object = {}
Gram.Map = object

--[[ Exports:
	Gram.Map:new() =>
		CMap:AppendBeacon(handler_name, beacon_table) -> beacon
		CMap:DeleteBeacon(beacon)
		
		CMap:ForEach(func) : fundamental method for map's beacon management
			Returning true in the passing function deletes the current beacon,
				false - deletes and breaks the loop.
		CMap:ForEach_NoChange(func) : like previous, but you cannot delete beacons,
										and any returned value breaks the loop
										However, it's faster.
		
		CMap:Poll()
		CMap:PollBeacon(beacon) -> is_deleted
		
		CMap:Clear(handler_name)
		CMap:ClearAll()
		
		CMap:GetRenderer() -> obj
		CMap:SetRenderer(obj)
		
		CMap:SetupDraw(x, y, w, h)
		CMap:Draw(target_pos, target_rot) : EyePos(), EyeAngles().Yaw - for example
]]

--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object:new()
	local beacons = {}
	
	return setmetatable({
		_beacons = beacons,
		_locked = false,
		
		_iter = Gram.Beacons.CreateIterator(beacons),
		
	}, self)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:AppendBeacon(handler_name, beacon_table)
	if Gram.Handlers[handler_name] == nil then
		error("Gram handler \""..handler_name.."\" not found")
	end
	
	if not getmetatable(beacon_table) then
		setmetatable(beacon_table, Gram.Handlers[handler_name])
		
		beacon_table._maps = {self}
		beacon_table:OnInitialize()
	else
		table.insert(beacon_table._maps, self)
	end
	
	--table.insert(self._beacons, beacon_table)
	local arrays, n = self._beacons
	for i = 1, #arrays do
		local beacons = arrays[i]
		if beacons.Priority > beacon_table.Priority then
			n = i
			break
		elseif beacons.Priority == beacon_table.Priority then
			table.insert(beacons, beacon_table)
			
			arrays = nil
			break
		end
	end
	if arrays then
		local beacons = {beacon_table; Priority = beacon_table.Priority}
		if n ~= nil then
			table.insert(arrays, n, beacons)
		else
			table.insert(arrays, beacons)
		end
	end
	
	local renderer = self._renderer
	if renderer and renderer.OnBeaconsUpdated then
		renderer:OnBeaconsUpdated(self._iter)
	end
	
	return beacon_table
end

function object:DeleteBeacon(beacon)
	if self._locked then
		error("Tried to perform an action on a locked beacon storage!")
	end
	
	local arrays = self._beacons
	for i = 1, #arrays do
		local beacons = arrays[i]
		for j = 1, #beacons do
			if beacons[j] == beacon then
				table.remove(beacons, j)
				
				if #beacons == 0 then
					table.remove(arrays, i)
				end
				
				arrays = nil
				break
			end
		end
		
		if not arrays then
			break
		end
	end
	
	table.RemoveByValue(beacon._maps, self)
	
	if arrays ~= nil then return end
	
	local renderer = self._renderer
	if renderer and renderer.OnBeaconsUpdated then
		renderer:OnBeaconsUpdated(self._iter)
	end
	
	--[[self:ForEach(function(_beacon)
		if _beacon == beacon then
			return false
		end
	end)]]
end


local function for_each(self, beacons, func, locked_prev)
	local offs = 0
	
	for j = 1, #beacons do
		local beacon = beacons[j]
		
		local pr = beacon.Priority
		local res = func(beacon)
		
		if locked_prev and (res ~= nil or pr ~= beacon.Priority) then
			error("Tried to perform an action on a locked beacon storage!")
		end
		
		if res == false then
			if offs == 0 then
				table.remove(beacons, j)
			elseif j == #beacons then
				beacons[j] = nil
			else
				for k = j + 1, #beacons do
					beacons[k - offs] = beacons[k]
					beacons[k] = nil
				end
			end
			
			table.RemoveByValue(beacon._maps, self)
			
			return false
		else
			local diff_pr = pr ~= beacon.Priority
			if res == true or diff_pr then
				offs = offs + 1
				beacons[j] = nil
				table.RemoveByValue(beacon._maps, self)
				
				if diff_pr then
					self:AppendBeacon(beacon.HANDLER_NAME, beacon)
				end
			elseif offs ~= 0 then
				beacons[j - offs] = beacon
				beacons[j] = nil
			end
		end
	end
	
	if offs ~= 0 then
		return true
	end
end

function object:ForEach(func)
	local locked_prev = self._locked
	self._locked = true
	
	local arrays_changed = false
	
	local offs = 0
	
	local arrays = self._beacons
	for i = 1, #arrays do
		local beacons = arrays[i]
		local ret = for_each(self, beacons, func, locked_prev)
		
		if ret ~= nil then
			arrays_changed = true
			
			if ret == false then
				break
			end
		end
		
		if #beacons == 0 then
			offs = offs + 1
			arrays[i] = nil
		elseif offs ~= 0 then
			arrays[i - offs] = beacons
			arrays[i] = nil
		end
	end
	
	self._locked = false
	
	if not arrays_changed then return end
	
	local renderer = self._renderer
	if renderer and renderer.OnBeaconsUpdated then
		renderer:OnBeaconsUpdated(self._iter)
	end
end

function object:ForEach_NoChange(func)
	self._locked = true
	
	for beacon in self._iter do
		if func(beacon) ~= nil then
			break
		end
	end
	
	self._locked = false
end


local function pollBeacon(beacon)
	if not beacon.ShouldPoll then return end
	
	local newpos, newang
	local ang_needed = beacon.CanRotate or beacon.ShowViewDirection
	
	if beacon.Entity then
		if not IsValid(beacon.Entity) then
			return true
		end
		
		newpos = beacon.Entity:GetPos()
		if ang_needed then
			newang = beacon.Entity:GetAngles()
		end
	else
		newpos, newang = beacon:OnPoll()
		
		if not newpos then
			return true
		end
	end
	
	if newpos then
		beacon.pos = newpos
	end
	if newang and ang_needed then
		-- It seems that entities with normal physics
		-- like prop_physics or vehicles are rotated by a quater
		-- so we give an option to fix our angle.
		beacon.rot = newang.Yaw + beacon.AngleOffset
	end
end

function object:PollBeacon(beacon)
	if pollBeacon(beacon) then
		self:DeleteBeacon(beacon)
		return true
	end
end

function object:Poll()
	return self:ForEach(pollBeacon)
end


function object:Clear(handler_name)
	local handler_table = Gram.Handlers[handler_name]
	if handler_table == nil then
		error("Gram handler \""..handler_name.."\" not found")
	end
	
	self:ForEach(function(beacon)
		if getmetatable(beacon) == handler_table then
			return true
		end
	end)
end
function object:ClearAll()
	if #self._beacons == 0 then return end
	
	if self._locked then
		error("Tried to perform an action on a locked beacon storage!")
	end
	
	for beacon in self._iter do
		table.RemoveByValue(beacon._maps, self)
	end
	
	self._beacons = {}
	self._iter = Gram.Beacons.CreateIterator(self._beacons)
	
	local renderer = self._renderer
	if renderer and renderer.OnBeaconsUpdated then
		renderer:OnBeaconsUpdated(self._iter)
	end
end


function object:GetRenderer()
	return self._renderer
end
function object:SetRenderer(obj)
	self._renderer = obj
	
	if self._x ~= nil then
		obj:Setup(self._x, self._y, self._w, self._h)
	end
	
	if obj.OnBeaconsUpdated and #self._beacons ~= 0 then
		obj:OnBeaconsUpdated(self._iter)
	end
end

function object:SetupDraw(x, y, w, h)
	self._x, self._y = x, y
	self._w, self._h = w, h
	
	if self._renderer then
		self._renderer:Setup(x, y, w, h)
	end
end
function object:Draw(target_pos, target_rot)
	self._locked = true
	
	local iterator, renderer = self._iter, self._renderer
	iterator("reset")
	
	renderer:SetupRender(target_pos, target_rot)
	
	renderer:RenderLayout()
	renderer:DrawBeacons(iterator)
	renderer:PostRender()
	
	self._locked = false
end
