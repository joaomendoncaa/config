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

        -- In the case npm is not installed the plugin has an utility to do so.
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
        -- CSS file when neovim is exited.
        --
        -- SEE: https://github.com/iamcco/markdown-preview.nvim?tab=readme-ov-file#markdownpreview-config
        init = function()
            local crypto = require 'utils.crypto'
            local g = vim.g

            local custom_css = [[
                #page-ctn {
                    max-width: unset;
                    min-height: 100vh;

                    display: flex;
                    flex-direction: column
                }

                .markdown-body {
                    flex-grow: 1;
                }

                .markdown-body > * {
                    margin-right: auto!important;
                    margin-left: auto!important;

                    max-width: 800px;
                }
            ]]

            local prefix = '/tmp/mkdp-custom_css-'
            local hash = crypto.hashString(custom_css)
            local path = prefix .. hash .. '.css'

            local custom_css_file = io.open(path, 'r')

            if custom_css_file then
                custom_css_file:close()
            else
                custom_css_file = io.open(path, 'w')
                if not custom_css_file then
                    error('Failed to create or write to the temporary CSS file: ' .. path)
                end

                local mkdp_css_file = io.open(vim.fn.stdpath 'data' .. '/lazy/markdown-preview.nvim/app/_static/markdown.css', 'r')
                if not mkdp_css_file then
                    error 'Failed to open mkdp CSS file'
                end

                custom_css_file:write(mkdp_css_file:read '*a' .. '\n' .. custom_css)

                custom_css_file:close()
                mkdp_css_file:close()
            end

            vim.api.nvim_create_autocmd('VimLeavePre', {
                desc = 'Cleanup temporary CSS file.',

                group = vim.api.nvim_create_augroup('mkdp-cleanup-css', { clear = true }),

                callback = function(_)
                    os.remove(path)
                end,
            })

            g.mkdp_markdown_css = path
            g.mkdp_theme = 'light'
            g.mkdp_auto_close = 0
        end,
    },
}
