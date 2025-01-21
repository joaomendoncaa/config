return {
    -- Simple session management for Neovim with git branching, autoloading and Telescope support.
    -- SEE: https://github.com/olimorris/persisted.nvim
    'olimorris/persisted.nvim',

    lazy = false,

    config = function()
        local IGNORE_LIST = {
            'codecompanion',
            'neo-tree',
            'help',
            'nofile',
            'qf',
        }

        local plugin = require 'persisted'
        local commands = require 'utils.commands'
        local key = require('utils.functions').key

        local handle_persisted_save_pre = function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local curr = vim.bo[buf].filetype
                for _, ft in ipairs(IGNORE_LIST) do
                    if curr == ft then
                        vim.api.nvim_buf_delete(buf, { force = true })
                        break
                    end
                end
            end
        end

        local handle_should_save = function()
            local bufs = vim.api.nvim_list_bufs()

            if #bufs == 1 then
                local bufnr = bufs[1]
                local name = vim.api.nvim_buf_get_name(bufnr)

                return name ~= ''
            end

            return true
        end

        key('n', '<leader>S', '<CMD>SessionLoad<CR>', '[S]ession [S]elect last.')

        commands.user('SessionsList', plugin.select)

        commands.auto('User', {
            pattern = 'PersistedSavePre',
            callback = handle_persisted_save_pre,
        })

        plugin.setup {
            use_git_branch = true,
            should_save = handle_should_save,
        }
    end,
}
