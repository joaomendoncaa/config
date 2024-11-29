local commands = require 'utils.commands'
local formatters = require 'utils.formatters'
local strings = require 'utils.strings'

local has_format_on_save = true

return {
    -- Lightweight yet powerful formatter plugin for Neovim.
    -- SEE: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',

    event = { 'BufWritePre' },
    cmd = { 'Conform', 'ConformInfo' },
    keys = { '<leader>f' },

    init = function()
        local plugin = require 'conform'

        local keymap = vim.keymap.set

        local function format_disable()
            has_format_on_save = false

            vim.api.nvim_set_hl(0, 'FormatDisabled', { fg = '#ff0000' })

            vim.api.nvim_echo(
                strings.truncateChunks {
                    { '[OFF]', 'FormatDisabled' },
                    { ' ' },
                    { 'Formatting' },
                },
                true,
                {}
            )
        end

        local function format_enable()
            has_format_on_save = true

            vim.api.nvim_set_hl(0, 'FormatEnabled', { fg = '#00ff00' })

            vim.api.nvim_echo(
                strings.truncateChunks {
                    { '[ON]', 'FormatEnabled' },
                    { ' ' },
                    { 'Formatting' },
                },
                true,
                {}
            )
        end

        local function format()
            if not has_format_on_save then
                return
            end

            local opts = { async = false, lsp_format = 'lsp_fallback' }

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

        keymap('n', '<leader>ff', format, { desc = '[F]ormat buffer.' })
        keymap('n', '<leader>fk', format_enable, { desc = '[F]ormat enable.' })
        keymap('n', '<leader>fj', format_disable, { desc = '[F]ormat disable.' })

        commands.user('Format', format)
        commands.user('FormatDisable', format_disable)
        commands.user('FormatEnable', format_enable)

        commands.auto('BufWritePre', { callback = format })

        plugin.setup {
            format_on_save = nil,
            notify_on_error = true,
            formatters_by_ft = {
                yaml = { 'yamlfmt' },
                html = { 'biome', 'prettier' },
                toml = { 'biome' },
                templ = { 'templ' },
                css = { 'biome', 'prettier' },
                javascript = { 'biome', 'prettier' },
                javascriptreact = { 'biome', 'prettier' },
                typescript = { 'biome', 'prettier' },
                typescriptreact = { 'biome', 'prettier' },
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
