-- cpp-interface.lua - Functions for interfacing with the C++ side

-- Copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
-- mention or link to https://bitbucket.org/inclinescene/public and
-- http://devwrench.com.

require 'Help'

-- Globals
T0 = 0          -- the sim time of the frame after the last relol()

-- Stash a global, since I don't yet know how to access parameters from an
-- unnamed chunk with ... .
function loadGlobal(name, val)
    _G[name] = val
end

--=========================================================================--
-- Per-frame callbacks

-- List of event callbacks.  Each element is a function taking
-- (sim time minus T0, simulation time).
-- Callbacks are not necessarily called in order.
CBK={}

-- Function called once per frame, in the event traversal.
function perFrameEvent(sim_time)
    for _, callback in pairs(CBK) do
        callback(sim_time - T0, sim_time)
    end
end

-- Convenience function to add to CBK.  Returns the index.
function doPerFrame(fn)
    local index = #CBK+1
    CBK[index] = fn
    return index
end
sethelp(doPerFrame,[[
doPerFrame(function([time], [raw_time]) ... end)
  Set up the provided function to be run once per frame, during the event
  traversal, on the FRAME event.  #time is referenced to global T0;
  #raw_time is the simulation time.]])

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
sethelp(doNthFrame,[[
doNthFrame(framenum, function([time], [raw_time]) ... end)
  Set up the provided function to be run on the `framenum`th successive frame,
  during the event traversal, on the FRAME event.  E.g., framenum==1 => run
  on the next frame.  #time is referenced to global T0; #raw_time is the
  simulation time.]])

-- Add to CBK a function that will only run once, on the next frame.
function doNextFrame(fn)
    doNthFrame(1, fn)
end
sethelp(doNextFrame,[[
doNextFrame(function([time], [raw_time]) ... end)
  Set up the provided function to be run on the next frame, during the event
  traversal, on the FRAME event.  #time is referenced to global T0;
  #raw_time is the simulation time.]])

-- vi: set ts=4 sts=4 sw=4 et ai: --
