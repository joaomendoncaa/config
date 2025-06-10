local M = {}

function M.func(fn, ...)
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

function M.handle_save_quit()
    local wl_nowrite = { 'codecompanion', 'nvimtree', 'qf' }

    local buf = vim.api.nvim_get_current_buf()
    local ft = string.lower(vim.bo[buf].filetype or '')
    local bufname = vim.api.nvim_buf_get_name(buf)
    local is_unnamed = bufname == '' and vim.bo[buf].modified
    local is_nowrite = vim.tbl_contains(wl_nowrite, ft)

    if is_nowrite then
        return vim.cmd 'q'
    end

    if is_unnamed then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local is_empty = #lines == 0 or (#lines == 1 and lines[1] == '')

        if is_empty then
            vim.bo[buf].modified = false
            return vim.cmd 'q'
        end
    end

    vim.cmd 'wq'
end

return M
