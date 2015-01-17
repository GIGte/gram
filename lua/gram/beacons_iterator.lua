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
lib.Iterator = object

--[[ Exports:
	Gram.Beacons.CreateIterator(upv_table) -> iter_func
	
	Gram.Beacons.Iterator:new() =>
		CIterator:GetTable() -> tbl
		CIterator:SetTable(tbl)
		
		CIterator:Reset()
		CIterator:Next()
	
	Note: for table[table, table, ...] format
]]

--------------------------------
-- Externals				  --
--------------------------------

function lib.CreateIterator(upv_table)
	local i, j = 0, 0
	local l, a = 0
	
	return function(input)
		if input and input == "reset" then
			i, j = 0, 0
			l = 0
			return
		end
		
		if j == l then
			i = i + 1
			a = upv_table[i]
			if a == nil then return end
			
			l = #a
			
			j = 1
		else
			j = j + 1
		end
		
		return a[j]
	end
end


--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object:new()
	return setmetatable({
		_ei = 0,
		_i = 0,
		_ec = 0,
		
	}, self)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:GetTable()
	return self._table
end
function object:SetTable(tbl)
	self._table = tbl
end

function object:Reset()
	self._ei = 0
	self._i = 0
	self._ec = 0
end

function object:Next()
	if self._i == self._ec then
		self._ei = self._ei + 1
		self._ee = self._table[self._ei]
		if self._ee == nil then return end

		self._ec = #self._ee

		self._i = 1
	else
		self._i = self._i + 1
	end

	return self._ee[self._i]
end
