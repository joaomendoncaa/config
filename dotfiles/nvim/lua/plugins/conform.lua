return {
    -- Lightweight yet powerful formatter plugin for Neovim.
    -- SEE: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',

    event = { 'BufWritePre' },
    cmd = { 'Conform', 'ConformInfo' },

    config = function()
        local plugin = require 'conform'
        local commands = require 'utils.commands'
        local formatters = require 'utils.formatters'

        local keymap = vim.keymap.set

        local format = function()
            local formatter = formatters.get_closest {
                biome = { 'biome.json' },
                prettier = {
                    'prettier.config.js',
                    '.prettierrc',
                    '.prettierrc.json',
                    '.prettierrc.yaml',
                    '.prettierrc.yml',
                },
            }

            if not formatter then
                plugin.format { async = true, lsp_fallback = true }
            else
                plugin.format { async = true, lsp_fallback = false, formatters = formatter }
            end
        end

        keymap('n', '<leader>f', format, { desc = '[F]ormat buffer.' })

        commands.user('Format', format)

        commands.auto({ 'BufWritePre' }, { callback = format })

        plugin.setup {
            notify_on_error = false,
            formatters_by_ft = {
                html = { 'biome', 'prettier' },
                templ = { 'templ' },
                css = { 'biome', 'prettier' },
                javascript = { 'biome', 'prettier' },
                javascriptreact = { 'biome', 'prettier' },
                typescript = { 'biome', 'prettier' },
                typescriptreact = { 'biome', 'prettier' },
                yaml = { 'biome', 'prettier' },
                json = { 'biome', 'prettier' },
                jsonc = { 'biome', 'prettier' },
                svelte = { 'biome', 'prettier' },
                sql = { 'sql_formatter' },
                sh = { 'shfmt' },
                lua = { 'stylua' },
            },
            formatters = {
                biome = {
                    prepend_args = {
                        'check',
                        '--unsafe',
                        '--write',
                    },
                },
                prettier = {
                    prepend_args = {
                        '--write',
                    },
                },
            },
        }
    end,
}
