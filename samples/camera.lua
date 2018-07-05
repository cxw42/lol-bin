-- camera.lua: Demonstration of camera control in lua-osg-livecoding
-- cxw/Incline 2018

-- Global - change them during runtime if you want
cam_speed = 1
cam_radius= 10;

function camUpdate(time)
    local theta = time*cam_speed
    local x = cam_radius*math.sin(theta)
    local y = cam_radius*(-math.cos(theta))
    local z = 4*math.sin(theta/2)+2

    CAM.ViewMatrix = UTIL:viewLookAt({x,y,z}, {2,2,2}, {0,0,1})
end --camUpdate()

doPerFrame(camUpdate)

-- Show the size of the current HUD viewport
local hud_camera = HUD:getParent(0)
local v = hud_camera.Viewport:get()
print(string.format('Viewport: %dx%d@(%d,%d)', v.z, v.w, v.x, v.y))

-- vi: set ts=4 sts=4 sw=4 et ai: --
