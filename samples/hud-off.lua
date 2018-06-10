-- hud-off.lua: lua-osg-livecoding sample
-- Functions to turn off the HUD.
-- cxw/Incline 2018

require 'Help'

function hudblack()
    for i=0,3 do
        HUD.ColorArray[i] = {0,0,0,1}
    end
    HUD.ColorArray:dirty()
    HUD:dirty()
end
sethelp('hudblack',[[hudblack(): make the whole HUD black]], true)

function derezhud()
    local parent = HUD:getParent(0)
    parent:removeChild(HUD)
end
sethelp('derezhud',[[derezhud(): remove the HUD node from the scenegraph.
May have strange side-effects, since it doesn't currently reset the clear
bits on the other parts of the scenegraph.  If you have problems, try
hudblack() instead.]], true)

print([[Run hudblack() to make the whole HUD black, or derezhud() to remove
the HUD entirely.]])

-- vi: set ts=4 sts=4 sw=4 et ai: --
