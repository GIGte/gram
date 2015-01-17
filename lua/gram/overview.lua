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

local lib = {}
Gram.Overview = lib

--[[ Exports:
	Gram.Overview.Load(map_name)
	Gram.Overview.Return(data)
	
	Gram.Overview.FindLocation(data, pos) -> entry
	Gram.Overview.FindLocationByName(data, name) -> entry
	Gram.Overview.IsWithin(data, pos, entry) -> bool
	
	Gram.Overview.AA(entry) -> vec_a, vec_b
	Gram.Overview.NestedEntries(entry) -> entries
	
	Gram.Overview.SizeXY(entry) -> size
	
	Gram.Overview.ClampPosition(entry, pos) -> pos
	Gram.Overview.ClampPosition_IndentXY(entry, pos, indent) -> pos
	Gram.Overview.ClampPositionSizeXY(entry, pos, size) -> pos
	Gram.Overview.ClampPositionSizeXY_IndentXY(entry, pos, size, indent) -> pos
]]

--------------------------------
-- Overview loading			  --
--------------------------------

local data

function lib.Load(map_name)
	data = nil
	
	local tar_file = "gram_overviews/" .. map_name .. ".lua"
	if file.Exists(tar_file, "LUA") then
		include(tar_file)
		
		if not istable(data) then
			error("Gram returned overview data \""..map_name.."\" incorrect!")
		end
	end
	
	tar_file = "resource/overviews/" .. map_name .. ".txt" -- CSS/DoD overview
	if file.Exists(tar_file, "GAME") then
		local tbl = util.KeyValuesToTable(file.Read(tar_file, "GAME"))
		
		data = {}
		data[1] = {
			name = "Ambient",
				vector_origin, vector_origin,
			texture_id = surface.GetTextureID(tbl["material"]),
			scale = tonumber(tbl["scale"]),
			pos_x = tonumber(tbl["pos_x"]),
			pos_y = tonumber(tbl["pos_y"]),
			rotate = tbl["rotate"] == 1,
			zoom = tonumber(tbl["zoom"]),
		}
	end
	
	return data
end

function lib.Return(_data)
	data = _data
end


--------------------------------
-- Overview lookup			  --
--------------------------------

function lib.FindLocation(data, pos)
	local ov_entry
	
	for i = 1, #data do
		local entry = data[i]
		local vec_a, vec_b = entry[1], entry[2]
		
		if not pos:WithinAABox(vec_a, vec_b) and vec_a ~= vec_b then
			continue
		end
		
		if entry[3] ~= nil then
			for i = 3, #entry do
				local subentry = entry[i]
				vec_a, vec_b = subentry[1], subentry[2]
				
				if pos:WithinAABox(vec_a, vec_b) then
					ov_entry = entry
					break
				end
			end
		end
		
		if not ov_entry then
			ov_entry = entry
		end
		
		break
	end
	
	return ov_entry
end

function lib.FindLocationByName(data, name)
	for i = 1, #data do
		local entry = data[i]
		
		if entry.name == name then
			return entry
		end
		
		if entry[3] == nil then continue end
		
		for i = 3, #entry do
			local subentry = entry[i]
			if subentry.name == name then
				return subentry
			end
		end
	end
end

function lib.IsWithin(data, pos, entry)
	if entry[1] == entry[2] then
		if data[1] == entry then
			return true
		end
		
		for i = 1, #data do
			local entry_ = data[i]
			if entry_ == entry then
				return true
			elseif pos:WithinAABox(entry_[1], entry_[2]) then
				return false
			end
		end
	else
		return pos:WithinAABox(entry[1], entry[2])
	end
end


--------------------------------
-- Utility functions		  --
--------------------------------

function lib.AA(entry) -- maybe something more meaningful?
	return entry[1], entry[2]
end

function lib.NestedEntries(entry)
	return entry[3]
end

function lib.ClampPosition(entry, pos)
	local vec_a, vec_b = entry[1], entry[2]
	
	pos.x = math.Clamp(pos.x, vec_a.x, vec_b.x)
	pos.y = math.Clamp(pos.y, vec_a.y, vec_b.y)
	pos.z = math.Clamp(pos.z, vec_a.z, vec_b.z)
	
	return pos
end

function lib.ClampPosition_IndentXY(entry, pos, indent) -- is it really indent?
	local vec_a, vec_b = entry[1], entry[2]
	
	pos.x = math.Clamp(pos.x, vec_a.x + indent, vec_b.x - indent)
	pos.y = math.Clamp(pos.y, vec_a.y + indent, vec_b.y - indent)
	pos.z = math.Clamp(pos.z, vec_a.z, vec_b.z)
	
	return pos
end

function lib.SizeXY(entry)
	local size = surface.GetTextureSize(entry.texture_id)
	return size * entry.scale
end

function lib.ClampPositionSizeXY(entry, pos, size) -- something not good?
	pos.x = math.Clamp(pos.x, entry.pos_x, entry.pos_x + size)
	pos.y = math.Clamp(pos.y, entry.pos_y - size, entry.pos_y)
	
	return pos
end

function lib.ClampPositionSizeXY_IndentXY(entry, pos, size, indent) -- that name is awful, can it be shorter?
	pos.x = math.Clamp(pos.x, entry.pos_x + indent, entry.pos_x + size - indent)
	pos.y = math.Clamp(pos.y, entry.pos_y - size + indent, entry.pos_y - indent)
	
	return pos
end
-- D: