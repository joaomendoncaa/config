return {
    {
        -- Markdown Vim Mode.
        -- SEE: https://github.com/ixru/nvim-markdown
        'ixru/nvim-markdown',

        ft = { 'markdown' },

        config = function() end,
    },

    {
        -- Markdown preview plugin for (neo)vim.
        -- SEE: https://github.com/iamcco/markdown-preview.nvim
        'iamcco/markdown-preview.nvim',

        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },

        build = function()
            vim.fn['mkdp#util#install']()
        end,

        -- Upon initializing the plugin, a temporary CSS file will be created in the
        -- /tmp directory. This file will be hashed from its contents so that it
        -- isn't unnecessarily re-written by subsequent calls to the plugin.
        --
        -- This is because the plugin forces you to use a file instead of inlining
        -- the CSS you want injected.
        --
        -- It also registers a `VimLeavePre` autocommand to clean up the temporary
        -- CSS file when neovim is existed.
        --
        -- SEE: https://github.com/iamcco/markdown-preview.nvim?tab=readme-ov-file#markdownpreview-config
        init = function()
            local crypto = require 'utils.crypto'

            local custom_css = [[
                body {
                    font-family: Arial, sans-serif;
                }

                h1 {
                    color: blue;
                }
            ]]

            local prefix = '/tmp/mkdp-custom_css-'
            local hash = crypto.hashString(custom_css)
            local path = prefix .. hash .. '.css'

            local file = io.open(path, 'r')

            if file then
                file:close()
            else
                file = io.open(path, 'w')

                if not file then
                    error('Failed to create or write to the temporary CSS file: ' .. path)
                end

                file:write(custom_css)
                file:close()
            end

            vim.g.mkdp_markdown_css = path

            vim.api.nvim_create_autocmd('VimLeavePre', {
                desc = 'Cleanup temporary CSS file.',

                group = vim.api.nvim_create_augroup('mkdp-cleanup-css', { clear = true }),

                callback = function(_)
                    os.remove(path)
                end,
            })
        end,

        config = function()
            vim.keymap.set('n', '<leader>p', '<CMD>MarkdownPreviewToggle<CR>', { desc = 'Markdown [P]review.' })
        end,
    },
}
