-- Geometry.lua: geometry routines, including object creation and
-- state manipulation.

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'checks';
require 'Help';

local Util = require 'Util';
local stringx = require 'pl.stringx';   --from penlight
local tablex = require 'pl.tablex';

local Geometry = {}

-- =====================================================================
-- Shape creation

local function preshape(color, name)
    local the_drawable = new("osg::ShapeDrawable")
    the_drawable.Color = Util.vec2seq(color, 4)
    if name and (name ~= '') then
        the_drawable.Name = name
    end
    return the_drawable
end

local function postshape(the_drawable, the_shape)
    -- set drawable.Shape after initializing the_shape
    the_drawable.Shape = the_shape
    local pat = new 'osg::PositionAttitudeTransform'
    pat:addChild(the_drawable)
    return pat
end

-- Make a sphere ShapeDrawable.
-- Color, center, radius are required; name is optional.
function Geometry.makeSphere(color, center, radius, name)
    checks('table','table','number','?string')
    local the_drawable = preshape(color, name)

    local the_shape = new("osg::Sphere")
    the_shape.Center = Util.vec2seq(center,3)
    the_shape.Radius = radius

    return postshape(the_drawable, the_shape)
end --makeSphere()

sethelp(Geometry.makeSphere,[[
Make a sphere ShapeDrawable.
Color, center, radius are required; name is optional.
function Geometry.makeSphere(vec4 color, vec3 center, float radius, string name)
]])

function Geometry.makeBox(color, center, halflens, name)
    checks('table','table','table','?string')
    local the_drawable = preshape(color, name)

    local the_shape = new('osg::Box')
    the_shape.Center = Util.vec2seq(center,3)
    the_shape.HalfLengths = halflens

    return postshape(the_drawable, the_shape)
end
sethelp(Geometry.makeBox,[[
function Geometry.makeBox(color, center, vec3 half-lengths, name)]])

function Geometry.makeCone(color, center, radius, height, name)
    checks('table','table','number', 'number', '?string')
    local the_drawable = preshape(color, name)

    local the_shape = new('osg::Cone')
    the_shape.Center = Util.vec2seq(center,3)
    the_shape.Radius = radius
    the_shape.Height = height

    return postshape(the_drawable, the_shape)
end
sethelp(Geometry.makeCone,[[
function Geometry.makeCone(color, center, float radius, float height, name)
]])

function Geometry.makeCapsule(color, center, radius, height, name)
    checks('table','table','number', 'number', '?string')
    local the_drawable = preshape(color, name)

    local the_shape = new('osg::Capsule')
    the_shape.Center = Util.vec2seq(center,3)
    the_shape.Radius = radius
    the_shape.Height = height

    return postshape(the_drawable, the_shape)
end
sethelp(Geometry.makeCapsule,[[
function Geometry.makeCapsule(color, center, float radius, float height, name)
]])

function Geometry.makeCylinder(color, center, radius, height, name)
    checks('table','table','number', 'number', '?string')
    local the_drawable = preshape(color, name)

    local the_shape = new('osg::Cylinder')
    the_shape.Center = Util.vec2seq(center,3)
    the_shape.Radius = radius
    the_shape.Height = height

    return postshape(the_drawable, the_shape)
end
sethelp(Geometry.makeCylinder,[[
function Geometry.makeCylinder(color, center, float radius, float height, name)
]])


-- =====================================================================
-- Motions

function Geometry.pos_clelies(time, radius, speed)
    --Clelies curve
    --thanks to http://wiki.roblox.com/index.php?title=Parametric_equations ,
    --now available at http://blockland.wikia.com/wiki/Parametric_equations
    local sin=math.sin
    local cos=math.cos
    local pos = {}
    local smt = sin(speed*time)
    pos.x = radius * smt*cos(time)
    pos.y = radius * smt*sin(time)
    pos.z = radius * cos(speed*time)
    return pos
end --pos_clelies()
sethelp(Geometry.pos_clelies,
    'pos_clelies(float time, float radius, float speed)')
sethelp('Geometry.pos_clelies',[[See help(Geometry.pos_clelies)]])

-- =====================================================================
-- Shaders

-- Shaders are described, for purposes of easy editing, by a "description."
-- That is a table including:
--  - a sequence part that holds the source lines, 1..n.
--  - a hash part with keys:
--      - 'ty' for the type of the shader
--      - 'name' for the name of the shader

-- Make a shader of the given type from the given source string
local _sdesc_idx = 0
function Geometry.string2sdesc(ty, source, name)
    checks('string','string', '?string');
    retval=stringx.splitlines(source);
    retval.ty = ty
    if not name then
        name = 'shader_' .. ty .. '_' .. _sdesc_idx
        _sdesc_idx = _sdesc_idx + 1     -- make sure the name is unique
    end
    retval.name = name
    return retval
end --string2sdesc()
sethelp(Geometry.string2sdesc, [[
Geometry.string2sdesc(ty, source): string #source, split into lines,
into a shader description.  #ty can be 'VERTEX' or 'FRAGMENT'.]])

-- Make an actual shader from an sdesc
function Geometry.sdesc2shader(sdesc)
    checks('table');
    local src = stringx.join('\n', sdesc)   -- only does the sequence part
    shader = new('osg::Shader')
    shader:source(src)
    shader.Type = sdesc.ty
    shader.Name = sdesc.name or ''
    return shader
end --sdesc2shader()
sethelp(Geometry.sdesc2shader,
[[ Make an actual shader from an sdesc.
function Geometry.sdesc2shader(sdesc)]])

-- Helper for makeAndApplyProgram().  Make a shader from #desc.
local function make_shader( desc,           isfile)
    checks(                 'table|string', '?');
    local shader;

    if type(desc)=='table' then
        shader = Geometry.sdesc2shader(desc);
    else    -- string descr
        if isfile then
            shader = readFile(desc)
            if not shader then error('Could not load shader ' .. desc) end
        else
            shader = new('osg::Shader')
            shader:source(desc)
        end
    end
    return shader
end

-- Make a shader program.
-- If #vert and #frag are tables, they are sdescs.
-- If they are strings and #isfile, #vert and #frag are filename s.
-- Otherwise, they are GLSL.
function Geometry.makeProgram(
            program_name,   vert,           frag,           isfile)
    checks( 'string',       'table|string', 'table|string', '?')

    local pgm = new('osg::Program')
    pgm.Name = program_name

    local vshader, fshader

    vshader = make_shader(vert, isfile);
    vshader.Type = 'VERTEX';

    fshader = make_shader(frag, isfile);
    fshader.Type = 'FRAGMENT';

    pgm:shader('add', vshader)
    pgm:shader('add', fshader)

    return pgm
end --Geometry.makeProgram
sethelp(Geometry.makeProgram, [[
-- Make a shader program.
-- If #vert and #frag are tables, they are sdescs.
-- If they are strings and #isfile, #vert and #frag are filename s.
-- Otherwise, they are GLSL.
function Geometry.makeProgram(
            program_name,   vert,           frag,           isfile)
    checks( 'string',       'table|string', 'table|string', '?')
]])

-- Applies the shaders in #pgm to the StateSet associated with #node.
function Geometry.applyProgram(node, pgm)
    local ss = node:getOrCreateStateSet()
    ss:add(pgm)     -- Automatically replaces any program that's already
                    -- there, as far as I can tell.
    return node     -- for convenience
end --applyProgram()
sethelp(Geometry.applyProgram, [[
-- Applies the shaders in #pgm to the StateSet associated with #node.
function Geometry.applyProgram(node, pgm)]])

-- Creates and applies the shaders to the StateSet associated with #node.
-- Other parameters are as Geometry.makeProgram.
function Geometry.makeAndApplyProgram(
            node, program_name, vert,           frag,           isfile)
    checks('table','string',    'table|string', 'table|string', '?')
    local pgm = Geometry.makeProgram(program_name, vert, frag, isfile)

    Geometry.applyProgram(node, pgm)
    return node -- for convenience
end --makeAndApplyProgram()
sethelp(Geometry.makeAndApplyProgram, [[
-- Creates and applies the shaders to the StateSet associated with #node.
-- Other parameters are as Geometry.makeProgram.
function Geometry.makeAndApplyProgram(
            node, program_name, vert,           frag,           isfile)
    checks('table','string',    'table|string', 'table|string', '?')]])

-- Create a Uniform
function Geometry.makeUniform(name, ty, initial_value, nelems)
    checks('string','string','?','?number')
    local retval = new('osg::Uniform')
    retval.Name = name
    retval.DataVariance = 'DYNAMIC'
    retval.NumElements = nelems or 1
    retval.Type = ty
    if type(initial_value) ~= 'nil' then
        retval:value(initial_value)
    end
    return retval
end --makeUniform()
sethelp(Geometry.makeUniform, [=[
-- Create a Uniform
function Geometry.makeUniform(name, ty[, initial_value[, number of elements]])
    Valid #ty values are strings of the ADD_ENUM_VALUE lines in
    src/osgWrappers/serializers/osg/Uniform.cpp
]=])

-- ===========================
-- Some built-in shaders

default_vshader_needs_getuv= [[
// From osgshaders example
#version 130
precision highp int;
precision highp float;
varying vec2 uv;
vec2 getuv();

void main(void)
{
    uv = getuv();
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
]]
sethelp('default_vshader_needs_getuv', [[
Default vertex shader.  Append a definition of vec2 getuv(), e.g.,
getuv_texture, getuv_color_xz, getuv_centered_hud]], true)

getuv_texture=[[
vec2 getuv() { return gl_MultiTexCoord0.xy; }
]]
sethelp('getuv_texture',[[Use with default_vshader_needs_getuv]], true)

getuv_centered_hud=[[
        uniform vec2 iResolution;
        vec2 getuv() {  // move the origin to the center of the window
            vec2 retval;
            //return gl_Vertex.xy;  //gl_Vertex;
            // For the HUD, (0,0)->(1,1) (LL->UR).
            if(iResolution.x > iResolution.y) {     // landscape - x range >1
                retval.y = gl_Vertex.y - 0.5;       // move to the center
                retval.x = (gl_Vertex.x - 0.5) * iResolution.x / iResolution.y;
            } else {                                // portrait - y range >1
                retval.x = gl_Vertex.x - 0.5;       // move to the center
                retval.y = (gl_Vertex.y - 0.5) * iResolution.y / iResolution.x;
            }
            return retval;
        }
]]
sethelp('getuv_centered_hud',[[Use with default_vshader_needs_getuv]], true)

default_vshader = default_vshader_needs_getuv .. getuv_texture
sethelp('default_vshader',[[Default vertex shader; uses getuv_texture]], true)

getuv_color_xz = [[
vec2 getuv() { return gl_Color.xz; }
]]
sethelp('getuv_color_xz',[[Use with default_vshader_needs_getuv.
Uses the red and blue components for u and v, respectively.]], true)

fshader_color_needs_color=[[
#version 130
precision highp int;
precision highp float;

vec4 color();

uniform float iGlobalTime;  // from main.cpp
uniform vec2 iResolution;   // from main.cpp
void main( void ) {
    gl_FragColor = color();
}
]]
sethelp('fshader_color_needs_color',[[
Fixed-color fragment shader.  Append a definition of vec4 color().]], true)

fshader_adaptation=
[[
#version 130
precision highp int; precision highp float;
// Adaptation, modified from tdf17.frag.in by cxw/Incline (ncl01: Road Trip)
uniform float iGlobalTime;
uniform vec2 iResolution;
void mainImage( out vec4 fragColor, in vec2 fragCoord );
void main( void )
{
    vec4 color = vec4(0.0,0.0,0.0,1.0);
    mainImage( color, gl_FragCoord.xy );
    gl_FragColor = color;
}
]]
sethelp('fshader_adaptation',[[
This string provides a definition of
  void mainImage( out vec4 fragColor, in vec2 fragCoord );
so you can use ShaderToy-style routines.
Can use iGlobalTime, iResolution]], true)

fshader_hud_circles=[[
// Modified from demosplash-2016/03.frag by cxw/Incline

#define PI (3.1415926535897932384626433832795028841971)
    // from memory :)
#define PI_OVER_2 (1.5707963267948966192313216916398)
#define PI_OVER_4 (0.78539816339744830961566084581988)
#define THREE_PI_OVER_4 (2.3561944901923449288469825374596)
#define TWO_PI (6.283185307179586)
#define ONE_OVER_TWO_PI (0.15915494309644431437107064141535)
    // not from memory :) :)

uniform float circle_speed, circle_interval, circle_shift;

vec4 do_color(in float time, in vec2 coords,
                in float speed, in float how_often, in float phase_shift)
{
    float dist = distance(vec2(0),coords);  //uvs have origin at the center
    float phase = speed*time + phase_shift;
    float whereami = -50 + 50.0*dist - phase;     // f = 50/2pi
        //Goes negative as the animation progresses

    // Not what I wanted, but still cool
    //float val = 0.5+0.5*sin(whereami) *
    //            step(0.0, sin(50.0/4.0*dist-phase));

    // Also cool
    //float val = (0.5+0.5*sin(whereami)) *
    //            step(0.0, sin(50.0*4.0*dist-phase));

    float which_one = abs(whereami * ONE_OVER_TWO_PI);  //which ring
    float this_ring_p = mod(which_one, how_often) ;    //every nth ring
    float val = (0.5+0.5*sin(whereami)) *
                step(0.2, this_ring_p) *    //0.2, 1.2 are empirical
                (1-step(1.2, this_ring_p));

    //val = this_ring_p * 0.25;
    float val2 = coords.x < 0.5 ? val : 0.5+0.5*sin(whereami);  //debug
    return vec4(0.0,0.0,
                val,  // render in the blue channel
                1.0);
} //do_color

float do_window(in float time, in float x)
{
    float window_pos = abs(0.5*sin(time));
        // from 0 to 0.5 and back, over and over again
    return step(window_pos,  x);
    //          ^^^^^^^^^^ > ^  => 0.0 else 1.0
} //do_window

varying vec2 uv;    // 1:1 aspect ratio, origin at window center

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iGlobalTime;
    vec4 scene_color = do_color(t, uv, circle_speed*TWO_PI, circle_interval, circle_shift);
    //vec4 scene_color = do_color(t, uv, 2.33296005*TWO_PI, 4, 0);
        // empirical BPM of Firing Up by MoN, converted to beats per sec.
        // (almost 140bpm, which would be 2.3333....)
        // TODO convert bpm to speed for a given ring count
    float window =  1.0;
        // or how about this?  (cxw: reset time first)
        // do_window(t, uv.x);
    fragColor = scene_color * window;
} //mainImage

// vi: set ts=4 sts=4 sw=4 et ai: //

]]
sethelp('fshader_hud_circles','use with fshader_adaptation', true)

fshader_crazy = [[
// Adapted from the glslsandbox default
#version 130
precision highp float;

//#define REFERENCE_TO_SCREEN
    // if defined, coords are referenced to the screen.
    // if not, coords are referenced to the poly in which they appear.

#define LOADING_FREQ (0.2)
#define TWO_PI (6.283185307179586)

uniform float iGlobalTime;  // from main.cpp
//uniform vec2 iResolution;   // from main.cpp
uniform vec2 Origin;

//uniform float s_speed;      // s_* = from rocket
float s_speed;

varying vec2 uv;            // from the vertex shader

vec2 get_uvs( void ) {
    // Determine where we are in quad-relative coordinates.
    // retval.x goes from 0.0 at the left to 1.0 at the right.
    // retval.y goes from 0.0 at the bottom to 1.0 at the top.

#ifdef REFERENCE_TO_SCREEN
    vec2 retval = gl_FragCoord.xy/iResolution;
    //(0.0, 0.0)->(1.0, 1.0) for the full-screen rectangle
    // ** NOTE ** gl_FragCoord.xy and iResolution.xy because these are
    // screen space (X is to the right and Y is up)
#else
    vec2 retval = clamp(uv, 0.0, 1.0);
    // This references the image to the poly in which it is generated.
    // ** NOTE ** the geometry is in the XZ plane
    // (X is to the right and Z is up)
#endif
    return retval;
}  //get_uvs

void main( void ) {
    s_speed = 0.1;
    float the_time = iGlobalTime*s_speed;

    // GLSL Sandbox default, tweaked slightly
    float color = 0.0;
    float rotation = mod( /*LOADING_FREQ*/ s_speed * the_time, TWO_PI);
    mat2 rot = mat2(cos(rotation), sin(rotation), -sin(rotation), cos(rotation));

    vec2 my_uv = get_uvs() + Origin;     //(0,0) = LL; (1,1) = UR
    vec2 position = rot*my_uv; //clamp(rot * my_uv, 0.0, 1.0);
    gl_FragColor = vec4(position.x, position.y, 0.0, 1.0);
    //return;

    color += sin( position.x * cos( the_time / 15.0 ) * 80.0 ) + cos( position.y * cos( the_time / 15.0 ) * 10.0 );
    color += sin( position.y * sin( the_time / 10.0 ) * 40.0 ) + cos( position.x * sin( the_time / 25.0 ) * 40.0 );
    color += sin( position.x * sin( the_time / 5.0 ) * 10.0 ) + sin( position.y * sin( the_time / 35.0 ) * 80.0 );
    color *= sin( the_time / 10.0 ) * 0.5;
    gl_FragColor = vec4( vec3( color, color * 0.5, sin( color + the_time / 3.0 ) * 0.75 ), 1.0 );

    //gl_FragColor = vec4( my_uv.x, my_uv.y, 0.0, 1.0);
    // Uncomment this to see the xy axes in colors
}
]]
sethelp('fshader_crazy',[[glsl sandbox tweaked default.
Use on its own - doesn't need anything else.]], true)

return Geometry

-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
