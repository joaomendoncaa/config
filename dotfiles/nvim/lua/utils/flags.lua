local flags = {}

function flags.isOne(ref)
    if tonumber(ref or 0) ~= 1 then
        return false
    end

    return true
end

return flags
