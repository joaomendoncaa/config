local M = {}

---Computes a hash value for the given string.
---
---@param str string The input string to hash.
---@return number The computed hash value.
function M.hashString(str)
    local hash = 0

    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2 ^ 32
    end

    return hash
end

return M
