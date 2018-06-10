-- texture.lua: lua-osg-livecoding sample
-- Functions to texture-map a quad.
-- cxw/Incline 2018

--[[
OK, get ready for a wild ride.  On my test system, the fixed-function pipeline
emulation supports colors, but not texturing.  Therefore, we have to use
a fragment shader to do the texturing.  Since we have to use a fragment shader,
we also have to use a vertex shader.  The good news is that Geometry.lua
provides a default vertex shader that will do the job.
--]]

local Geometry = require 'Geometry'

-- === Basics ===

-- Make geometry
q = quad({1,0,1},{3,0,1},{3,0,3})

-- Read the image.  NOTE: sides must be power-of-two lengths in pixels.
img = readImageFile('assets/texture.png')
img.Name = "our_image"

-- Attach the image to a texture
tex = new('osg::Texture2D')
tex.Image = img
tex.Name = "our_texture"

-- Attach the texture to the geometry (ss = osg::StateSet).
--
-- StateSet manipulation is handled through lua add(), set(), get(), remove()
-- methods.  See osg/src/osgPlugins/LuaScriptEngine.cpp, functions
-- callStateSetSet(), callStateSetGet(), and callStateSetRemove().
--
-- Names you can use with get() are:
--  - class names (without package, e.g., 'Texture2D'
--  - object names (the .Name) field
--  - GL attribute/mode names (set in osg/src/osgDB/ObjectWrapper.cpp,
--      in the constructor for ObjectWrapperManager)

q.ss:add(0, tex)        -- 0 => texture unit 0

--q.ss:set(0, 'TEXTURE')    -- not supported on my test system
--q.ss:set(0, 'TEXTURE0')   -- not supported on my test system
--q.ss:set(0, 'REPEAT')   -- wrap/clamp
--q.ss:set(0, 'LINEAR')   -- filtering

-- === Uniform ===
-- This section makes the texture accessible to the fragment shader as
-- uniform variable 'sampler'.

-- Make an array to hold the single value 0.  Have to do this because
-- SAMPLER_2D requires an integer unit number, and all literal numbers in the
-- Lua source are considered to be floats or doubles.
samplerValueArray = new('osg::IntArray')
samplerValueArray:add(0)     -- 0 => texture unit 0

-- Make the variable and add it to the StateSet so it will be visible.
sampler = Geometry.makeUniform('sampler', 'SAMPLER_2D', samplerValueArray)
q.ss:add(sampler)

-- === Shader ===
vdesc = Geometry.string2sdesc('VERTEX', default_vshader)

fdesc = Geometry.string2sdesc('FRAGMENT',
    fshader_color_needs_color ..    -- this calls vec4 color(), supplied here.
    [=[
    varying vec2 uv;                // Texture coords from the vertex shader
    uniform sampler2D sampler;      // The texture, from the uniform set above
    vec4 color() {
        if(gl_FrontFacing) {    // Front side of the quad
            return texture2D(sampler, uv);  // Get the value from the texture

        } else {                // Back side of the quad
            // A simple test, just to make sure it's actually running.
            // Pan the view, and you will see the colors of the square change.
            vec2 other_uv = gl_FragCoord.xy/iResolution.xy;
            return vec4(mod(iGlobalTime*0.25, 1.0), other_uv, 1.0);
        }
    }
    ]=],
    'tex_map_vertex_shader'     -- name of the shader; our choice
)

-- Compile/link the vertex and fragment shaders into a program
pgm = Geometry.makeProgram(
    'our_program',      -- name (our choice)
    vdesc, fdesc        -- the shaders to use
)

-- Load the program onto the quad
Geometry.applyProgram(q.geom, pgm)

-- vi: set ts=4 sts=4 sw=4 et ai: --
