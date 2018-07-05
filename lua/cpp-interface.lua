-- cpp-interface.lua - Functions for interfacing with the C++ side

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

--=========================================================================--
-- Add ./lua to the package path

if not package.path then
    package.path='./lua/?.lua;;'
else
    local missing_semi = (string.sub(package.path, -1) ~= ';')
    package.path=package.path .. (missing_semi and ';' or '') ..
        './lua/?.lua'
end

--=========================================================================--
-- Globals
T0 = 0          -- the sim time of the frame after the last relol()
ARGV = {}       -- Extra command-line arguments
LOL_RUN = nil   -- Filename to run
CMD_TO_CPLUSPLUS = ''   -- A command the C++ side should run
MUSIC = false   -- whether music is being used as the timebase (-m)
                -- NOTE: this is still true even if the music is done playing.

--=========================================================================--
-- Transferring state to and from C++

require 'Help'

-- Stash a global, since I don't yet know how to access parameters from an
-- unnamed chunk with ... .
function loadGlobal(name, val)
    _G[name] = val
end

-- Stash arguments
function loadArgv(...)
    ARGV = table.pack(...)
end

-- Read a global
function readGlobal(name)
    return _G[name]
end

-- Get the command string and clear it (called by C++)
function cxx_get_cmd()
    local x = CMD_TO_CPLUSPLUS
    CMD_TO_CPLUSPLUS = ''
    return x
end

-- Set the command string to C++ - callable by the user
function cxx_do(cmd)
    CMD_TO_CPLUSPLUS = '' .. cmd
end
sethelp('cxx_do',[[cxx_do(cmd): send string `cmd` to C++]], true)

--=========================================================================--
-- Per-frame callbacks

-- List of event callbacks.  Each element is a function taking
-- (sim time minus T0, simulation time).
-- Callbacks are not necessarily called in order.
CBK={}

-- Function called once per frame, in the event traversal.
-- Array part is traversed in order first.  Other callbacks are traversed
-- after the array part, in no particular order.
function perFrameEvent(sim_time)
    seen={}
    for key, callback in ipairs(CBK) do
        callback(sim_time - T0, sim_time)
        seen[key]=true
    end
    for key, callback in pairs(CBK) do
        if not seen[key] then
            callback(sim_time - T0, sim_time)
        end
    end
end --perFrameEvent()

-- Convenience function to add to CBK.  Returns the index.
function doPerFrame(fn)
    local index = #CBK+1
    CBK[index] = fn
    return index
end
sethelp('doPerFrame',[[
doPerFrame(function([time], [raw_time]) ... end)
  Set up the provided function to be run once per frame, during the event
  traversal, on the FRAME event.  #time is referenced to global T0;
  #raw_time is the simulation time.
  doPerFrame() callbacks are called in the order of calls to doPerFrame.]],
true)

-- Add to CBK a function that will only run once, on the nth succeeding frame.
function doNthFrame(framenum, fn)
    local unique_key = {}

    local inner = function(time, sim_time)
        framenum = framenum-1
        if framenum == 0 then
            CBK[unique_key] = nil
            fn(time, sim_time)
        end
    end

    CBK[unique_key] = inner
end
sethelp('doNthFrame',[[
doNthFrame(framenum, function([time], [raw_time]) ... end)
  Set up the provided function to be run on the `framenum`th successive frame,
  during the event traversal, on the FRAME event.  E.g., framenum==1 => run
  on the next frame.  #time is referenced to global T0; #raw_time is the
  simulation time.
  NOTE: these will run after doPerFrame() callbacks for that frame, but there
  is no relative order guarantee between doNthFrame callbacks.]], true)

-- Add to CBK a function that will only run once, on the next frame.
function doNextFrame(fn)
    doNthFrame(1, fn)
end
sethelp('doNextFrame',[[
doNextFrame(function([time], [raw_time]) ... end)
  Set up the provided function to be run on the next frame, during the event
  traversal, on the FRAME event.  #time is referenced to global T0;
  #raw_time is the simulation time.
  Will run after the doPerFrame() callbacks for the next frame, but in no
  particular order with respect to any other callbacks.]], true)

-- vi: set ts=4 sts=4 sw=4 et ai: --
