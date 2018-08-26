-- sync-example.lua
-- cxw/Incline 2017--2018
-- Show different squares controlled by a Sync instance.
-- This is an example of how to do animation.
--
-- Run as:
--  livecoding -m assets/Kevin_MacLeod_-_The_Rule.ogg -o
--          -r samples/sync-example.lua

local Geometry = require 'Geometry'
local Sync = require 'Sync'
local SYNC_FILENAME = 'assets/sync_Kevin_MacLeod_-_The_Rule.csv'
curr_time = 0

-- === Grab the updated values each frame ===================================

local sync_data = Sync:new(SYNC_FILENAME, MODEL)
print(string.format('Loaded %d channels of sync data from %s',
        sync_data.nchannels, SYNC_FILENAME))
for uniform_name, u in pairs(obj.uniforms) do
    print(string.format('    Uniform %s = channel %d', uniform_name, u.chanidx))
end

local curr  -- Current values for all the channels

doPerFrame(function(time)
    curr_time = time
    curr = sync_data:get_and_set_uniforms(time)
    -- Returns data in #curr for us to use, and also sets any uniforms
    -- indicated in the sync data.
end)

-- === Channel 1 ============================================================
-- Channel 1 is a progress indicator

-- The background has range (0,0)->(1,1) filling the viewport.  The coordinates
-- are X>, Y^, Z out.  Things with Z<=0 are visible.
-- This is in the background, so the geometry will be on top of it.
hudcamera = BG:getParent(0)
local viewport = hudcamera.Viewport:get()   -- Just in case you care
viewport = {w=viewport.z, h=viewport.w}

text = new 'osgText::Text'
text.FontName='assets/AnonymousPro.ttf'     -- because it's awesome
text.CharHeight = 0.1               -- as a percentage of the HUD
text.TextUTF8=''                    -- initially
text.AxisAlignment = 'XY_PLANE'     -- BG HUD is XY, not XZ
text.Alignment = 'RIGHT_BOTTOM'     -- Stick it in the bottom-right corner
text.Position={1,0,0}
text.ResolutionW=64
text.ResolutionH=64

hudcamera:addChild(text)

-- Update the text every frame.  doPerFrame() callbacks are called in the
-- order they of doPerFrame calls, so when we get here, `curr` has already
-- been set by the previous callback.
doPerFrame(function()   -- Show the percentage of the way through.
    text.TextUTF8=string.format('%d%%', math.floor(curr[1]*100))
end)

-- === Foreground text ======================================================
-- Just because this is a convenient place to show how to do it!

fgtext = text:clone()
fgtext.Position={0,0,0}
fgtext.Alignment='LEFT_BOTTOM'
fgtext.TextUTF8='Foreground'
FG:addChild(fgtext)

-- === Channel 2 ============================================================

local q = quad({2,1,0},{3,1,0},{3,1,1})   -- also adds the quad to the model

-- Vertex shader
local vdesc = Geometry.string2sdesc('VERTEX', default_vshader)

-- Fragment shader
local uname = sync_data.channels[2].uniform_name
local fdesc = Geometry.string2sdesc('FRAGMENT',
    fshader_color_needs_color ..    -- this calls vec4 color(), supplied here.
    [=[
    uniform float ]=] .. uname .. [=[;

    vec4 color() {
        // pretty much the same as updateCone(), but in GLSL rather than Lua.
        float shade = mod(]=] .. uname .. [=[, 1.0);
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
