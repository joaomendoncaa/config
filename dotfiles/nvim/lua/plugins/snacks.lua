return {
    -- 🍿 A collection of small QoL plugins for Neovim.
    -- SEE: https://github.com/folke/lazy.nvim

    'folke/snacks.nvim',

    lazy = false,
    priority = 1000,

    config = function()
        local plugin = require 'snacks'
        local key = vim.keymap.set

        key('n', '<leader>n', function()
            plugin.notifier.show_history()
        end, { desc = 'Notification History' })
        key('n', '<leader>bd', function()
            plugin.bufdelete()
        end, { desc = 'Delete Buffer' })
        key('n', '<leader>cR', function()
            plugin.rename.rename_file()
        end, { desc = 'Rename File' })
        key('n', '<leader>gb', function()
            plugin.gitbrowse()
        end, { desc = 'Git Browse' })
        key('n', '<leader>gB', function()
            plugin.git.blame_line()
        end, { desc = 'Git Blame Line' })
        key('n', '<leader>gf', function()
            plugin.lazygit.log_file()
        end, { desc = 'Lazygit Current File History' })
        key('n', '<leader>gg', function()
            plugin.lazygit()
        end, { desc = 'Lazygit' })
        key('n', '<leader>gl', function()
            plugin.lazygit.log()
        end, { desc = 'Lazygit Log (cwd)' })
        key('n', '<leader>un', function()
            plugin.notifier.hide()
        end, { desc = 'Dismiss All Notifications' })
        key('n', '<c-/>', function()
            plugin.terminal()
        end, { desc = 'Toggle Terminal' })
        key('n', ']]', function()
            plugin.words.jump(vim.v.count1)
        end, { desc = 'Next Reference' })
        key('n', '[[', function()
            plugin.words.jump(-vim.v.count1)
        end, { desc = 'Prev Reference' })
        key('t', '<c-/>', '<cmd>lua require("snacks").terminal()<CR>', { desc = 'Toggle Terminal' })
        key(
            'n',
            '<leader>N',
            ':lua require("snacks").win { file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1], width = 0.6, height = 0.6, wo = { spell = false, wrap = false, signcolumn = "yes", statuscolumn = " ", conceallevel = 3 }, }<CR>',
            { desc = 'Neovim News' }
        )

        plugin.setup {
            notifier = {
                enabled = true,
                timeout = 2500,
            },
            styles = {
                notification = {
                    wo = { wrap = true },
                },
            },
        }
    end,
}
