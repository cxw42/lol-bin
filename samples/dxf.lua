-- dxf.lua: lua-osg-livecoding sample
-- cxw/Incline 2018

-- This shows a shape loaded from a DXF.  The DXF was exported from Inkscape
-- per https://kellylollardesigns.com/blogs/news/converting-svg-to-dxf
-- with the base units set to pt.  The origin of the SVG maps to the origin
-- of the OSG coordinate system, and the DXF is by default in the XY plane.

local Util = require 'Util'

dwg = readNodeFile('assets/drawing.dxf')    -- Load

-- First copy
xform1 = new 'osg::MatrixTransform'
    -- leave the transform at identity

mask1 = new 'osg::ColorMask'    -- Use a color mask to distinguish the copies
mask1.GreenMask = false     -- can't write green => red+blue
xform1:getOrCreateStateSet():set(mask1)

xform1:addChild(dwg)
MODEL:addChild(xform1)

-- Second copy
xform2 = new 'osg::MatrixTransform'
xform2.Matrix = UTIL:xformRotate(math.pi/2, {1,0,0})

mask2 = new 'osg::ColorMask'
mask2.RedMask = false     -- can't write red => green+blue
xform2:getOrCreateStateSet():set(mask2)

xform2:addChild(dwg)
MODEL:addChild(xform2)


-- vi: set ts=4 sts=4 sw=4 et ai: --
