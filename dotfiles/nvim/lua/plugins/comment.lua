return {
    -- Smart and powerful comment plugin for neovim. Supports treesitter, dot repeat, left-right/up-down motions, hooks, and more.
    -- SEE: https://github.com/numToStr/Comment.nvim
    'numToStr/Comment.nvim',

    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'JoosepAlviste/nvim-ts-context-commentstring',
    },

    init = function()
        vim.g.skip_ts_context_commentstring_module = true
    end,

    config = function()
        local prehook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()

        require('Comment').setup {
            padding = true,
            sticky = true,
            ignore = '^$',
            toggler = { line = 'gcc', block = 'gbc' },
            opleader = {
                line = 'gc',
                block = 'gb',
            },
            extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
            mappings = { basic = true, extra = true, extended = false },
            pre_hook = prehook,
            post_hook = function() end,
        }
    end,
}
