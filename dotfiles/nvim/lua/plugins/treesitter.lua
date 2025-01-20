return {
    -- Nvim Treesitter configurations and abstraction layer.
    -- SEE: https://github.com/nvim-treesitter/nvim-treesitter
    'nvim-treesitter/nvim-treesitter',

    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSInstall', 'TSBufEnable', 'TSBufDisable', 'TSModuleInfo' },
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
        textobjects = {
            select = {
                enable = false,
                keymaps = {
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ['ic'] = '@class.inner',
                },
            },
        },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = { 'ruby' },

            disable = function(_, buf)
                local max_filesize = 50 * 1024

                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    return true
                end
            end,
        },
        indent = { enable = true, disable = { 'ruby' } },
    },
}
