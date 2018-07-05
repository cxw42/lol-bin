-- Sync.lua: sync routines, inspired by Rocket
-- Copyright (c) 2018 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.
-- See end of file for input format

local pldata = require 'pl.data'
local print_r = require 'print_r'

require 'Help'

-- === Helpers ==============================================================
local function idiv(a,b)  -- integer division
    return (a - a % b) / b
end

local Sync = {}

-- === Class members, and constructor =======================================

-- Interpolation constants
Sync.STEP = '|'     -- like a brick wall
Sync.LINEAR = 'L'
Sync.SMOOTH = 'S'
Sync.RAMP = 'R'

-- Call as Sync:new(CSV filename[, model])
function Sync.new(cls, csv_filename, node)
    checks('table','string', 'table|nil')

    -- Create the instance ----------------------
    obj = {nchannels=0, channels={}, uniforms={}}
    setmetatable(obj, cls)
    cls.__index=cls     -- where Lua will look up methods called on obj

    -- Load the data ----------------------------
    local data = assert(pldata.read(csv_filename,
                                        {csv = true, no_convert = true}))

    -- parse the data and build the ArrayLists
    obj.nchannels = idiv(#data.fieldnames-3,3)
        -- There are three non-channel fields (comment, time, extra),
        -- and each channel has three fields (out, in, type)

    for chanidx=1, obj.nchannels do
        -- For each channel, pull the subset of rows that has an
        -- outgoing time.
        local chan = {times={}, knots={}, uniform_name=''}
        obj.channels[chanidx] = chan
        local knotidx = 1   -- next knot to use

        for rowidx=1, #data do
            local row = data[rowidx]
            -- row[1] is comment
            local time = tonumber(row[2])

            local colidx = (chanidx-1)*3 + 3
            local o = tonumber(row[colidx])
            local i = tonumber(row[colidx+1]) or o

            -- Interpolation type
            local ty = row[colidx+2]
            if (not ty) or (ty==0) or (ty=="") then ty = Sync.STEP end
            ty = string.upper(ty)

            if o then   -- o is either a number or nil
                chan.times[knotidx] = time
                chan.knots[knotidx] = {o=o, i=i, t=ty}
                knotidx = knotidx+1
            end
        end --rowidx

    end --chanidx

    -- Setup uniforms ---------------------------
    for chanidx=1, obj.nchannels do
        local colidx = (chanidx-1)*3 + 3    -- Outgoing column
        local uniform_name = string.match(data.original_fieldnames[colidx],
                                                            "#([%a_][%w_]*)")
        if uniform_name then
            obj.uniforms[uniform_name] = {chanidx=chanidx}
            obj.channels[chanidx].uniform_name = uniform_name
        end
    end --chanidx

    if node then    -- Create the osg::Uniform instances
        local ss = assert(node:getOrCreateStateSet(), 'given node has no state set')
        for uniform_name, u in pairs(obj.uniforms) do
            local uniform = Geometry.makeUniform(uniform_name,'FLOAT')
            ss:add(uniform)
            u.uniform = uniform
        end
    end

    --print_r(obj)
    return obj
end --Sync.new
sethelp(Sync.new,[[
Sync:new(filename[, node]): Create a new Sync instance.
    filename (string): csv filename to load
    node (optional object): OpenScenGraph node to attach uniforms to.
                            If not specified, no uniforms will be attached.]])

-- === Runtime internals ====================================================

-- Find the value of sorted array #arr that is less than or equal to #needle.
local function find_knot(arr, needle)
    local lo = 1
    local hi = #arr

    while lo <= hi do
        local mid = lo + idiv(hi-lo, 2)
        if needle == arr[mid] then
            return mid
        elseif needle < arr[mid] then
            hi = mid-1
        else
            lo = mid+1
        end
    end

    -- Now the likely case --- we didn't exactly hit a knot, so return
    -- the knot just below it.  That is `hi` because, to exit the loop,
    -- hi < lo, so `hi` is the one at the lower end of the range
    -- that brackets `needle`.  (Right?  Not formally analyzed ;) )
    return hi
end --find_knot()

-- Given a Sync channel in #chan, return:
--  the knot before (or at) #time,
--  the next knot that has a time, and
--  the percentage of the way between those knots (0..1)
local function knot_pct(chan, time)
    if time < chan.times[1] then
        return 1, 0
    elseif time >= chan.times[#chan.times] then
        return #chan.times-1, 1   -- All the way at the end
    else
        local knot = find_knot(chan.times, time)
        return knot, (time - chan.times[knot]) / (chan.times[knot+1] - chan.times[knot])
    end
end --knot_pct()

-- === Runtime member functions =============================================

function Sync:getchan(chanidx, time)
    local chan = self.channels[chanidx]
    local knot, pct = knot_pct(chan, time)
    local o = chan.knots[knot]    --outgoing
    local i = chan.knots[knot+1]  --incoming
    if o.t == Sync.STEP then
        return o.o

    elseif o.t == Sync.LINEAR then
        return o.o + (i.i - o.o) * pct

    elseif o.t == Sync.SMOOTH then
        pct = pct * pct * (3 - 2*pct)
        return o.o + (i.i - o.o) * pct

    elseif o.t == Sync.RAMP then
        pct = math.pow(pct, 2.0)
        return o.o + (i.i - o.o) * pct
    end

    error('Invalid interpolation type ' .. o.t)
end -- Sync:getchan
sethelp(Sync.getchan,[[
s:getchan(chanidx, time): Get a channel's value at a particular time.]])

function Sync:get(time)
    local retval = {}
    for chanidx = 1, self.nchannels do
        retval[chanidx] = self:getchan(chanidx, time)
    end
    return retval
end --Sync:get
sethelp(Sync.get,[[Get all the channels at a particular time.
After `s = Sync:new(...)`, `s:get(t)` will return a table of the values for
all the channels at that time.]])

function Sync:get_and_set_uniforms(time)
    local retval = self:get(time)
    for uniform_name, u in pairs(obj.uniforms) do
        --print(string.format('Setting %s %d to %f',
        --      uniform_name, u.chanidx, retval[u.chanidx]))
        u.uniform:value(retval[u.chanidx])
    end
    return retval
end --Sync:get_and_set_uniforms
sethelp(Sync.get_and_set_uniforms,[[
Get all the channels at a particular time, and set the values of any
uniforms.  Parameters and returns are the same as Sync:get().]])

-- === Class documentation ==================================================

sethelp('Sync',[[
The Sync class provides Rocket-style sync based on a CSV file.  The
input format is:
                     ---- channel 1 -------------------  ...
col. 1    2          3             4             5            #
Comment   Time (s)   outgoing val  incoming val  interp. ...  spare column

There are three columns per channel, so "#" is 3+(3 * num. of channels).

"interp." is empty for set, L for linear ramp, S for smooth, R for
quadratic ramp.

Uniform names:
If the "outgoing val" column for a channel has `#` followed immediately by
an identifier, that channel will be available with the uniform named after
that identifier.  E.g., `#some_uniform_name_1` will make uniform
`some_uniform_name_1`
]])
return Sync

-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
