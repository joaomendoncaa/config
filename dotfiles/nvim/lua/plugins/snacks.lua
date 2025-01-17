return {
    -- 🍿 A collection of small QoL plugins for Neovim.
    -- SEE: https://github.com/folke/snacks.nvim

    'folke/snacks.nvim',

    lazy = false,
    priority = 1000,

    config = function()
        local plugin = require 'snacks'
        local key = require('utils.functions').key
        local f = require('utils.functions').f

        local view_news = function()
            plugin.win {
                file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
                width = 0.6,
                height = 0.6,
                wo = { spell = false, wrap = false, signcolumn = 'yes', statuscolumn = ' ', conceallevel = 3 },
                border = 'rounded',
            }
        end

        key('n', '<leader>nn', plugin.notifier.show_history, 'Notification History')
        key('n', '<leader>nd', plugin.notifier.hide, 'Dismiss All Notifications')
        key('n', '<leader>bd', plugin.bufdelete.delete, 'Delete Buffer')
        key('n', '<leader>cR', plugin.rename.rename_file, 'Rename File')
        key('n', '<leader>gb', plugin.gitbrowse.open, 'Git Browse')
        key('n', '<leader>gB', plugin.git.blame_line, 'Git Blame Line')
        key('n', '<leader>gf', plugin.lazygit.log_file, 'Lazygit Current File History')
        key('n', '<leader>gg', plugin.lazygit.open, 'Lazygit')
        key('n', '<leader>gl', plugin.lazygit.log, 'Lazygit Log (cwd)')
        key('n', ']]', f(plugin.words.jump, vim.v.count1), 'Next Reference')
        key('n', '[[', f(plugin.words.jump, -vim.v.count1), 'Prev Reference')
        key('n', '<leader>N', view_news, 'Neovim News')

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
