-- hud-off.lua: lua-osg-livecoding sample
-- Functions to turn off the HUD.
-- cxw/Incline 2018

require 'Help'

function hudblack(whichhud)
    local hud = whichhud or BG
    for i=0,3 do
        hud.ColorArray[i] = {0,0,0,1}
    end
    hud.ColorArray:dirty()
    hud:dirty()
end
sethelp('hudblack',[[
hudblack([node]): make a whole HUD black.  If no node is given, the
default is the background.]], true)

function derezhud(whichhud)
    local hud = whichhud or BG
    local parent = hud:getParent(0)
    parent:removeChild(hud)
end
sethelp('derezhud',[[
derezhud([whichhud]): remove the given HUD node (default BG) from the
scenegraph.  May have strange side-effects, since it doesn't currently reset
the clear bits on the other parts of the scenegraph.  If you have problems, try
hudblack() instead.]], true)

print([[Run hudblack() to make the whole HUD black, or derezhud() to remove
the HUD entirely.]])

-- vi: set ts=4 sts=4 sw=4 et ai: --
