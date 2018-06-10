-- livecoding.lua
--  Reminder: don't forget to add help for each new function using sethelp()

-- livecoding.lua: Test of the OSG Lua interface, and livecoding!

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'checks'
require 'print_r'
require 'Help'
mathlib = require 'mathlib'

-- Reminder: this is run as a chunk of its own, so no `local` variables will
-- be exported.

print("Hello, world! 42")
--local inp = io.read()     -- this works fine - blocks the calling thread
--print("Input was: ", inp)

--=========================================================================--
-- Globals

MODEL = nil     -- the root of the Lua-created geometry
S = nil         -- the last shape created

--=========================================================================--
-- Load helpers

-- Load the basic stuff
function reload()

    -- Unload if we are being called for the second time
    package.loaded.dbg = nil
    package.loaded.Content = nil
    package.loaded.Geometry = nil
    package.loaded.Util = nil
    package.loaded.mathlib = nil
        -- thanks to http://lua-users.org/lists/lua-l/2011-05/msg00365.html

    -- Load it
    Util = require 'Util'     -- load ./Util.lua into the global namespace.
        -- TODO? add OSG_FILE_PATH to the Lua search path?
    Geometry = require 'Geometry'
    Content = require 'Content'
    dbg = require 'debugger'  -- https://github.com/slembcke/debugger.lua
    mathlib = require 'mathlib'

    UTIL = nil  -- drop the old one, hopefully
    UTIL = new('osg::ScriptUtils')

end --reload()
sethelp('reload', 'Reload packages used by livecoding.lua', true)

reload()    -- Do the initial load

-- Hack in some help for UTIL, since it doesn't have help of its own.
-- For some reason, UTIL.viewLookAt is different from the command line than
-- it is here.  TODO find out why.
sethelp('UTIL',[[
UTIL is an osg::ScriptUtils instance.
See help('foo') for the following foos:
    UTIL.viewLookAt]], true)

sethelp('UTIL.viewLookAt',[[
Matrix UTIL:viewLookAt(Vec3 eye, Vec3 center, Vec3 up): make a view matrix
a la gluLookAt().
]], true)

--=========================================================================--
-- Create geometry

-- Root of the Lua-created part of the scenegraph.  (ROOT is the actual
-- root node, and is created in C++.)
local grp = new("osg::Group");

-- Axis markers
local axis_switch = new('osg::Switch')
grp:addChild(axis_switch)
axis_switch:addChild(Geometry.makeSphere({1,1,1,1}, {0,0,0}, 0.2))
axis_switch:addChild(Geometry.makeSphere({1,0,0,1}, {5,0,0}, 0.2, 'X'))
axis_switch:addChild(Geometry.makeSphere({0,1,0,1}, {0,5,0}, 0.2, 'Y'))
axis_switch:addChild(Geometry.makeSphere({0,0,1,1}, {0,0,5}, 0.2, 'Z'))

function axis(onoff)
    val = not not onoff     -- make sure it's a bool
    for i=0,3 do
        axis_switch:setValue(i, val)
    end
end
sethelp('axis',
    'axis(true) to turn axis markers on; axis(false) to turn them off', true)

print("Children:", grp:getNumChildren())

MODEL = grp

--=========================================================================--
-- Some random uniforms

local rss = ROOT:getOrCreateStateSet()
-- For rotation in the shader
uOrigin = Geometry.makeUniform('Origin','FLOAT_VEC2')
do
    rss:add(uOrigin)
    local function origin_update(time)      -- called via CBK
        local radius = 0.5
        local speed = 1.0
        uOrigin:value({radius*math.cos(speed*time),
                        radius*math.sin(speed*time)})
        --print('Origin:', origin:value()[0], origin:value()[1])
    end
    doPerFrame(origin_update)
end
sethelp('uOrigin','uniform vec2 Origin', true)

-- For the HUD
uSpeed = Geometry.makeUniform('circle_speed', 'FLOAT', 4) --try 1
sethelp('uSpeed','uniform float circle_speed', true)

uInterval = Geometry.makeUniform('circle_interval', 'FLOAT', 1) --try 2.4
sethelp('uInterval','uniform float circle_interval', true)

uShift = Geometry.makeUniform('circle_shift', 'FLOAT', 0)
sethelp('uShift','uniform float circle_shift', true)

rss:add(uSpeed)
rss:add(uInterval)
rss:add(uShift)

--=========================================================================--
-- Live-coding functions
-- Global S holds the current shape.  All these functions either populate S
-- or operate on S, unless otherwise specified.
-- All shape-creation functions add the shape to MODEL, unless
-- otherwise specified.

-- Create a sphere and add it to the model.
function sph(color, pos, radius, name)
    S = Geometry.makeSphere(
        Util.vec2seq(color, 4),
        Util.vec2seq(pos, 3),
        radius or 1.0,
        name or '')
    MODEL:addChild(S)
end --sph
sethelp('sph', [[
Create a sphere and add it to the model.  Sets S to the new shape.
function sph(color, pos, radius, name)]], true)

-- Add a Content instance
function content()
    local retval = Content:new()
    S = retval.geom
    MODEL:addChild(S)
    return retval
end
sethelp('content',
[[content(): Creates a new Content instance and returns it.
After that, you can use foo:startbuild(), foo:newvload(), and foo:endbuild().
Also adds the instance's geometry (foo.geom) to the model and puts it in S.]])

-- Add a Content instance representing a quad.
-- corner1-corner2 is one side, and corner1-corner3 is the diagonal.
function quad(corner1, corner2, corner3)
    corner1 = Util.vec2seq(corner1, 3)      --regularize
    corner2 = Util.vec2seq(corner2, 3)

    local normal = Util.normal(corner1, corner2, corner3)   -- Get the normal

    -- Get the fourth corner
    local otherside = Util.seqMinusSeq(corner3, corner2)
    local corner4 = Util.seqPlusSeq(corner1, otherside)

    -- Build it
    local retval = Content:new()
    retval:startbuild('QUADS')
    retval:newvload(corner1, normal, {1,0,0,1}, {0,0})
    retval:newvload(corner2, normal, {0,1,0,1}, {1,0})
    retval:newvload(corner3, normal, {0,0,1,1}, {1,1})
    retval:newvload(corner4, normal, {1,0,1,1}, {0,1})
    retval:endbuild()
    S = retval.geom
    MODEL:addChild(S)
    return retval
end
sethelp('quad',
[[quad({x1, y1, z1}, {x2, y2, z2}): make a quad and return its Content
instance.  Sets S.  Texture coordinates are 0-1 on each axis.]], true)

-- Add a Content instance representing a triangle.
-- Corners are listed counter-clockwise.
function tri(corner1, corner2, corner3)
    corner1 = Util.vec2seq(corner1, 3)      --regularize
    corner2 = Util.vec2seq(corner2, 3)

    -- Get the normal
    local normal = Util.normal(corner1, corner2, corner3)

    -- Build it
    local retval = Content:new()
    retval:startbuild('TRIANGLES')
    retval:newvload(corner1, normal, {1,0,0,1}, {0,0})
    retval:newvload(corner2, normal, {0,1,0,1}, {1,0})
    retval:newvload(corner3, normal, {0,0,1,1}, {1,1})
    retval:endbuild()
    S = retval.geom
    MODEL:addChild(S)
    return retval
end
sethelp('tri',
[[tri({x1, y1, z1}, {x2, y2, z2}, {x3, y3, z3}): make a triangle and
return its Content instance.  Sets S.  Texture coordinates are X running 0-1
from vertex 1 to vertex 2, and Y running 0-1 from vertex 1/2 to vertex 3.
List vertices counter-clockwise.]], true)
-- Remove the last-added child
function drop()
    MODEL:removeChild(S)
end
sethelp('drop','drop(): Remove the last-added child (S)', true)

--=========================================================================--

-- Run an initial file, if the user has provided one
function relol()

    -- Discard old callbacks.  Assume CBK[0] is the origin_update callback
    -- created above.
    for i=#CBK,2,-1 do          -- clear the array part, except for CBK[1]
        table.remove(CBK, i)
    end

    for k,_ in pairs(CBK) do    -- clear the hash part
        if type(k) == 'string' then     -- don't remove [1]
            CBK[k] = nil
        end
    end

    -- Discard old geometry.  Assume child 0 is still the axis markers,
    -- and leave them present.
    for i=MODEL:getNumChildren()-1, 1, -1 do    -- children are 0-based
        MODEL:removeChild(MODEL:getChild(i))
    end

    -- Run LOL_RUN if specified
    local fn = os.getenv('LOL_RUN')
    if fn and Util.file_readable(fn) then
        print('-- Running initial file ' .. fn)
        dofile(fn)
        print('-- Done running initial file ' .. fn)
        print('-- To reload it, run relol().')
    end

    -- Set up to grab the new T0 on the next frame
    doNextFrame(function(_, sim_time)
        T0 = sim_time
        --print('T0 is now ' .. tostring(T0))
    end)

end
sethelp('relol',[[
relol()
  Discard any geometry you've added to the scene.
  Also, if the environment variable LOL_RUN specifies a readable file,
  execute it as Lua source.]], true)

relol()     -- Do it, Rockapella!

print [[

Reminder --> to position the camera, say `camoff`, then
  CAM.ViewMatrix = UTIL:viewLookAt({1,-20,6},{2.5,2.5,2.5},{0,0,1})

For help, say `help()` (without the backticks).
]]

return grp  -- whatever object(s) we return are what are displayed.

-- vi: set ts=4 sts=4 sw=4 et ai: --
