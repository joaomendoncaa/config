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

function M.resize_pane(direction, amount)
    local has_h_split = vim.fn.winnr 'k' ~= vim.fn.winnr() or vim.fn.winnr 'j' ~= vim.fn.winnr()
    local is_nvim = vim.fn.winnr '$' > 1
    local is_vertical = direction == 'up' or direction == 'down'

    local cmds = {
        vim = {
            left = string.format(':vertical resize -%d<CR>', amount),
            right = string.format(':vertical resize +%d<CR>', amount),
            up = string.format(':resize -%d<CR>', amount),
            down = string.format(':resize +%d<CR>', amount),
        },
        tmux = {
            left = string.format('tmux resize-pane -L %d', amount),
            right = string.format('tmux resize-pane -R %d', amount),
            up = string.format('tmux resize-pane -U %d', amount),
            down = string.format('tmux resize-pane -D %d', amount),
        },
    }

    if is_vertical and is_nvim and not has_h_split then
        return nil
    end

    if is_nvim then
        return cmds.vim[direction]
    end

    return vim.fn.system(cmds.tmux[direction])
end

return M
