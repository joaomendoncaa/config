return {
    'nvim-tree/nvim-tree.lua',

    event = 'VeryLazy',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
    },

    config = function()
        local commands = require 'utils.commands'
        local plugin = require 'nvim-tree'
        local api = require 'nvim-tree.api'
        local key = require('utils.functions').key

        local auto_focus_on_buf_enter = function()
            if not api.tree.is_visible() then
                return
            end

            local path = vim.fn.expand '%:p'
            if path == '' or vim.fn.filereadable(path) == 0 then
                return
            end

            api.tree.find_file(path)
        end

        local auto_exit_if_last_buffer = function()
            local current_ft = vim.bo.filetype
            if current_ft ~= 'NvimTree' then
                return
            end

            local wins = 0
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[buf].filetype
                local listed = vim.bo[buf].buflisted
                if listed and ft ~= 'NvimTree' then
                    wins = wins + 1
                end
            end

            if wins == 0 then
                vim.cmd 'quit'
            end
        end

        local handle_toggle = function()
            if api.tree.is_visible() then
                api.tree.close()
                return
            end

            local path = vim.fn.expand '%:p'
            if path == '' or vim.fn.filereadable(path) == 0 then
                vim.notify('No valid file under cursor', vim.log.levels.WARN)
                return
            end

            api.tree.open()
            api.tree.find_file(path)
            api.tree.focus()
        end

        local handle_attach = function(bufnr)
            api.config.mappings.default_on_attach(bufnr)

            key('n', 'h', api.node.navigate.parent_close, { buffer = bufnr, desc = 'Close directory' })
            key('n', 'l', api.node.open.edit, { buffer = bufnr, desc = 'Open file/directory' })
            key('n', 'q', api.tree.close, { buffer = bufnr, desc = 'Close tree' })
            key('n', '<leader>v', api.node.open.vertical, { buffer = bufnr, desc = 'Open split vertical' })
            key('n', '<leader>h', api.node.open.horizontal, { buffer = bufnr, desc = 'Open split horizontal' })
        end

        key('n', '<leader>ee', handle_toggle, 'Toggle [E]xplorer')

        api.events.subscribe(api.events.Event.FileCreated, function(file)
            vim.cmd('edit ' .. vim.fn.fnameescape(file.fname))
        end)

        commands.auto('BufEnter', {
            callback = auto_focus_on_buf_enter,
            group = commands.augroup 'NvimTreeAutoFocusOnBufEnter',
        })

        commands.auto('BufEnter', {
            callback = auto_exit_if_last_buffer,
            group = commands.augroup 'NvimTreeAutoExitIfLastBuffer',
        })

        plugin.setup {
            view = {
                side = 'right',
                width = 35,
            },
            on_attach = handle_attach,
            live_filter = {
                always_show_folders = false,
            },
        }
    end,
}
