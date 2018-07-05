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

-- === Code from elsewhere =============================================

--[[
Ordered table iterator.
Modified from http://lua-users.org/wiki/SortedIteration .
This has to be in Help rather than in Util because Util requires Help.
]]--

local function defaultKeySort(key1, key2)
  -- "number" < "string", so numbers will be sorted before strings.
    local type1, type2 = type(key1), type(key2)
    if type1 ~= type2 then
        return type1 < type2
    elseif type1 == 'string' then
        return key1 < key2
    else
        return tostring(key1) < tostring(key2)
    end
end

local function keysToList(t, keySort)
    local list = {}
    local index = 1
    for key in pairs(t) do
        list[index] = key
        index = index + 1
    end

    keySort = keySort or defaultKeySort

    table.sort(list, keySort)

    return list
end

-- Input a custom keySort function in the second parameter, or use the default one.
-- Creates a new table and closure every time it is called.
local function sortedPairs(t, keySort)
    checks('table','?function')
    local list = keysToList(t, keySort, true)

    local i = 0
    return function()
        i = i + 1
        local key = list[i]
        if key ~= nil then
            return key, t[key]
        else
            return nil, nil
        end
    end
end

-- === Main ============================================================

function help(x)
    checks('?string|function|table')
    if not x then
        print([[help(x): show help for `x` from the global HELP table.
Available topics include, but are not limited to, the following.  For help
on a listed topic, pass it as a string, e.g., help('foo').  You can also
try help(<some function, table, whatever>) and see if anything turns up.]])
        for k,_ in sortedPairs(HELP) do
            if type(k) == 'string' then print('',k) end
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
-- Also attach the help to that global itself.  However, don't do this
-- for global strings, since otherwise we can't tell their values apart
-- from table keys.
function sethelp(x,thehelp, g_too)
    checks('string|function|table','string','?boolean')
    HELP[x] = thehelp
    if g_too and _G[x] and type(_G[x]) ~= 'string' then
        HELP[_G[x]] = thehelp
    end
end

-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
