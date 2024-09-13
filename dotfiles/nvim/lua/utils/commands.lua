local M = {}

local autocmds = {}

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
    autocmds[event] = { event = event, opts = opts }
end

---@param id string
---@param opts? vim.api.keyset.create_augroup
function M.augroup(id, opts)
    opts = opts or {}
    opts.clear = opts.clear or true
    vim.api.nvim_create_augroup(id, opts)
end

---@param group string
function M.disable(group)
    for _, cmd in pairs(autocmds) do
        if cmd.opts.group == group then
            vim.api.nvim_del_autocmd(autocmds[cmd.event].event)
        end
    end
end

---@param group string
function M.enable(group)
    for _, cmd in pairs(autocmds) do
        if cmd.opts.group == group then
            M.auto(cmd.event, cmd.opts)
        end
    end
end

return M
