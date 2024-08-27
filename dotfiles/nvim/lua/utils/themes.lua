local M = {}

local tables = require 'utils.tables'

---Map of adjustments for each theme.
---NOTE: there's an _all key that represents adjustments for all themes
local ADJUSTMENTS = {
    ['default'] = function()
        vim.cmd.hi 'Title guifg=#8cf8f7'
    end,

    ['poimandres'] = function()
        vim.cmd.hi 'Comment gui=none'

        vim.cmd.hi 'Title guifg=#5de4c7'

        vim.api.nvim_set_hl(0, 'LspReferenceWrite', { bg = 'none' })
        vim.api.nvim_set_hl(0, 'LspReferenceText', { bg = 'none' })
        vim.api.nvim_set_hl(0, 'LspReferenceRead', { bg = 'none' })

        vim.api.nvim_set_hl(0, 'TelescopeResultsBorder', { fg = '#303340' })
        vim.api.nvim_set_hl(0, 'TelescopePreviewBorder', { fg = '#303340' })
    end,

    ['gruvbox'] = function()
        vim.cmd.hi 'SignColumn guibg=none'
    end,

    ['blue'] = function()
        vim.cmd.hi 'Comment gui=none'
    end,

    ['flow'] = function()
        vim.cmd 'hi clear MsgArea'
    end,

    ['kanagawa-paper'] = function()
        vim.cmd 'hi clear MsgArea'
    end,

    _all = function()
        vim.opt.background = 'dark'

        vim.cmd.hi 'barbecue_normal guibg=none'
        vim.cmd.hi 'barbecue_separator guibg=none'
        vim.cmd.hi 'barbecue_context guibg=none'
        vim.cmd.hi 'barbecue_dirname guibg=none'

        vim.cmd.hi 'StatusLine guibg=none guifg=none'
        vim.cmd.hi 'StatusLineNC guibg=none guifg=none'

        vim.cmd.hi 'Normal guibg=none ctermbg=none'
        vim.cmd.hi 'MsgSeparator guibg=none ctermbg=none'

        vim.cmd.hi 'TelescopePreviewNormal guibg=none'
        vim.cmd.hi 'TelescopePreviewBorder guibg=none'
        vim.cmd.hi 'TelescopeResultsNormal guibg=none'
        vim.cmd.hi 'TelescopeResultsBorder guibg=none'
        vim.cmd.hi 'TelescopePromptNormal guibg=none'
        vim.cmd.hi 'TelescopePromptBorder guibg=none'

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
    end,
}

---Adjust the colorscheme for conflicts.
---
---@param theme string The theme key.
function M.adjustConflicts(theme)
    ADJUSTMENTS._all()

    if ADJUSTMENTS[theme] then
        ADJUSTMENTS[theme]()
    end
end

---Update the colorscheme.
---
---@param arg? string Optionally pass in a theme key, in case there's none or it's empty 'default' will be used instead.
function M.update(arg)
    local theme = arg and #arg > 0 and arg or vim.env.NVIM_THEME or 'default'
    local themes = vim.fn.getcompletion('*', 'color')

    local up = function(t)
        vim.cmd.colorscheme(t)
        M.adjustConflicts(t)
    end

    if tables.contains(themes, theme) then
        return up(theme)
    end

    vim.notify('Theme "' .. theme .. '" not found. Falling back to default theme.', vim.log.levels.WARN)
    up 'default'
end

return M
