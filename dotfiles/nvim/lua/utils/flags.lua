local M = {}

function M.isTrue(ref)
    if ref == true then
        return true
    end

    local str = tostring(ref)
    str = string.lower(str)

    if str == 'true' or str == '1' then
        return true
    end

    return false
end

return M
