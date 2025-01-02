return {
    -- Simple session management for Neovim with git branching, autoloading and Telescope support.
    -- SEE: https://github.com/olimorris/persisted.nvim
    'olimorris/persisted.nvim',

    lazy = false,

    config = function()
        local IGNORE_LIST = {
            'codecompanion',
            'neo-tree',
        }

        local plugin = require 'persisted'
        local commands = require 'utils.commands'

        local key = vim.keymap.set

        local cleanup_buf_list = function()
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

        key('n', '<leader>Ss', '<CMD>SessionSelect<CR>', { desc = '[S]elect from [S]essions list.' })
        key('n', '<leader>SS', '<CMD>SessionLoad<CR>', { desc = '[S]ession [S]elect last.' })

        commands.auto('User', {
            pattern = 'PersistedSavePre',
            callback = cleanup_buf_list,
        })

        plugin.setup {
            use_git_branch = true,
        }
    end,
}
