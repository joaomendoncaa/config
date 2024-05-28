return {
    -- Lightweight yet powerful formatter plugin for Neovim.
    -- SEE: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',

    event = 'VeryLazy',

    config = function()
        require('conform').setup {
            notify_on_error = false,
            format_on_save = function(bufnr)
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = { c = true, cpp = true }
                return {
                    timeout_ms = 500,
                    lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                }
            end,
            formatters_by_ft = {
                lua = { 'stylua' },
                sh = { 'shfmt' },
                javascript = { 'prettier' },
                jsx = { 'prettier' },
                typescript = { 'prettier' },
                tsx = { 'prettier' },
                html = { 'prettier' },
            },
        }

        vim.keymap.set('n', '<leader>f', function()
            require('conform').format { async = true, lsp_fallback = true }
        end, { desc = '[F]ormat buffer' })
    end,
}
