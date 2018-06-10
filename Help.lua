-- Help.lua: functions for saving and accessing help for functions.
-- Always in the global environment, so just do `require 'Help';`.

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'checks'
print_r = require 'print_r'

-- The table that will store the help info
_G.HELP = _G.HELP or setmetatable({}, {__mode = "kv"})
    -- A weak table - thanks to http://lua-users.org/wiki/DecoratorsAndDocstrings

function help(x)
    checks('?string|function|table')
    if not x then
        print([[help(x): show help for `x` from the global HELP table.
Available topics are:]])
        for k,_ in pairs(HELP) do
            if type(k) ~= 'function' then print(k) end
        end
        return
    end

    local kind = 'table'
    local name = '<unknown>'

    if HELP[x] then
        print(tostring(x))
        print(HELP[x])
        return

    elseif type(x)=='string' and package.loaded[x] then
        -- It's a package name.  Report help for it.
        name = x
        x = package.loaded[x]
        kind = 'package'

    elseif type(x)=='string' and _G[x] and HELP[_G[x]] then
        print(tostring(x))
        print(HELP[_G[x]])
        return
    end

    if type(x)=='table' then
        print('In ' .. kind .. ' ' .. name .. ' (* = more help available):')
        for k, v in pairs(x) do
            if HELP[v or k] then print('*',k) else print(' ',k) end
                --  ^^^^^^ v first since k is always truthy
        end
    else
        print('No help available for ' .. tostring(x))
    end
end --help()

-- Add help text #thehelp for #x.  If #g_too, #x is the name of a global.
-- Also attach the help to that global itself.
function sethelp(x,thehelp, g_too)
    checks('string|function|table','string','?boolean')
    HELP[x] = thehelp
    if g_too and _G[x] then HELP[_G[x]] = thehelp end
end

-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
