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
if BG then
    local bg_camera = BG:getParent(0)
    local v = bg_camera.Viewport
    if v then
        local d = v:get()
        print(string.format('Viewport: %dx%d@(%d,%d)', d.z, d.w, d.x, d.y))
    else
        print 'Viewport: no master-camera viewport (probably multi-monitor)'
    end
end

-- vi: set ts=4 sts=4 sw=4 et ai: --
