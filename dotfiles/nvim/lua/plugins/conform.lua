return {
    -- Lightweight yet powerful formatter plugin for Neovim.
    -- SEE: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',

    event = { 'BufWritePre' },
    cmd = { 'Conform', 'ConformInfo' },
    keys = { '<leader>f' },

    init = function()
        local plugin = require 'conform'
        local commands = require 'utils.commands'
        local formatters = require 'utils.formatters'

        local keymap = vim.keymap.set

        local format_buffer = function()
            local opts = { async = false, lsp_fallback = true }

            local formatter = formatters.get_closest {
                biome = { 'biome.json' },
                prettier = {
                    '.prettierrc',
                    '.prettierrc.json',
                    '.prettierrc.yml',
                    '.prettierrc.yaml',
                    '.prettierrc.json5',
                    '.prettierrc.js',
                    '.prettierrc.cjs',
                    '.prettierrc.toml',
                    'prettier.config.js',
                    'prettier.config.cjs',
                },
            }

            if formatter then
                opts.formatters = formatter
            end

            plugin.format(opts)
        end

        keymap('n', '<leader>f', format_buffer, { desc = '[F]ormat buffer.' })

        commands.user('Format', format_buffer)

        commands.auto('BufWritePre', { callback = format_buffer })

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
