-- moving-tris.lua: lua-osg-livecoding sample
-- cxw/Incline 2018
--
-- Run as
--      LOL_RUN=samples/moving-tris.lua livecoding

local mathlib = require 'mathlib'
local Util = require 'Util'

local tri_side = 5                                  -- length of one side
local tri_height = tri_side * math.sqrt(3)*0.5      -- equilateral triangle

-- Make the geometry and add it to the model
local t = tri({0,0,0},{tri_side,0,0},{tri_side*0.5, 0, tri_height})

local function squash(x)    -- [-1,1] -> [0,1]
    return (x*0.5)+0.5
end

local function updateTriangle(time)
    -- #time is referenced to T0

    -- Tip of the triangle moves back and forth
    local theta = math.pi/6 * math.sin(time)
    t.geom.VertexArray[2] =
        -- original position    modifiers with theta
        {tri_side*0.5,
                                tri_height*math.sin(theta),
        tri_height              *math.cos(theta)}

    -- As a result, the normal also changes
    local normal = Util.normal(
        Util.vec2seq(t.geom.VertexArray[0],3),
        Util.vec2seq(t.geom.VertexArray[1],3),
        Util.vec2seq(t.geom.VertexArray[2],3)
    )

    for i=0,2 do    -- same normal for all vertices
        t.geom.NormalArray[i] = normal
    end

    -- Just for fun, change the colors also.  The initial colors from tri()
    -- are 0=>R, 1=>G, 2=>B.

    local color_period = 5.0    -- seconds over which the colors will cycle
    local color_rad = 2*math.pi*((time % color_period)/color_period)
        -- input to sin/cos goes from 0..2pi every color_period seconds

    local shift = 2*math.pi/3   -- divide circle into three pieces

    -- The colors move around the circle
    t.geom.ColorArray[0]={              -- red at time 0
        squash(math.cos(color_rad)),    -- red at time 0
        squash(math.cos(color_rad + shift)),
        squash(math.cos(color_rad + 2*shift)),
        1}

    t.geom.ColorArray[1]={              -- green at time 0
        squash(math.cos(color_rad - shift)),
        squash(math.cos(color_rad)),
        squash(math.cos(color_rad + shift)),
        1}

    t.geom.ColorArray[2]={              -- blue at time 0
        squash(math.cos(color_rad - 2*shift)),
        squash(math.cos(color_rad - shift)),
        squash(math.cos(color_rad)),
        1}

    -- Have to refresh to make the changes visible
    t:refresh()
end --updateTriangle

-- Set the camera
local up = {x=-0.2, y=0, z=1}
mathlib.normalize3(up)
doNthFrame(2, function()
    CAM.ViewMatrix = UTIL:viewLookAt({10, -10, 5}, {2.5, 2.5, 2.5},
        Util.vec2seq(up, 3))
end)
    -- Do on second frame as a hack.  During the first frame, the camera
    -- manipulator sets the initial view.

-- Run the animation
doPerFrame(updateTriangle)

-- vi: set ts=4 sts=4 sw=4 et ai: --
