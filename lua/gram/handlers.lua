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

local lib = Gram

--[[ Exports:
	Gram.Handlers : hash table; to add a new handler you should register it
	Gram.RegisterHandler(name, handler_table[, enabled])
	
	Gram.StartHandlers()
	Gram.StopHandlers()
	
	Gram.EPriority =>
		EPriority.Low
		EPriority.Medium
		EPriority.High
]]

--------------------------------
-- As is					  --
--------------------------------

local handler_meta = {
	--Label = false,
	Sprite = Gram.BeaconTextureID("be_square"),
	Color = color_white,
	Size = 10,
	
	--[[x = 0,
	y = 0,
	z = 0,
	ang = 0,]]
	
	pos = vector_origin,
	rot = 0,
	
	ShouldPoll = false,
	ShouldRemain = false,
	ScaleDependent = false,
	CanDiminish = true,
	CanRotate = false,
	ShowViewDirection = false,
	
	AngleOffset = 0,
	Priority = 1,
	
	OnInitialize = function() end,
	OnPoll = function() end,
	--OnUpdate = function() end,
	OnAnimate = function() end,
	
	Create = function(self, beacon_table)
		return Gram.Beacons.Create(self.HANDLER_NAME, beacon_table)
	end,
	Dispose = function(self)
		for i = 1, #self._maps do
			self._maps[i]:DeleteBeacon(self)
		end
	end
}

handler_meta.__index = handler_meta


--------------------------------
-- Event system				  --
--------------------------------

local ev_handlers = {}
local ev_handlers_col = {}

local function check(ent)
	local classname = ent:GetClass()
	
	local handler = ev_handlers[classname]
	
	if not handler then
		handler = ev_handlers_col[classname]
	end
	
	if not handler then
		for k,v in pairs(ev_handlers_col) do
			--if string.sub(k, -1) == "*" then
			--	local len = #k - 1
				if string.sub(classname, 1, #k) == k then
					handler = v
					break
				end
			--end
		end
	end
	
	if handler then
		if handler.CheckEntity and not handler:CheckEntity(ent) then return end
		
		handler:Create { Entity = ent }
		handler._lastent = ent
	end
end

local function revive(handler)
	if handler.ManualBeacons then return end
	
	local last = handler._lastent
	
	if handler.EntityClasses then
		for k,v in pairs(ents.GetAll()) do
			if not handler._classes[v:GetClass()] then continue end
			
			if last then
				if v == last then
					last = nil
				end
				continue
			end
			
			if handler.CheckEntity and not handler:CheckEntity(v) then continue end
			
			handler:Create { Entity = v }
			handler._lastent = v
		end
	
		return
	end
	
	for k,v in pairs(ents.FindByClass(handler.HANDLER_NAME)) do
		if last then
			if v == last then
				last = nil
			end
			continue
		end
		
		if handler.CheckEntity and not handler:CheckEntity(v) then continue end
		
		handler:Create { Entity = v }
		handler._lastent = v
	end
end

local function reload(handler)
	if handler.ManualBeacons then
		if not istable(handler.ManualBeacons) then return end
		
		for k,v in pairs(handler.ManualBeacons) do
			handler:Create(v)
		end
	elseif handler.EntityClasses then
		for k,v in pairs(ents.GetAll()) do
			if not handler._classes[v:GetClass()] then continue end
			if handler.CheckEntity and not handler:CheckEntity(v) then continue end
			
			handler:Create { Entity = v }
		end
	else
		for k,v in pairs(ents.FindByClass(handler.HANDLER_NAME)) do
			if handler.CheckEntity and not handler:CheckEntity(v) then continue end
			
			handler:Create { Entity = v }
		end
	end
end

local function reload_to(handler, listener)
	if handler.ManualBeacons then
		if not istable(handler.ManualBeacons) then return end
		
		for k,v in pairs(handler.ManualBeacons) do
			listener:OnBeaconCreated(handler.HANDLER_NAME, v)
		end
	elseif handler.EntityClasses then
		for k,v in pairs(ents.GetAll()) do
			if not handler._classes[v:GetClass()] then continue end
			if handler.CheckEntity and not handler:CheckEntity(v) then continue end
			
			listener:OnBeaconCreated(handler.HANDLER_NAME, { Entity = v })
		end
	else
		--local last = handler._lastent
		for k,v in pairs(ents.FindByClass(handler.HANDLER_NAME)) do
			--[[if last then
				if v == last then
					last = nil
				end
			else
				handler:Create { Entity = v }
				continue -- only if subscribed?
			end]]
			
			if handler.CheckEntity and not handler:CheckEntity(v) then continue end
			
			listener:OnBeaconCreated(handler.HANDLER_NAME, { Entity = v })
		end
	end
end

function handler_meta:Start()
	if next(ev_handlers) == nil and next(ev_handlers_col) == nil then
		hook.Add("OnEntityCreated", "Gram_OnEntityCreated", check)
	end
	
	if string.sub(self.HANDLER_NAME, -1) == "*" then
		ev_handlers_col[string.sub(self.HANDLER_NAME, 1, #self.HANDLER_NAME - 1)] = self
	elseif self.EntityClasses then
		self._classes = {}
		for k,v in pairs(self.EntityClasses) do
			self._classes[v] = true
			ev_handlers_col[v] = self
		end
	else
		ev_handlers[self.HANDLER_NAME] = self
	end
end

function handler_meta:Stop()
	if ev_handlers[self.HANDLER_NAME] then
		ev_handlers[self.HANDLER_NAME] = nil
	else
		for k,v in pairs(ev_handlers_col) do
			if v == self then
				ev_handlers_col[k] = nil
			end
		end
	end
	
	if next(ev_handlers) == nil and next(ev_handlers_col) == nil then
		hook.Remove("OnEntityCreated", "Gram_OnEntityCreated")
	end
end

function handler_meta:Restart()
	ev_handlers[""] = true
	
	self:Stop()
	self:Start()
	
	ev_handlers[""] = nil
end

function handler_meta:Revive() -- recover, renew, restore?
	revive(self)
end

function handler_meta:Reload()
	reload(self)
end

function handler_meta:ReloadToListener(listener)
	reload_to(self, listener)
end


--------------------------------
-- Externals				  --
--------------------------------

lib.Handlers = {}

function lib.RegisterHandler(name, handler_table, enabled)
	if not isstring(name) then return end
	
	handler_table.__index = handler_table
	lib.Handlers[name] = setmetatable(handler_table, handler_meta)
	
	if not handler_table.HANDLER_NAME then
		handler_table.HANDLER_NAME = name
	end
	
	if enabled then
		handler_table:Start()
	end
end

function lib.StartHandlers()
	for k,v in pairs(lib.Handlers) do
		v:Revive()
		v:Start()
	end
end

function lib.StopHandlers()
	for k,v in pairs(lib.Handlers) do
		v:Stop()
	end
end

lib.EPriority = { -- handler render priority
	Low = 0,
	Medium = 1,
	High = 2
}


--------------------------------
-- Handler loader			  --
--------------------------------

for k,f in pairs(file.Find("gram_beacons/*.lua","LUA")) do
	BEACON = {
		HANDLER_NAME = string.gsub(string.sub(f, 1, #f - 4), "#", "*")
	}
	
	include("gram_beacons/" .. f)
	lib.RegisterHandler(BEACON.HANDLER_NAME, BEACON)
end

BEACON = nil
