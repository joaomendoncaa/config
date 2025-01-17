local M = {}

function M.f(fn, ...)
    local args = { ... }
    return function()
        return fn(unpack(args))
    end
end

function M.key(mode, lhs, rhs, opts)
    local defaults = { silent = true, noremap = true }
    if type(opts) == 'string' then
        defaults.desc = opts
    end
    opts = type(opts) == 'table' and opts or {}
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', defaults, opts))
end

return M
