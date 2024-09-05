return {
    -- Nvim Treesitter configurations and abstraction layer.
    -- SEE: https://github.com/nvim-treesitter/nvim-treesitter
    'nvim-treesitter/nvim-treesitter',

    event = { 'VeryLazy', 'BufEnter' },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
        auto_install = true,
        ensure_installed = {
            'tsx',
            'typescript',
            'go',
            'bash',
            'c',
            'diff',
            'html',
            'lua',
            'luadoc',
            'markdown',
            'markdown_inline',
            'query',
            'vim',
            'vimdoc',
        },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = { 'ruby' },
        },
        indent = { enable = true, disable = { 'ruby' } },
    },

    config = function(_, opts)
        local configs = require 'nvim-treesitter.configs'

        configs.setup(opts)
    end,
}
