local themes = {}

function themes.adjustConflicts(match)
    local adjustment_schemes = {
        default = function()
            vim.cmd.hi 'Title guifg=#8cf8f7'
        end,

        poimandres = function()
            vim.cmd.hi 'Comment gui=none'
            vim.cmd.hi 'LspReferenceWrite guibg=none'
            vim.cmd.hi 'LspReferenceText guibg=none'
            vim.cmd.hi 'LspReferenceRead guibg=none'
        end,

        gruvbox = function()
            vim.cmd.hi 'SignColumn guibg=none'
        end,

        blue = function()
            vim.cmd.hi 'Comment gui=none'
        end,
    }

    vim.cmd.hi 'Normal guibg=none ctermbg=none'

    vim.api.nvim_set_hl(0, 'LazyReasonSource', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'LazyReasonFt', { fg = '#5de4c7' })

    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

    vim.api.nvim_set_hl(0, 'OverseerPENDING', { fg = '#fffac2' })
    vim.api.nvim_set_hl(0, 'OverseerRUNNING', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'OverseerCANCELED', { fg = '#f087bd' })
    vim.api.nvim_set_hl(0, 'OverseerSUCCESS', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'OverseerFAILURE', { fg = '#f087bd' })
    vim.api.nvim_set_hl(0, 'OverseerDISPOSED', { fg = '#d0679d' })

    vim.api.nvim_set_hl(0, 'DiagnosticSignOk', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignError', { bg = 'none' })

    if adjustment_schemes[match] then
        adjustment_schemes[match]()
    end
end

return themes
