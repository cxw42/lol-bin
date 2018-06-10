-- cone.lua
-- cxw/Incline 2017--2017
-- Make a cone.  This is an example of how to do animation.
-- This is designed to be run with dofile() via the LOL_RUN mechanism
-- in livecoding.lua.  Therefore, it is not a package.

-- === Add an animated cone =================================================

local xform = new("osg::MatrixTransform")
--grp:addChild(xform)
xform.DataVariance='DYNAMIC'
xform.Matrix={1,0,0,0,
              0,1,0,0,
              0,0,1,0,
              0,0,0,1}
--Util.dump(xform.Matrix)   -- Members are 0..15, NOT 1..16

local drw = new("osg::ShapeDrawable");
xform:addChild(drw)   -- methods use : ; property accesses use .
drw.Color = {0.75,1,0.5,1}
drw.DataVariance = 'DYNAMIC'    -- since we will change the color

-- Need to rescale the normals since the cone will be growing and shrinking.
-- This is the equivalent of the C++
-- drw->getOrCreateStateSet()->setMode(GL_NORMALIZE, osg::StateAttribute::ON)
local ss = new("osg::StateSet")
drw.StateSet = ss
ss:set('GL_NORMALIZE', 'ON')

local shape = new("osg::Cone")
-- Now set up the shape BEFORE the assignment to `drw.Shape`, because
-- that assignment triggers the `ShapeDrawable::build()` call that actually
-- makes the shape geometry.  Changes to `shape` after `drw.Shape=shape`
-- do not affect the displayed geometry even though they DO change the shape
-- properties in a way that is reflected when you later inspect the
-- scene graph!
shape.Radius=2
drw.Shape = shape   -- assign now that we're ready.

--frame=0

local function updateCone(data, nv)
    -- TODO figure out how to get the FrameStamp.  I may need to add
    -- a function to the serializer for NodeVisitor.
    -- TODO figure out read-only properties.  I think I may just need to
    -- have a setter that always throws, or have a custom function that
    -- only returns the value and doesn't take any parameters.

    time = nv:getSimulationTime() - T0
        -- minus T0 => relative to last relol()

    local scale = math.max(0.1, math.abs(2 * math.sin(time)))

    -- The following works
    xform.Matrix={scale,0,0,0,
                  0,scale,0,0,
                  0,0,scale,0,
                  0,0,0,1}

    --[[ -- This doesn't work, and I don't know why at the moment.
    xform.Matrix[0] = scale
    xform.Matrix[5] = scale
    xform.Matrix[10] = scale
    ]]--

    drw.Color = {time % 1.0, 1.0 - (time % 1.0), 0.5, 1.0}

end --updateCone

drw.UpdateCallback = updateCone

MODEL:addChild(xform)

-- === Add a per-frame callback =============================================
local frame=0

local function cone_perframe(sim_time)
    frame = frame + 1
    if (frame % 300) == 0 then        -- every ~5 sec
        print('sim time',sim_time,'since T0',sim_time-T0)
    end
end

doPerFrame(cone_perframe)

-- vi: set ts=4 sts=4 sw=4 et ai: --
