local M = {}

---@param name string
---@param command any
---@param opts? vim.api.keyset.user_command
function M.user(name, command, opts)
    opts = opts or {}
    vim.api.nvim_create_user_command(name, command, opts)
end

---@param event any
---@param opts? vim.api.keyset.create_autocmd
function M.auto(event, opts)
    opts = opts or {}
    vim.api.nvim_create_autocmd(event, opts)
end

---@param id string
---@param opts? vim.api.keyset.create_augroup
function M.augroup(id, opts)
    opts = opts or {}
    opts.clear = opts.clear or true
    vim.api.nvim_create_augroup(id, opts)
end

return M
