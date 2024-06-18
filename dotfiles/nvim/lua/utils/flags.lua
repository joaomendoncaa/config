local M = {}

-- Checks if the given value is 1
--
---@param ref any The value to check.
---@return boolean True if the value is 1, false otherwise.
function M.isOne(ref)
    if tonumber(ref or 0) ~= 1 then
        return false
    end

    return true
end

return M
