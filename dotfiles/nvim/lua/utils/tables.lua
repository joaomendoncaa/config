local M = {}

---Check if element is in table.
---
---@param table table The table to check.
---@param element any The element to check.
---@return boolean True if element is in table.
function M.contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

---Filters a table by given keys.
---
---@param table table The table to filter.
---@param keys string[] The keys to filter.
---@return table The filtered table.
function M.filter(table, keys)
    local res = {}

    for _, key in ipairs(keys) do
        local value = table[key]

        if value then
            res[key] = value
        end
    end
    return res
end

return M
