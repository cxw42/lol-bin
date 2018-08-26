-- text.lua: Demonstration of text in lua-osg-livecoding
-- cxw/Incline 2018

-- Show the size of the current background viewport
local hud_camera = BG:getParent(0)
local v = hud_camera.Viewport:get()
print(string.format('Viewport: %dx%d@(%d,%d)', v.z, v.w, v.x, v.y))

text = new('osgText::Text')

-- Set properties listed in osg/src/osgWrappers/serializers/osgText/TextBase.cpp
text.FontName='assets/AnonymousPro.ttf'
text.CharHeight = 4
text.TextUTF8='Hello, world!'
text.AxisAlignment = 'USER_DEFINED_ROTATION'
text.Alignment = 'LEFT_BASE_LINE'
text.Position = {1,5,0}

-- Tip it forward 30 degrees from the default orientation, which is in
-- the XY plane.  Rotation forward is positive because it's right-handed ---
-- point your right thumb to the right (along the X axis) and your fingers curl
-- in the positive direction of rotation.
text.Rotation = UTIL:quatRotate(math.rad(30), {1,0,0})

-- Set properties listed in osg/src/osgWrappers/serializers/osgText/Text.cpp
text.Color={.5,1,.5,1}
text.BackdropType='DROP_SHADOW_BOTTOM_RIGHT'
text.BackdropOffsetH = 0.1
text.BackdropOffsetV = 0.2

-- Color-gradient colors
text.CGTopLeft={0,0,0,1}
text.CGBottomLeft={1,0,0,1}
text.CGBottomRight={1,1,0,1}
text.CGTopRight={1,1,1,1}

local last_user_rotation   -- rotation state

function textrotation()
    if text.AxisAlignment == 'XZ_PLANE' then
        print 'user-defined rotation'
        text.AxisAlignment = 'USER_DEFINED_ROTATION'
        text.Rotation = last_user_rotation
    elseif text.AxisAlignment == 'USER_DEFINED_ROTATION' then
        last_user_rotation = text.Rotation
        print 'screen-aligned text'
        text.AxisAlignment = 'SCREEN'
    else
        print 'XZ-plane text'
        text.AxisAlignment = 'XZ_PLANE'
    end
end

function textgradient()
    -- Note: for some reason we have to pass through SOLID to change
    -- between PER_CHARACTER and OVERALL.

    if text.ColorGradientMode == 'SOLID' then
        print('per-character gradient')
        text.ColorGradientMode = 'PER_CHARACTER'

    elseif text.ColorGradientMode == 'PER_CHARACTER' then
        print('overall gradient')
        text.ColorGradientMode='SOLID'
        doNextFrame(function() text.ColorGradientMode='OVERALL' end)    -- this works, empirically

    else -- ColorGradientMode=='OVERALL'
        print('solid color')
        text.ColorGradientMode='SOLID'
    end
end --gradient()

MODEL:addChild(text)
print([[
 * `text` is the text instance
 * call `textgradient()` to cycle gradient
 * call `textrotation()` to cycle between XZ-plane, screen, and text.Rotation
]])

-- vi: set ts=4 sts=4 sw=4 et ai: --
