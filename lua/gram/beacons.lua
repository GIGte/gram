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

Gram.Beacons = Gram.Beacons or {}
local lib = Gram.Beacons

local object = {}
lib.Listener = object

--[[ Exports:
	Gram.Beacons.Create(handler_name, beacon_table) -> beacon
	Gram.Beacons.Subscribe(listener) :
		Tricky here. Since the listeners are stored in a weak table,
		they are subject to garbage collection.
		Therefore you should store them somewhere.
		
		Saving a listener as a CMap's member is the suggested solution.
		
		Note: this is only necessary if you do not have any references to the
		listener, that is you have a local variable which is used only in a
		single place.
	
	Gram.Beacons.Listener.new() =>
		CListener:GetMapObject() -> obj
		CListener:SetMapObject(obj)
		
		CListener:Listen()
		
		CListener.Filters = {} : array of handler names allowed; empty to pass all
		CListener:OnBeaconCreated = function(handler_name, beacon_table)
]]

--------------------------------
-- Beacon management		  --
--------------------------------

local listeners = setmetatable({}, { __mode = "v" })

function lib.Create(handler_name, beacon_table)
	setmetatable(beacon_table, Gram.Handlers[handler_name])
	
	beacon_table._maps = {}
	
	for k,v in pairs(listeners) do
		v:OnBeaconCreated(handler_name, beacon_table)
	end
	
	beacon_table:OnInitialize()
	
	return beacon_table
end

function lib.Subscribe(listener)
	if listener.OnBeaconCreated == nil then
		error("Wrong beacon listener used!")
	end
	
	if not table.HasValue(listeners, listener) then
		table.insert(listeners, listener)
	end
end


--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object.new()
	return setmetatable({
		
	}, object)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:GetMapObject()
	return self._map
end
function object:SetMapObject(obj)
	self._map = obj
end

object.Listen = lib.Subscribe


--------------------------------
-- Members					  --
--------------------------------

object.Filters = {}

function object:OnBeaconCreated(handler_name, beacon_table)
	if #self.Filters ~= 0 then
		if not table.HasValue(self.Filters, handler_name) then
			return
		end
	end
	
	if self._map ~= nil then
		self._map:AppendBeacon(handler_name, beacon_table)
	end
end
