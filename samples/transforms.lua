-- transforms.lua: lua-osg-livecoding sample
-- cxw/Incline 2018

-- This shows two rotating triangles and a moving+rotating triangle.  Each of
-- the first two triangles is rotated a different way: t1 with a Lua per-frame
-- callback (during the event traversal), and t2 with an update callback
-- (during the update traversal).  The choice of which to use is yours!

local mathlib = require 'mathlib'
local Util = require 'Util'

-- === Triangle 1 =======================================================
-- Make the geometry and add it to the model
t1 = tri(1)       --equilateral
xform1 = xform()  -- Now xform1 controls the position &c. of t1

-- Updater for t1
function t1_perframe(time) -- #time is referenced to T0
    local rotation_matrix = UTIL:xformRotate(time, {0,0,1})
        -- time => rotation amount
        -- {0,0,1} => rotation axis.  OSG is right-handed, so this is
        -- clockwise rotation when looking in the +Z direction.
    xform1.Matrix = rotation_matrix     -- apply the change
end --t1_perframe

-- Animate t1
doPerFrame(t1_perframe)

-- === Triangle 2 =======================================================
t2 = tri(1)
xform2 = xform()  -- Likewise xform2 for t2

-- Updater for t2
function t2_update_callback(data, nv)
    local time = nv:getSimulationTime() - T0
    local rotation_matrix = UTIL:xformRotate(time + math.pi, {0,1,1})
        -- +math.pi => 180 degrees out of phase with t1
    xform2.Matrix = rotation_matrix
end

xform2.UpdateCallback = t2_update_callback

-- === Triangle 3 =======================================================
-- This one uses a different type of transform.

t3 = tri(2)
xform3 = new 'osg::PositionAttitudeTransform'
insert_above(t3, xform3)        -- now xform3 controls where t3 goes

-- Pivot point: the point in the local coordinate system of t3 that should
-- map to xform4.Position.  Note that this is affected by xform4.Scale.
xform3.PivotPoint={1, 1, 2.0/3.0}
    -- x=1 and z=2/3 are the center of the triangle.
    -- y=1 moves the triangle toward the viewer by 1.

-- Updater for t3
function t3_update_callback(data, nv)
    local time = nv:getSimulationTime() - T0
    xform3.Position = {2.5, 2.5, 2.5 + 2.5 * math.sin(time)}
    local rotation = UTIL:quatRotate(2.0*time, {0,0,1})
    xform3.Attitude = rotation
    xform3.Scale = {math.sin(0.2*time), 1, math.cos(0.2*time)}
        -- slowly stretch and shrink the triangle.  Leave Scale.y == 1
        -- so that the distance between the triangle and the pivot point
        -- will stay consistent.
end

xform3.UpdateCallback = t3_update_callback

-- vi: set ts=4 sts=4 sw=4 et ai: --
