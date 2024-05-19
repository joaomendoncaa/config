local themes = {}

function themes.adjustConflicts(match)
    local adjustment_schemes = {
        poimandres = function()
            vim.cmd.hi 'Comment gui=none'
            vim.cmd.hi 'LspReferenceWrite guibg=none'
            vim.cmd.hi 'LspReferenceText guibg=none'
            vim.cmd.hi 'LspReferenceRead guibg=none'
        end,

        blue = function()
            vim.cmd.hi 'Comment gui=none'
        end,
    }

    if adjustment_schemes[match] then
        adjustment_schemes[match]()
    end
end

return themes
