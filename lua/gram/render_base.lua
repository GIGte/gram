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

Gram.Renderers = Gram.Renderers or {}
local lib = Gram.Renderers

local object = {}
lib.Base = object

--[[ Exports:
	Gram.Renderers.Base:new() =>
		CBase:Setup(x, y, w, h)
		CBase:SetupRender(target_pos, target_rot)
		
		CBase:PreRenderLayout() : both called inside!
		CBase:PostRenderLayout()
		
		CBase:RenderLayout()
		CBase:DrawBeacons(iterator)
		CBase:PostRender()
		
		CBase:CalcBeaconDeltas(beacon) : internal!
		
		CBase:RenderBeacon(beacon, x, y, size, ang, overflow) : internal!
		
		CBase:DrawMapTexture(ov_entry, pos_changed) : internal!
		CBase:RenderOverview() : internal!
		
		CBase:GetOverviewData() -> data
		CBase:SetOverviewData(data)
		
		CBase:GetDistance() -> dist
		CBase:SetDistance(dist)
		
		CBase:OnBeaconsUpdated = function(iterator)
]]

local surface, math = surface, math -- some subtles too

--------------------------------
-- Utilities				  --
--------------------------------

local function updateRectUV(verts, u, v, delta)
	local ud = delta - verts.ud
	local vd = delta - verts.vd
	
	verts[1].u, verts[1].v = u - ud, v - vd
	verts[2].u, verts[2].v = u + ud, v - vd
	verts[3].u, verts[3].v = u + ud, v + vd
	verts[4].u, verts[4].v = u - ud, v + vd
end
local function updateRectUV_rotated(verts, u, v, delta)
	local ud = delta - verts.vd
	local vd = delta - verts.ud
	
	verts[1].u, verts[1].v = u - ud, v + vd
	verts[2].u, verts[2].v = u - ud, v - vd
	verts[3].u, verts[3].v = u + ud, v - vd
	verts[4].u, verts[4].v = u + ud, v + vd
end

local function updateRectXY(verts, x, y, w, h)
	verts.ud = w < h and (h - w) / (2 * h) or 0
	verts.vd = w > h and (w - h) / (2 * w) or 0
	
	verts[1].x, verts[1].y = x, y
	verts[2].x, verts[2].y = x + w, y
	verts[3].x, verts[3].y = x + w, y + h
	verts[4].x, verts[4].y = x, y + h
end


--------------------------------
-- Assets					  --
--------------------------------

local tex_be_square = Gram.BeaconTextureID("be_square")
local tex_be_triup = Gram.BeaconTextureID("be_triup")
local tex_be_tridown = Gram.BeaconTextureID("be_tridown")
local tex_fov = Gram.AssetTextureID("fov")

surface.CreateFont("Gram_BeaconLabel", {
	font = "Tahoma",
	size = 12,
	weight = 550,
	antialias = false
})
surface.CreateFont("Gram_BeaconLabel_Outline", {
	font = "Tahoma",
	size = 12,
	weight = 550,
	antialias = false,
	outline = true
})


--------------------------------
-- Constructor				  --
--------------------------------

object.__index = object

function object:new()
	return setmetatable({
		
	}, self)
end


--------------------------------
-- Methods					  --
--------------------------------

function object:Setup(x, y, w, h)
	self._x, self._y = x, y
	self._w, self._h = w, h
	
	self._scale = math.max(w, h) / (self._distance * 2)
	
	if not self._verts then
		self._verts = {{ }, { }, { }, { }}
	end
	
	updateRectXY(self._verts, x, y, w, h)
	
	self._lastpos = nil -- force update
end

function object:SetupRender(target_pos, target_rot)
	self._pos, self._ang = target_pos, target_rot
end


function object:DrawMapTexture(ov_entry, pos_changed)
	if pos_changed then
		local ov_size = Gram.Overview.SizeXY(ov_entry)
		
		local u = (self._pos.x - ov_entry.pos_x) / ov_size
		local v = (ov_entry.pos_y - self._pos.y) / ov_size
		
		local uv_delta = self._distance / ov_size
		
		if ov_entry.rotate then
			updateRectUV_rotated(self._verts, u, v, uv_delta)
		else
			updateRectUV(self._verts, u, v, uv_delta)
		end
		
		self._rotated = ov_entry.rotate
	end
	
	surface.SetDrawColor(color_white)
	surface.SetTexture(ov_entry.texture_id)
	surface.DrawPoly(self._verts)--surface.DrawTexturedRectUV(
end

function object:RenderOverview()
	local ov_entry
	
	if self._lastpos == self._pos then -- some caching...
		if self._ov_entry then
			ov_entry = self._ov_entry
			self:DrawMapTexture(ov_entry, false)
		end
	else
		self._lastpos = self._pos
		
		ov_entry = Gram.Overview.FindLocation(self._ovdata, self._pos)
		
		if ov_entry then
			self:DrawMapTexture(ov_entry, true)
		end
		
		self._ov_entry = ov_entry
	end
end

function object:PreRenderLayout()
	
end
function object:PostRenderLayout()
	
end

function object:RenderLayout()
	self:PreRenderLayout()
	
	if self._ovdata ~= nil then
		self:RenderOverview()
	end
	
	self:PostRenderLayout()
end

function object:RenderBeacon(beacon, x, y, size, ang, overflow)
	local sz_d2 = size/2
	
	surface.SetDrawColor(beacon.Color)
	
	surface.SetTexture(
		beacon.Sprite == tex_be_square and (
			self._pos.z > beacon.pos.z + 128 and tex_be_tridown or
			self._pos.z < beacon.pos.z - 128 and tex_be_triup or tex_be_square
		) or beacon.Sprite
	)
	
	if size > 4 and beacon.CanRotate then
		surface.DrawTexturedRectRotated(x, y, size, size, beacon.rot - ang)
	else
		surface.DrawTexturedRect(x - sz_d2, y - sz_d2, size, size)
	end
	
	if not overflow and beacon.ShowViewDirection then
		local sz = size*3
		
		surface.SetTexture(tex_fov)
		surface.DrawTexturedRectRotated(
			x + math.sin(math.rad(ang - beacon.rot))*sz,
			y - math.cos(math.rad(ang - beacon.rot))*sz,
			
			sz*2, sz*2,
			beacon.rot - ang
		)
	end
	
	if beacon.Label and beacon.Label ~= "" then -- the slowest part of the entire code!!
		surface.SetFont("Gram_BeaconLabel_Outline")
		surface.SetTextColor(80,80,80,250)--0,0,0,200)
		surface.SetTextPos(x + sz_d2 + 4, y - sz_d2 - 6)
		surface.DrawText(beacon.Label)
		
		surface.SetFont("Gram_BeaconLabel")
		surface.SetTextColor(beacon.Color)
		surface.SetTextPos(x + sz_d2 + 4, y - sz_d2 - 6)
		surface.DrawText(beacon.Label)
	end
end

function object:CalcBeaconDeltas(beacon)
	local pos, bpos, scale = self._pos, beacon.pos, self._scale
	if self._rotated then
		return (bpos.y - pos.y) * scale, (bpos.x - pos.x) * scale
	else
		return (bpos.x - pos.x) * scale, (pos.y - bpos.y) * scale
	end
end

function object:DrawBeacons(iterator)
	local pos, scale = self._pos, self._scale
	local center_x, center_y = self._x + self._w/2, self._y + self._h/2
	
	for beacon in iterator do
		local dx, dy = self:CalcBeaconDeltas(beacon)
		local dw, dh = self._w/2 - math.abs(dx), self._h/2 - math.abs(dy)
		
		local overflow = false
		
		if dw < 0 or dh < 0 then
			if beacon.ShouldRemain then
				overflow = true
				dx = dw < 0 and (dx > 0 and dx - dw or dx + dw) or dx
				dy = dh < 0 and (dy > 0 and dy - dh or dy + dh) or dy
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
			local delta = math.min(dw, dh)
			if delta < size then
				size = delta < 4 and 4 or delta
			end
		end
		
		local resx = center_x + dx
		local resy = center_y + dy
		
		local ov_ang = self._rotated and 180 or 90
		
		self:RenderBeacon(beacon, resx, resy, size, ov_ang, overflow)
	end
end

function object:PostRender()
	
end


function object:GetOverviewData()
	return self._ovdata
end
function object:SetOverviewData(data)
	self._ovdata = data
end

function object:GetDistance()
	return self._distance
end
function object:SetDistance(dist)
	self._distance = dist
	self._scale = math.max(self._w, self._h) / (dist*2)
	
	self._lastpos = nil -- force update
end


--------------------------------
-- Events					  --
--------------------------------

function object:OnBeaconsUpdated(iterator)

end
