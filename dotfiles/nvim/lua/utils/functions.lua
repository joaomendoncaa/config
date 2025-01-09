local M = {}

--- Creates a function that calls fn with the provided arguments when invoked
--- Useful for getting a reference to a function with pre-bound arguments
---
--- @param fn function The function to be called
--- @param ... any Arguments to pass to fn when invoked
--- @return function New function that will call fn with the bound arguments
function M.a(fn, ...)
    local args = { ... }
    return function()
        return fn(unpack(args))
    end
end

return M
