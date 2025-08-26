return {
    'folke/snacks.nvim',

    event = 'VeryLazy',

    init = function()
        local plugin = require 'snacks'
        local misc = require 'utils.misc'

        local f = misc.func
        local key = misc.key

        local view_news = function()
            plugin.win {
                file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
                width = 0.6,
                height = 0.6,
                wo = { spell = false, wrap = false, signcolumn = 'yes', statuscolumn = ' ', conceallevel = 3 },
                border = 'rounded',
            }
        end

        plugin.toggle.profiler():map '<leader>pp'
        plugin.toggle.profiler_highlights():map '<leader>ph'

        key('n', '<leader>.', f(plugin.scratch), '[S]cratch')
        key('n', '<leader>ps', f(plugin.profiler.scratch), '[S]cratch')
        key('n', '<leader>nn', plugin.notifier.show_history, 'Notification History')
        key('n', '<leader>nd', plugin.notifier.hide, 'Dismiss All Notifications')
        key('n', '<leader>bd', plugin.bufdelete.delete, 'Delete Buffer')
        key('n', '<leader>cR', plugin.rename.rename_file, 'Rename File')
        key('n', '<leader>gb', plugin.gitbrowse.open, 'Git Browse')
        key('n', '<leader>gB', plugin.git.blame_line, 'Git Blame Line')
        key('n', '<leader>gf', plugin.lazygit.log_file, 'Lazygit Current File History')
        key('n', '<leader>gg', plugin.lazygit.open, 'Lazygit')
        key('n', '<leader>gl', plugin.lazygit.log, 'Lazygit Log (cwd)')
        key('n', '<leader>rf', plugin.rename.rename_file, '[R]ename [F]ile')
        key('n', ']]', f(plugin.words.jump, vim.v.count1), 'Next Reference')
        key('n', '[[', f(plugin.words.jump, -vim.v.count1), 'Prev Reference')
        key('n', '<leader>N', view_news, 'Neovim News')
    end,

    config = function(_, opts)
        local plugin = require 'snacks'

        plugin.setup(vim.tbl_extend('force', opts, {
            notifier = {
                enabled = true,
                timeout = 1500,
                style = 'fancy',
            },
            input = {
                enabled = false,
                icon = '',
                prompt_pos = 'title',
            },
            styles = {
                notification = {
                    wo = { wrap = true },
                },
                input = {
                    title_pos = 'left',
                    row = 10,
                },
            },
        }))
    end,
}
