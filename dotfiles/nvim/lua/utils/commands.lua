local M = {}

function M.new(name, command, opts)
    opts = opts or {}
    vim.api.nvim_create_user_command(name, command, opts)
end

function M.auto(event, opts)
    opts = opts or {}
    vim.api.nvim_create_autocmd(event, opts)
end

function M.augroup(id, opts)
    opts = opts or {}
    opts.clear = opts.clear or true
    vim.api.nvim_create_augroup(id, opts)
end

return M
