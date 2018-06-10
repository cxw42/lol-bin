-- Content.lua: Content class

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'checks'
require 'Help'
local Util = require 'Util'

-- For now, doesn't support attribute arrays.  Also, for now, all arrays
-- are per-vertex.  If you specify nil for an array when loading, it gets the
-- value from the previous vertex, or a (sensible?) default.
-- VertexData array.
local Content = {}

-- ctor.  Call as Content:new().  Uses the OOP pattern from PIL sec. 16.1.
function Content.new(cls, obj)
    checks('table','?table')
    obj = obj or {}
    setmetatable(obj, cls)
    cls.__index=cls     -- where Lua will look up methods called on obj

    -- make a new osg array type, with the given optional binding or
    -- bind-per-vertex.
    local function makearray(ty, binding)
        local arr = new(ty)
        arr.Binding = binding or 'BIND_PER_VERTEX'
        return arr
    end

    -- Give the new object some geometry
    obj.geom = new('osg::Geometry')
    obj.geom.DataVariance = 'DYNAMIC'   -- play it safe
    obj.geom.VertexArray = makearray 'osg::Vec3Array'
    obj.geom.NormalArray = makearray 'osg::Vec3Array'
    obj.geom.ColorArray = makearray 'osg::Vec4Array'
    obj.geom.TexCoordArray = makearray 'osg::Vec2Array'
    obj.geom.TexCoordArrayList:add(obj.geom.TexCoordArray)
        -- Texture coords are also available for texture unit 0.  It's unit 0
        -- because TexCoordArrayList is initially empty, so the add() call
        -- fills element 0.
    obj.geom.SecondaryColorArray = makearray 'osg::Vec4Array'
    obj.geom.FogCoordArray = makearray 'osg::FloatArray'

    -- Give it a StateSet
    obj.ss = new('osg::StateSet')       -- for convenient reference
    obj.ss.DataVariance = 'DYNAMIC'     -- play it safe
    obj.geom.StateSet = obj.ss

    -- initialize instance data
    -- TODO support VertexAttribData
    --obj.attr2array={}   -- Attribute names to array numbers
    --obj.array2attr={}   -- reverse map

    obj.is_building = false
    obj.is_assembling = false
    obj.assem_into = nil        -- a primitive set
    obj.live_build = true

    -- If we are in a livecoding environment, add it to the model
    --[[if _G.MODEL then
        MODEL:addChild(obj.geom)
        S = obj.geom
    end]]

    return obj
end

sethelp(Content.new,[[Create a new Content instance.  No parameters.
Call as Content:new().]])

----- State -----

-- Set the fixed-pipeline lighting
function Content:lighting(is_on)
    checks('table','boolean')
    self.ss:set('GL_LIGHTING', (is_on and 'ON' or 'OFF') .. ' OVERRIDE')
end
sethelp(Content.lighting,'Content.lighting(true/false) - set GL lighting')

----- Building: creating primitive sets while adding vertices -----

function Content:build_in_progress()
    checks('table')
    return (self.is_assembling or self.is_building)
end

-- Finish a build begun by startbuild()
function Content:endbuild()
    checks('table')
    if self.is_assembling then error("Can't build while assembling") end
    if not self.is_building then error("Can't call endbuild before startbuild()") end

    self.is_building = false
    self.assem_into.Count = self.geom.VertexArray:size() - self.assem_into.First
        -- The last vertex of the build is size-1 (0-based).  Therefore
        -- size is last+1, so size-first is the same as
        -- last-first+1 == the number of elems on [first,last].
    self.assem_into = nil

    self.geom:dirty()
end

-- Start a build.  Unless no_live_update is specified with a true value,
-- the primitive set will be updated live as building progresses.
function Content:startbuild(mode, no_live_update)
    checks('table','string','?boolean')
        -- table is the implicit self parameter
    if self.is_assembling then error("Can't build while assembling"); end
    if self.is_building then self:endbuild(); end

    self.is_building = true

    self.assem_into = new('osg::DrawArrays')
    self.assem_into.DataVariance = 'DYNAMIC'
    self.assem_into.Mode = mode
    self.assem_into.First = self.geom.VertexArray:size()
    self.assem_into.Count = 0

    self.geom.PrimitiveSetList:add(self.assem_into)

    self.live_build = not no_live_update
end
sethelp(Content.startbuild,[[
function Content:startbuild(mode, no_live_update)
Start a build.  Unless no_live_update is specified with a true value,
the primitive set will be updated live as building progresses.

#mode values (specify as strings, e.g., 'POINTS'):
    POINTS
    LINES
    LINE_STRIP
    LINE_LOOP
    TRIANGLES
    TRIANGLE_STRIP
    TRIANGLE_FAN
    QUADS
    QUAD_STRIP
    POLYGON
    LINES_ADJACENCY
    LINE_STRIP_ADJACENCY
    TRIANGLES_ADJACENCY
    TRIANGLE_STRIP_ADJACENCY
    PATCHES]])


-- Helper for Content:newvload().  Load new_values[value_idx], or def_value,
-- or the preceding value, expanded to vec_size elements, into which_table.
local function stuffdata(new_values, value_idx, vec_size, which_table, def_value)

    -- Make a function to prep data for insertion
    local expander
    if vec_size > 1 then
        expander = function(val) return Util.vec2seq(val, vec_size) end
    else
        expander = function(val) return val end
    end

    if new_values.n>=value_idx and new_values[value_idx] then   -- value provided
        which_table:add(expander(new_values[value_idx]))

    elseif which_table:size()<=0 then           -- default value for new array
        which_table:add(expander(def_value))

    else                                        -- copy value from previous row
        local t = which_table
        t:add(t[t:size()-1])    -- add a copy of the last element
    end
    which_table:dirty()
end --local stuffdata()

-- Load a vertex, e.g., during a build.  Parameters are tables having the
-- values of the arrays, in the order:
-- vertex (vec3), normal (vec3), color (vec4), texture (vec2),
-- secondary color (vec4), fog (float).
-- Specify nil to use the default for that parameter.
function Content:newvload(...)
    -- Not sure why checks() doesn't work here, but oh well
    --data = table.pack(...)
    --print 'in newvload:'
    --print_r(data)
    --checks('table', 'table', '?table', '?table', '?table', '?table', '?number')
    ----     self     vertex   normal    color     texture   2nd color fog

    data = table.pack(...)

    -- Vertex data, vec3
    stuffdata(data, 1, 3, self.geom.VertexArray, {0,0,0})

    -- Normal data, vec3
    stuffdata(data, 2, 3, self.geom.NormalArray, {0,-1,0})   -- towards viewer

    -- Color data, vec4
    stuffdata(data, 3, 4, self.geom.ColorArray, {0.8, 0.8, 0.0, 1.0})   -- brightish yellow

    -- Texture coords, vec2
    stuffdata(data, 4, 2, self.geom.TexCoordArray, {0,0})

    -- Secondary color, vec4
    stuffdata(data, 5, 4, self.geom.SecondaryColorArray, {0.0, 0.8, 0.8, 1.0})   -- brightish cyan

    -- Fog color, float (default distance 0 => no fog effect)
    stuffdata(data, 6, 1, self.geom.FogCoordArray, 0.0)

    if self.live_build then
        self.assem_into.Count = self.assem_into.Count + 1
        -- otherwise Count will be updated by endbuild()
        self.geom:dirty()
    end

end --Content:newvload

sethelp(Content.newvload,[[Content:newvload(...)
Load a vertex, e.g., during a build.  Parameters are tables having the
values of the arrays, in the order:
    vertex (vec3),
    normal (vec3),
    color (vec4),
    texture (vec2),
    secondary color (vec4),
    fog (float).
Specify nil to use the default for that parameter.
]])

----- Modifying -----
function Content:refresh()
    checks('table')

    -- Play it safe - dirty everything
    if self.geom.VertexArray then self.geom.VertexArray:dirty() end
    if self.geom.NormalArray then self.geom.NormalArray:dirty() end
    if self.geom.ColorArray then self.geom.ColorArray:dirty() end
    if self.geom.TexCoordArray then self.geom.TexCoordArray:dirty() end
    if self.geom.SecondaryColorArray then self.geom.SecondaryColorArray:dirty() end
    if self.geom.FogCoordArray then self.geom.FogCoordArray:dirty() end

    -- Have to dirty the geometry itself, as well.
    self.geom:dirty()
end
sethelp(Content.refresh,[[c:refresh()
Call after changing c.geom.VertexArray, c.geom.NormalArray, c.geom.ColorArray,
c.geom.TexCoordArray, c.geom.SecondaryColorArray, or c.geom.FogCoordArray
to make the changes take effect.]])

return Content

-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
