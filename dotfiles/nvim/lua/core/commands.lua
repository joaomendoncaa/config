local commands = require 'utils.commands'
local clipboard = require 'utils.clipboard'
local git = require 'utils.git'

local make_rust = function()
    pcall(vim.api.nvim_del_augroup_by_name, 'RustCargoQuickFixHooks')
    vim.bo.makeprg = 'cargo build --release'
end

local toggle_wrap = function()
    vim.cmd 'set wrap!'
end

local buffer_delete = function()
    vim.cmd 'call delete(expand("%")) | bdelete!'
end

local touch_command = function(opts)
    local args = vim.split(opts.args, '%s+')
    local subcommand, path = args[1], args[2]

    if not path then
        vim.notify('Path argument required', vim.log.levels.ERROR)
        return
    end

    local final_path = subcommand == 'relative' and (vim.fn.getcwd() .. '/' .. path) or path

    if not vim.tbl_contains({ 'absolute', 'relative' }, subcommand) then
        vim.notify('Invalid subcommand. Use: Touch absolute|relative <path>', vim.log.levels.ERROR)
        return
    end

    local parent = vim.fn.fnamemodify(final_path, ':h')
    vim.fn.mkdir(parent, 'p')

    local f = io.open(final_path, 'a')
    if f then
        f:close()
    end
end

local touch_complete = function(arglead, cmdline)
    local args = vim.split(cmdline, '%s+')
    if #args == 2 then
        return { 'absolute', 'relative' }
    elseif #args >= 3 then
        return vim.fn.getcompletion(arglead, 'file')
    end
    return {}
end

local buffer_messages = function()
    local result = vim.api.nvim_exec2('messages', { output = true })

    vim.cmd 'new'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result.output, '\n'))
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
end

local auto_highlight_yank = function()
    vim.highlight.on_yank()
end

local auto_keep_unique_sidebar = function()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_ft = string.lower(vim.bo[current_buf].filetype or '')
    local current_win = vim.api.nvim_get_current_win()
    local current_group = nil
    local conflicting_wins = {
        sidebar = {
            'nvimtree',
            'codecompanion',
            'undotree',
        },
    }

    for group, filetypes in pairs(conflicting_wins) do
        if vim.tbl_contains(filetypes, current_ft) then
            current_group = group
            break
        end
    end

    if not current_group then
        return
    end

    local windows = vim.api.nvim_list_wins()
    local width_to_restore = vim.api.nvim_win_get_width(current_win)

    for _, win in ipairs(windows) do
        if win ~= current_win then
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = string.lower(vim.bo[buf].filetype or '')

            if vim.tbl_contains(conflicting_wins[current_group], ft) then
                pcall(vim.api.nvim_win_close, win, false)
                vim.cmd('vertical resize ' .. width_to_restore)
                return
            end
        end
    end
end

commands.user('ToggleWrap', toggle_wrap)

commands.user('BufferDelete', buffer_delete)

commands.user('BufferMessages', buffer_messages)

commands.user('ReplaceContentWithClipboard', clipboard.replace_with_yanked_and_write)

commands.user('Touch', touch_command, { nargs = '+', complete = touch_complete })

commands.auto({ 'TextYankPost' }, {
    callback = auto_highlight_yank,
    group = commands.augroup 'AutoHighlightYank',
})

commands.auto({ 'BufEnter', 'BufWinEnter' }, {
    callback = auto_keep_unique_sidebar,
    group = commands.augroup 'KeepUniqueSidebar',
})

commands.auto({ 'VimLeavePre' }, {
    callback = git.kill_sync_timers,
    group = commands.augroup 'CleanupGitSyncTimers',
})

commands.auto('FileType', {
    pattern = 'rust',
    group = commands.augroup 'RustMake',
    callback = make_rust,
})

local CARGO_EFM = [[%-G,%-Gerror: aborting %.%#,%-Gerror: Could not compile %.%#,%Eerror: %m,%Eerror[E%n]: %m,%Wwarning: %m,%Wwarning[E%n]: %m,%Inote: %m,%C %#--> %f:%l:%c,%C %#╭▸ %f:%l:%c,%E  left:%m,%C right:%m %f:%l:%c,%Z,%f:%l:%c: %t%*[^:]: %m,%f:%l:%c: %*\d:%*\d %t%*[^:]: %m,%-G%f:%l %s,%-G%*[ ]^,%-G%*[ ]^%*[~],%-G%*[ ]...,%-G\s%#Downloading%.%#,%-G\s%#Checking%.%#,%-G\s%#Compiling%.%#,%-G\s%#Finished%.%#,%-G\s%#error: Could not compile %.%#,%-G\s%#To learn more\,%.%#,%-G\s%#For more information about this error\,%.%#,%-Gnote: Run with `RUST_BACKTRACE=%.%#,%.%#panicked at \'%m\'\, %f:%l:%c]]

commands.user('Make', function(opts)
    make_rust()
    local args = opts.args or ''
    local cmd = 'cargo build --release'
    if args ~= '' then
        cmd = cmd .. ' ' .. args
    end
    local output = vim.fn.system(cmd .. ' 2>&1')
    local ok = vim.v.shell_error == 0
    local lines = vim.split(output, '\n')
    if #lines > 0 and lines[#lines] == '' then
        table.remove(lines)
    end
    if #lines == 0 then
        vim.notify('Build successful', vim.log.levels.INFO)
        return
    end
    local tmpfile = vim.fn.tempname()
    vim.fn.writefile(lines, tmpfile)
    local saved_efm = vim.bo.errorformat
    vim.bo.errorformat = CARGO_EFM
    vim.cmd('cfile ' .. tmpfile)
    vim.bo.errorformat = saved_efm
    vim.cmd 'botright copen'
    if not ok then
        vim.notify('Build failed', vim.log.levels.ERROR)
    end
end, { nargs = '*' })
