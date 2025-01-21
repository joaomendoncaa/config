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

        local key = vim.keymap.set

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

        local function handle_should_save()
            local bufs = vim.api.nvim_list_bufs()
            if #bufs == 1 and bufs[1] == '1' then
                return false
            end
        end

        key('n', '<leader>S', '<CMD>SessionLoad<CR>', { desc = '[S]ession [S]elect last.' })

        commands.user('SessionsList', '<CMD>SessionSelect<CR>')

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
