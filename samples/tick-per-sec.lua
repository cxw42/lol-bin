-- tick-per-sec.lua
-- cxw/Incline 2017--2018
-- Blink a cone in time with assets/tick-per-sec.ogg.
-- This is an example of how to do animation.

local Geometry = require 'Geometry'

-- === Cone that flashes on even-numbered seconds ===========================

-- Put the cone where we want it
local xform = new("osg::MatrixTransform")
xform.DataVariance='DYNAMIC'
xform.Matrix=UTIL:xformTranslate({2.5,2.5,2.5})

local drw = new("osg::ShapeDrawable");
xform:addChild(drw)
drw.Color = {0.3, 0.3, 0.3, 1.0}
drw.DataVariance = 'DYNAMIC'

--local ss = new("osg::StateSet")
--drw.StateSet = ss
--ss:set('GL_NORMALIZE', 'ON')

local shape = new("osg::Cone")
shape.Radius=2
drw.Shape = shape   -- assign now that we're ready.

local function updateCone(data, nv)
    time = nv:getSimulationTime()
        -- since this is synced to the soundtrack, just use the
        -- simulation time directly.

    -- shade: 1.0 on even numbers of seconds (exp(-0)==1.0), then
    -- drops off to 0.3 as time moves forward.  The higher the exponent,
    -- the faster the dropoff.
    local shade = 0.3 + 0.7 * (math.exp(-(time % 2.0)) ^ 12.0)

    drw.Color = {shade, shade, shade, 1.0}  -- 1.0 = alpha
end --updateCone

drw.UpdateCallback = updateCone

MODEL:addChild(xform)

-- === Quad that flashes on odd-numbered seconds ============================

local q = quad({2,1,0},{3,1,0},{3,1,1})   -- also adds the quad to the model

-- Vertex shader
local vdesc = Geometry.string2sdesc('VERTEX', default_vshader)

-- Fragment shader
local fdesc = Geometry.string2sdesc('FRAGMENT',
    fshader_color_needs_color ..    -- this calls vec4 color(), supplied here.
    [=[
    uniform float osg_SimulationTime;
        // Same as the nv:getSimulationTime() value.

    vec4 color() {
        // pretty much the same as updateCone(), but in GLSL rather than Lua.
        float time = osg_SimulationTime;
        float shade = 0.3 + 0.7 * pow(exp(-mod(time+1.0, 2.0)),12.0);
            // time+1.0 => 180 deg. out of phase with the cone
        return vec4(shade, shade, shade, 1.0);
    }
    ]=],
    'quad_frag_shader')

-- Compile/link the vertex and fragment shaders into a program
local pgm = Geometry.makeProgram(
    'quad_program',     -- name (our choice)
    vdesc, fdesc        -- the shaders to use
)

-- Load the program onto the quad
Geometry.applyProgram(q.geom, pgm)

-- vi: set ts=4 sts=4 sw=4 et ai: --
