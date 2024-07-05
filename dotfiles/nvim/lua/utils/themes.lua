local M = {}

local hi = vim.cmd.hi
local cmd = vim.cmd

local sethl = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

function M.adjustConflicts(match)
    local adjustment_schemes = {
        default = function()
            hi 'Title guifg=#8cf8f7'
        end,

        poimandres = function()
            hi 'Comment gui=none'
            hi 'LspReferenceWrite guibg=none'
            hi 'LspReferenceText guibg=none'
            hi 'LspReferenceRead guibg=none'
        end,

        gruvbox = function()
            hi 'SignColumn guibg=none'
        end,

        blue = function()
            hi 'Comment gui=none'
        end,

        ['kanagawa-paper'] = function()
            cmd 'hi clear MsgArea'
        end,
    }

    hi 'StatusLine guibg=none guifg=none'
    hi 'StatusLineNC guibg=none guifg=none'

    hi 'Normal guibg=none ctermbg=none'
    hi 'MsgSeparator guibg=none ctermbg=none'

    hi 'TelescopePreviewNormal guibg=none'
    hi 'TelescopePreviewBorder guibg=none'
    hi 'TelescopeResultsNormal guibg=none'
    hi 'TelescopeResultsBorder guibg=none'
    hi 'TelescopePromptNormal guibg=none'
    hi 'TelescopePromptBorder guibg=none'

    sethl('LazyReasonSource', { fg = '#5de4c7' })
    sethl('LazyReasonFt', { fg = '#5de4c7' })

    sethl('NormalFloat', { bg = 'none' })

    sethl('OverseerPENDING', { fg = '#fffac2' })
    sethl('OverseerRUNNING', { fg = '#5de4c7' })
    sethl('OverseerCANCELED', { fg = '#f087bd' })
    sethl('OverseerSUCCESS', { fg = '#5de4c7' })
    sethl('OverseerFAILURE', { fg = '#f087bd' })
    sethl('OverseerDISPOSED', { fg = '#d0679d' })

    sethl('DiagnosticSignOk', { bg = 'none' })
    sethl('DiagnosticSignHint', { bg = 'none' })
    sethl('DiagnosticSignInfo', { bg = 'none' })
    sethl('DiagnosticSignWarn', { bg = 'none' })
    sethl('DiagnosticSignError', { bg = 'none' })

    if adjustment_schemes[match] then
        adjustment_schemes[match]()
    end
end

function M.update(theme_key)
    vim.cmd.colorscheme(theme_key)
    M.adjustConflicts(theme_key)
end

return M
