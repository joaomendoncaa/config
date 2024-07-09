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

        local formatter_biome = function()
            local buffer_path = vim.api.nvim_buf_get_name(0)
            local cwd = vim.fn.getcwd()
            local has_biome_json = vim.fn.filereadable(cwd .. '/biome.json')

            if has_biome_json then
                return {
                    inherit = false,
                    command = 'biome',
                    args = { 'format', '--write', buffer_path },
                }
            end

            return 'prettier'
        end

        plugin.setup {
            notify_on_error = false,
            format_on_save = function(bufnr)
                local disabled_filetypes = { c = true, cpp = true }

                return {
                    timeout_ms = 500,
                    lsp_fallback = not disabled_filetypes[vim.bo[bufnr].filetype],
                }
            end,
            formatters_by_ft = {
                ['*'] = { 'prettier' },
                lua = { 'stylua' },
                sh = { 'shfmt' },
            },
            formatters = {
                typescriptreact = formatter_biome,
                javascriptreact = formatter_biome,
                javascript = formatter_biome,
                typescript = formatter_biome,
                css = formatter_biome,
                scss = formatter_biome,
                json = formatter_biome,
            },
        }

        local keymap = vim.keymap.set

        keymap('n', '<leader>f', format_buffer, { desc = '[F]ormat buffer.' })
    end,
}
