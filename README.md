# Gram (Garry's mod Radars And Maps)
Gram is an object-oriented radar creation framework for Garry's Mod.

This is an experimental addon that is committed to simplify (hopefully) and unify the creation of various kinds of radars, maps and so on.

The map is a dynamically updated 2D element which has a background (game level's overview) and contains beacons that represent some specific entities or particular positions.

The main idea is that you can easily extend functionality by using inheritance and overriding the default methods.

## Sample use
```Lua
local obj_radar = Gram.Renderers.Radar:new()
obj_radar:SetDistance(distance)

local obj_map = Gram.Map:new()
obj_map:SetupDraw(x, y, size, size)
obj_map:SetRenderer(obj_radar)

obj_map.listener = Gram.Beacons.Listener:new()
obj_map.listener:SetMapObject(obj_map)
obj_map.listener:Listen()

-- obj_map:Draw(pos, rot), obj_map:Poll() to call
```
