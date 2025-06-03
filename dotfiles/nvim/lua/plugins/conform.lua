return {
    'stevearc/conform.nvim',

    lazy = true,
    event = { 'VeryLazy' },
    cmd = { 'Conform', 'ConformInfo' },
    keys = { '<leader>f' },

    init = function()
        local commands = require 'utils.commands'
        local strings = require 'utils.strings'
        local plugin = require 'conform'
        local git = require 'utils.git'
        local misc = require 'utils.misc'
        local f = misc.f
        local key = misc.key

        local has_format_on_save = true

        local function set_format_on_save(value, opts)
            opts = opts or {
                silent = false,
            }

            has_format_on_save = value

            if not opts.silent then
                local hl = value and '#00ff00' or '#ff0000'
                local text = value and '[ON]' or '[OFF]'

                vim.api.nvim_set_hl(0, 'HL', { fg = hl })
                strings.echo(strings.truncateChunks {
                    { text, 'HL' },
                    { ' ' },
                    { 'Formatting' },
                })
            end
        end

        local function format_async(cb)
            plugin.format({ async = true }, cb or nil)
        end

        local function handle_buf_write(ctx)
            local write_without_context = function()
                vim.api.nvim_buf_call(ctx.buf, f(vim.cmd, 'noautocmd write!'))
            end

            if has_format_on_save then
                format_async(write_without_context)
            else
                write_without_context()
            end

            git.sync_with_remote { paths = 'blog.jmmm.sh', delay = 500 }
        end

        key('n', '<leader>ff', format_async, '[F]ormat buffer.')
        key('n', '<leader>fk', f(set_format_on_save, true), '[F]ormat enable.')
        key('n', '<leader>fj', f(set_format_on_save, false), '[F]ormat disable.')

        commands.user('Format', format_async)
        commands.user('FormatDisable', f(set_format_on_save, false))
        commands.user('FormatEnable', f(set_format_on_save, true))

        commands.auto('BufWriteCmd', { callback = handle_buf_write })

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
                stylua = {
                    condition = function()
                        return vim.bo.filetype == 'lua'
                    end,
                },
                biome = {
                    condition = function()
                        return vim.fn.filereadable(vim.fn.getcwd() .. '/biome.json') == 1
                    end,

                    prepend_args = {
                        'check',
                        '--unsafe',
                        '--write',
                    },
                },
                prettier = {
                    condition = function()
                        return vim.fn.filereadable(vim.fn.getcwd() .. '/biome.json') == 0
                    end,
                    prepend_args = {
                        '--write',
                    },
                },
            },
        }
    end,
}
