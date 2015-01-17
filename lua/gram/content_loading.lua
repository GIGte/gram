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

Gram.MaterialReplacements = {}

Gram.MaterialFolders = {
	Assets = "gr_content/",
	Beacons = "gr_content/",
	Overviews = "gr_overviews/"
}

function Gram.TextureID(path)
	local tex = Gram.MaterialReplacements[path]
	return tex or surface.GetTextureID(path)
end

function Gram.AssetTextureID(path)
	path = Gram.MaterialFolders.Assets .. path
	return Gram.TextureID(path)
end

function Gram.BeaconTextureID(path)
	path = Gram.MaterialFolders.Beacons .. path
	return Gram.TextureID(path)
end

function Gram.OverviewTextureID(path)
	path = Gram.MaterialFolders.Overviews .. path
	return Gram.TextureID(path)
end

function Gram.OverviewTextureID_R(mapname, postfix)
	local path = Gram.MaterialFolders.Overviews ..
		mapname .. "/" .. mapname .. (postfix or "")
	return Gram.TextureID(path)
end
