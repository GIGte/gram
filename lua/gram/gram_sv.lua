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

for k, f in pairs(file.Find("gram/*.lua", "LUA")) do
	AddCSLuaFile("gram/" .. f)
end

for k, f in pairs(file.Find("gram_beacons/*.lua", "LUA")) do
	AddCSLuaFile("gram_beacons/" .. f)
end

for k, f in pairs(file.Find("gram_overviews/*.lua", "LUA")) do
	AddCSLuaFile("gram_overviews/" .. f)
end

--[[resource.AddFile("materials/be_square.vmt")
resource.AddFile("materials/be_tridown.vmt")
resource.AddFile("materials/be_triup.vmt")
resource.AddFile("materials/fov.vmt")
resource.AddFile("materials/ring.vmt")]]
