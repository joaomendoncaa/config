local TIMER_HOLDSTER = nil
local TIMER_DELAY = 1000

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

        local auto_blog_save = function()
            local cwd = vim.fn.getcwd()

            local handle_on_exit = function(_, code)
                if code ~= 0 then
                    vim.notify('Failed to auto-save blog changes to git', vim.log.levels.ERROR)
                end
            end

            if not string.match(cwd, 'blog.jmmm.sh$') then
                return
            end

            if TIMER_HOLDSTER then
                vim.uv.timer_stop(TIMER_HOLDSTER)
                TIMER_HOLDSTER:close()
            end

            TIMER_HOLDSTER = vim.uv.new_timer()
            TIMER_HOLDSTER:start(
                TIMER_DELAY,
                0,
                vim.schedule_wrap(function()
                    local datetime = os.date '%Y-%m-%d %H:%M:%S'
                    local commit_msg = string.format('sync: %s', datetime)

                    vim.fn.jobstart({
                        'sh',
                        '-c',
                        "git add . && git commit -m '" .. commit_msg .. "' && git push",
                    }, {
                        cwd = cwd,
                        on_exit = handle_on_exit,
                    })

                    TIMER_HOLDSTER:close()
                    TIMER_HOLDSTER = nil
                end)
            )
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

            auto_blog_save()
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
