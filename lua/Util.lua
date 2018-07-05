-- Util.lua: Utility package.

-- Copyright (c) 2017--2018 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'checks'
require 'Help'
local mathlib = require 'mathlib'

local Util = {}

-- dump(o): Print all fields of `o`.  Thanks to
-- https://stackoverflow.com/a/2620398/2877364 by
-- https://stackoverflow.com/users/32203/frank-schwieterman and
-- https://stackoverflow.com/a/2625911/2877364 by
-- https://stackoverflow.com/users/137317/u0b34a0f6ae
function Util.dump(o)
    print("Members of",o)
    for key,value in pairs(o) do
        print("found member " ,key,type(value),value);
    end

    if getmetatable(o) then
        for key,value in pairs(getmetatable(o)) do
            print("found meta",key, type(value),value)
        end
    end

end --dump()
sethelp(Util.dump,'Print all fields of arg 1')

-- Check if a file is readable
function Util.file_readable(filename)
    local fd = io.open(filename, 'r')
    if fd == nil then
        return false
    else
        io.close(fd)
        return true
    end
end
sethelp(Util.file_readable,[[file_readable(filename): return true if file is
readable, false otherwise]])

-- === Vector-manipulation routines ===

-- Count the whole ("w") number of elements in a table, including both
-- array and hash parts
function Util.getw(tbl)
    checks('table')
    w = 0
    for _ in pairs(tbl) do w = w + 1 end
    return w
end --getw()
sethelp(Util.getw,[[
-- Count the whole ("w") number of elements in a table, including both
-- array and hash parts
function Util.getw(tbl)
]])

-- Regularize a vector to a sequence of n elements, taking into account
-- the special keys supported by LuaScriptEngine::getvec*().
-- Any missing elements are filled in with 1.0.
-- Requirement: 2<=n<=4
function Util.vec2seq(vec, n)
    checks('table','number')

    w = Util.getw(vec)
    --print('w',w,'#vec',#vec,'n',n)

    -- Check if it's a sequence.  Per the manual, #vec is undefined if
    -- vec is not a sequence.  http://www.lua.org/manual/5.2/manual.html#3.4.6
    -- On my Lua 5.2, # stops at the first hole.
    if w == #vec and w == n then return vec end

    -- Build the return value.  Use the special names from getvec*().
    rv={}   -- will be a sequence
    if n==2 then
        rv[1] = vec.x or vec.s or vec.luminance or vec[1] or 1.0
        rv[2] = vec.y or vec.t or vec.alpha or vec[2] or 1.0
    elseif n==3 then
        rv[1] = vec.x or vec.r or vec.red or vec.s or vec[1] or 1.0
        rv[2] = vec.y or vec.g or vec.green or vec.t or vec[2] or 1.0
        rv[3] = vec.z or vec.b or vec.blue or vec.r or vec[3] or 1.0
    elseif n==4 then
        rv[1] = vec.x or vec.r or vec.red or vec.s or vec[1] or 1.0
        rv[2] = vec.y or vec.g or vec.green or vec.t or vec[2] or 1.0
        rv[3] = vec.z or vec.b or vec.blue or vec.r or vec[3] or 1.0
        rv[4] = vec.w or vec.a or vec.alpha or vec.q or vec[4] or 1.0
    else
        error("vec2seq: need 2<=n<=4; got n=" .. n)
    end
    return rv
end --vec2seq()
sethelp(Util.vec2seq,[[Util.vec2seq(vec, n)
Regularize a vector to a sequence of n elements, taking into account
the special keys supported by LuaScriptEngine::getvec*().
Any missing elements are filled in with 1.0.
Requirement: 2<=n<=4
]])

function Util.seq2xyz(vec, n)
    checks('table','number')
    local retval = {}
    if n>0 then retval.x = vec[1] or 0.0 end
    if n>1 then retval.y = vec[2] or 0.0 end
    if n>2 then retval.z = vec[3] or 0.0 end
    if n>3 then retval.w = vec[4] or 0.0 end
    return retval
end
sethelp(Util.seq2xyz, [[Util.seq2xyz(vec, n)
Make a sequence into a table with fields x, y, z, w (up to #n fields).
Missing elements are filled in with 0.0.]])

-- Compute s1+s2
function Util.seqPlusSeq(s1, s2)
    checks('table','table')
    if #s1 ~= #s2 then
        error('s1 and s2 must have the same length')
    end
    local retval = {}
    for idx = 1,#s1 do
        retval[idx] = s1[idx]+s2[idx]
    end
    return retval
end
sethelp(Util.seqPlusSeq,[[Util.seqPlusSeq(s1, s2): s1+s2]])

-- Compute s1-s2
function Util.seqMinusSeq(s1, s2)
    checks('table','table')
    if #s1 ~= #s2 then
        error('s1 and s2 must have the same length')
    end
    local retval = {}
    for idx = 1,#s1 do
        retval[idx] = s1[idx]-s2[idx]
    end
    return retval
end
sethelp(Util.seqMinusSeq,[[Util.seqMinusSeq(s1, s2): s1-s2]])

-- Compute a normal from three vertices, specified counter-clockwise
function Util.normal(v1, v2, v3)
    -- Get the normal
    local side = Util.seqMinusSeq(v2,v1)
    local diag = Util.seqMinusSeq(v3,v1)
    local normal =  mathlib.crossProduct(
                        Util.seq2xyz(side,3), Util.seq2xyz(diag, 3)
                    );
    mathlib.normalize3(normal)
    normal = Util.vec2seq(normal, 3)
    return normal
end
sethelp(Util.normal,[[Util.normal(v1, v2, v3): get normal of vertices.
Vertices are specified in counterclockwise order.
Inputs are sequences (123, not xyz)]])

return Util;

-- vi: set ts=4 sts=4 sw=4 et ai: --
