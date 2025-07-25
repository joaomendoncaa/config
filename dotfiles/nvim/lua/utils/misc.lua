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

function M.arrange_ordered_list()
    local row = vim.api.nvim_win_get_cursor(0)[1]

    local start_line = row
    while start_line > 1 and vim.fn.getline(start_line - 1) ~= '' do
        start_line = start_line - 1
    end

    local last_line = vim.api.nvim_buf_line_count(0)
    local end_line = row
    while end_line < last_line and vim.fn.getline(end_line + 1) ~= '' do
        end_line = end_line + 1
    end

    local count = 0
    for lnum = start_line, end_line do
        local line = vim.fn.getline(lnum)
        local replaced = line:gsub('^(%d+)', function()
            count = count + 1
            return tostring(count)
        end)
        if replaced ~= line then
            vim.fn.setline(lnum, replaced)
        end
    end
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
    local is_nowrite = vim.tbl_contains(wl_nowrite, ft)
    local is_readonly = vim.bo[buf].readonly

    if is_nowrite or is_readonly then
        return vim.cmd 'q'
    end

    if vim.bo.modified then
        return vim.notify 'Buffer modified, save it first.'
    end

    local bufname = vim.api.nvim_buf_get_name(buf) or ''
    local is_unnamed = bufname == ''
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false) or 0
    local is_empty = #lines == 0 or (#lines == 1 and lines[1] == '')

    if is_unnamed and is_empty then
        vim.bo[buf].modified = false
        return vim.cmd 'q!'
    end

    vim.cmd 'q'
end

return M
