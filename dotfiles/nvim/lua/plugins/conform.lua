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
        local f = require('utils.functions').f

        local has_format_on_save = true
        local timer_holdster = nil
        local timer_delay = 500

        local keymap = vim.keymap.set

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

        local sync_if_blog = function()
            if not string.match(vim.fn.getcwd(), 'blog.jmmm.sh$') then
                return
            end

            local handle_on_exit = function(_, code)
                if code ~= 0 then
                    vim.notify('Failed to auto-save blog changes to git', vim.log.levels.ERROR)
                end
            end

            local handle_on_start = vim.schedule_wrap(function()
                local commit_msg = string.format('sync: %s', os.date '%Y-%m-%d %H:%M:%S')
                local cmd = {
                    'sh',
                    '-c',
                    "git add . && git commit -m '" .. commit_msg .. "' && git push",
                }

                vim.fn.jobstart(cmd, {
                    cwd = vim.fn.getcwd(),
                    on_exit = handle_on_exit,
                })

                timer_holdster:close()
                timer_holdster = nil
            end)

            if timer_holdster then
                vim.uv.timer_stop(timer_holdster)
                timer_holdster:close()
            end

            timer_holdster = vim.uv.new_timer()
            timer_holdster:start(timer_delay, 0, handle_on_start)
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

            sync_if_blog()
        end

        keymap('n', '<leader>ff', format_async, { desc = '[F]ormat buffer.' })
        keymap('n', '<leader>fk', f(set_format_on_save, true), { desc = '[F]ormat enable.' })
        keymap('n', '<leader>fj', f(set_format_on_save, false), { desc = '[F]ormat disable.' })

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
