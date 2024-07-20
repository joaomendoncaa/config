local M = {}

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
