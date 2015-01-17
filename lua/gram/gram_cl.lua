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

if Gram then return end

Gram = { _VERSION = "1.0" }

-- Content loading helpers
include("gram/content_loading.lua")

-- Main systems
include("gram/handlers.lua")
include("gram/beacons.lua")
include("gram/beacons_iterator.lua")
include("gram/overview.lua")

-- Classes
include("gram/map.lua")
include("gram/render_base.lua")
