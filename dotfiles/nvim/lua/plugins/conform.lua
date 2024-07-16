return {
    -- Lightweight yet powerful formatter plugin for Neovim.
    -- SEE: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',

    event = { 'BufWritePre' },
    cmd = { 'Conform', 'ConformInfo' },

    config = function()
        local plugin = require 'conform'

        local format_buffer = function()
            plugin.format { async = true, lsp_fallback = true }
        end

        plugin.setup {
            notify_on_error = false,
            format_on_save = function(bufnr)
                local disabled_filetypes = { c = true, cpp = true }

                return {
                    timeout_ms = 100,
                    lsp_fallback = not disabled_filetypes[vim.bo[bufnr].filetype],
                }
            end,
            formatters_by_ft = {
                typescriptreact = { 'biome' },
                javascriptreact = { 'biome' },
                javascript = { 'biome' },
                typescript = { 'biome' },
                css = { 'biome' },
                scss = { 'biome' },
                json = { 'biome' },

                lua = { 'stylua' },
                sh = { 'shfmt' },
            },
            formatters = {
                biome = {
                    prepend_args = {
                        'check',
                        '--unsafe',
                        '--write',
                    },
                },
            },
        }

        local keymap = vim.keymap.set

        keymap('n', '<leader>f', format_buffer, { desc = '[F]ormat buffer.' })
    end,
}
