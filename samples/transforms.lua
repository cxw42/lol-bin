-- transforms.lua: lua-osg-livecoding sample
-- cxw/Incline 2018
--
-- This shows two triangles, both rotating.  Each triangle is rotated a
-- different way: t1 with a Lua per-frame callback (during the event
-- traversal), and t2 with an update callback (during the update traversal).
-- The choice of which to use is yours!

local mathlib = require 'mathlib'
local Util = require 'Util'

-- === Triangle 1 ===
-- Make the geometry and add it to the model
local t1 = tri(1)       --equilateral
local xform1 = xform()  -- Now xform1 controls the position &c. of t1

-- Updater for t1
local function t1_perframe(time) -- #time is referenced to T0
    local m = UTIL:xformRotate(time, {0,0,1})
        -- time => rotation amount
        -- {0,0,1} => rotation axis.  OSG is right-handed, so this is
        -- clockwise rotation when looking in the +Z direction.
    xform1.Matrix = m   -- apply the change
end --t1_perframe

-- Animate t1
doPerFrame(t1_perframe)

-- === Triangle 2 ===
local t2 = tri(1)
local xform2 = xform()  -- Likewise xform2 for t2

-- Updater for t2
local function t2_update_callback(data, nv)
    local time = nv:getSimulationTime() - T0
    local m = UTIL:xformRotate(time + math.pi, {0,1,1})
    xform2.Matrix = m
end

xform2.UpdateCallback = t2_update_callback

-- vi: set ts=4 sts=4 sw=4 et ai: --
