return {
    -- 'joaomendoncaa/led.nvim',
    dir = '~/lab/led.nvim/',

    event = 'VeryLazy',

    config = function()
        local plugin = require 'led'

        plugin.setup {
            char = '●',
            ignore = { 'terminal', 'quickfix', 'nofile', 'codecompanion', 'NvimTree', 'noice' },
            gap = 2,
            debug = false,

            leds = {
                {
                    position = 'top-right',
                    highlight = { fg = '#ff0000' },
                    handler = function(winnr, bufnr)
                        local errors = #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
                        if errors == 0 then
                            return nil
                        end
                        return 'E' .. tostring(errors)
                    end,
                },

                {
                    position = 'top-right',
                    highlight = { fg = '#555555' },
                    handler = function(winnr, bufnr)
                        local full_path = vim.api.nvim_buf_get_name(bufnr)
                        if full_path == '' then
                            return nil
                        end

                        local parent_dir = vim.fn.fnamemodify(full_path, ':h:t')
                        local filename = vim.fn.fnamemodify(full_path, ':t')

                        return parent_dir .. '/' .. filename
                    end,
                },
            },
        }
    end,
}
