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
        local f = misc.func
        local key = misc.key

        local cwd_formatter = {}

        local function find_file_up(name, start)
            local dir = start
            for _ = 1, 10 do
                if vim.fn.filereadable(dir .. '/' .. name) == 1 then
                    return true
                end
                local parent = vim.fn.fnamemodify(dir, ':h')
                if parent == dir then
                    break
                end
                dir = parent
            end
            return false
        end

        local prettier_files = { '.prettierrc', '.prettierrc.json', '.prettierrc.js', 'prettier.config.js', 'prettier.config.mjs' }

        local function pick_formatter(cwd)
            if cwd_formatter[cwd] then
                return cwd_formatter[cwd]
            end

            local has_biome = find_file_up('biome.json', cwd)
            local has_prettier = false
            for _, f in ipairs(prettier_files) do
                if find_file_up(f, cwd) then
                    has_prettier = true
                    break
                end
            end

            local choice
            if has_prettier and not has_biome then
                choice = 'prettier'
            else
                choice = 'biome'
            end

            cwd_formatter[cwd] = choice
            return choice
        end

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
            vim.cmd 'Trim'

            local write_without_context = function()
                vim.api.nvim_buf_call(ctx.buf, function()
                    vim.cmd 'noautocmd write!'
                end)
            end

            if has_format_on_save then
                format_async(write_without_context)
            else
                write_without_context()
            end

            git.sync_with_remote { paths = { 'blog.jmmm.sh', 'journal.jmmm.sh', 'rustlings' }, delay = 500 }
        end

        key('n', '<leader>ff', f(format_async), '[F]ormat buffer.')
        key('n', '<leader>fk', f(set_format_on_save, true), '[F]ormat enable.')
        key('n', '<leader>fj', f(set_format_on_save, false), '[F]ormat disable.')

        commands.user('Format', f(format_async))
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
                qml = { 'qmlformat' },
                templ = { 'templ' },
                rust = { 'rustfmt' },
                css = { 'biome', 'prettier' },
                javascript = { 'biome', 'prettier' },
                javascriptreact = { 'biome', 'prettier' },
                typescript = { 'biome', 'prettier' },
                glsl = { 'clang_format' },
                typescriptreact = { 'biome', 'prettier' },
                json = { 'biome', 'prettier' },
                jsonc = { 'biome', 'prettier' },
                svelte = { 'biome', 'prettier' },
                sql = { 'sql_formatter' },
                sh = { 'shfmt' },
                lua = { 'stylua' },
            },
            formatters = {
                qmlformat = {
                    prepend_args = {
                        '-i',
                    },
                },
                rustfmt = {
                    command = 'sh',
                    args = { '-c', 'rustfmt --edition 2024 --emit stdout | dx fmt -f -' },
                    stdin = true,
                },
                stylua = {
                    condition = function()
                        return vim.bo.filetype == 'lua'
                    end,
                },
                biome = {
                    condition = function()
                        return pick_formatter(vim.fn.getcwd()) == 'biome'
                    end,

                    args = function(self, ctx)
                        return { 'check', '--stdin-file-path', ctx.filename, '--write', '--unsafe' }
                    end,
                },
                prettier = {
                    condition = function()
                        return pick_formatter(vim.fn.getcwd()) == 'prettier'
                    end,
                    prepend_args = {
                        '--write',
                    },
                },
            },
        }
    end,
}
