-- print_r(x): Print x in a human-friendly way.
-- Modified from https://github.com/robmiracle/print_r/blob/master/print_r.lua
-- at commit c764743 .
-- Original license unknown; see https://github.com/robmiracle/print_r/issues/1
-- See also https://code.coronalabs.com/code/table-printing-function , which
-- says "This was in the original Corona Community Code exchange by
-- user: OderWat".

-- This version copyright (c) 2017 cxw/Incline.  CC-BY-SA 3.0.  In any
-- derivative work, mention or link to
-- https://bitbucket.org/inclinescene/public and http://devwrench.com.

function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                local tLen = #t
                for i = 1, tLen do
                    local val = t[i]
                    if (type(val)=="table") then
                        print(indent.."#["..i.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(i)+8))
                        print(indent..string.rep(" ",string.len(i)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."#["..i..'] => "'..val..'"')
                    else
                        print(indent.."#["..i.."] => "..tostring(val))
                    end
                end
                for pos,val in pairs(t) do
                    local spos = tostring(pos)
                    if type(pos) ~= "number" or math.floor(pos) ~= pos or (pos < 1 or pos > tLen) then
                        if (type(val)=="table") then
                            print(indent.."["..spos.."] => "..tostring(t).." {")
                            sub_print_r(val,indent..string.rep(" ",string.len(spos)+8))
                            print(indent..string.rep(" ",string.len(spos)+6).."}")
                        elseif (type(val)=="string") then
                            print(indent.."["..spos..'] => "'..val..'"')
                        else
                            print(indent.."["..spos.."] => "..tostring(val))
                        end
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
   end --sub_print_r

   if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end

   print()
end

return print_r
-- vi: set ts=4 sts=4 sw=4 et ai fo=crql: --
