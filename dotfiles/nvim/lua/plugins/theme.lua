return {
    -- Poimandres colorscheme for Neovim written in Lua.
    -- SEE: https://github.com/olivercederborg/poimandres.nvim
    'olivercederborg/poimandres.nvim',

    priority = 1000,

    config = function()
        local poimandres = require 'poimandres'
        local themes = require 'utils.themes'
        local cmd = vim.cmd

        poimandres.setup {
            dim_nc_background = true,
            disable_background = true,
            disable_float_background = true,
        }

        cmd.colorscheme 'poimandres'
        themes.adjustConflicts 'poimandres'

        vim.api.nvim_create_autocmd('ColorScheme', {
            desc = 'Make necessary adjustments to the selected colorscheme.',
            group = vim.api.nvim_create_augroup('color-scheme-background-removal', { clear = true }),
            callback = function(args)
                themes.adjustConflicts(args.match)

                vim.cmd 'hi Normal guibg=none ctermbg=none'

                vim.api.nvim_set_hl(0, 'LazyReasonSource', { fg = '#5de4c7' })
                vim.api.nvim_set_hl(0, 'LazyReasonFt', { fg = '#5de4c7' })

                vim.api.nvim_set_hl(0, 'OverseerPENDING', { fg = '#fffac2' })
                vim.api.nvim_set_hl(0, 'OverseerRUNNING', { fg = '#5de4c7' })
                vim.api.nvim_set_hl(0, 'OverseerCANCELED', { fg = '#f087bd' })
                vim.api.nvim_set_hl(0, 'OverseerSUCCESS', { fg = '#5de4c7' })
                vim.api.nvim_set_hl(0, 'OverseerFAILURE', { fg = '#f087bd' })
                vim.api.nvim_set_hl(0, 'OverseerDISPOSED', { fg = '#d0679d' })
            end,
        })
    end,
}
