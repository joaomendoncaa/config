return {
    'nvim-treesitter/nvim-treesitter',

    lazy = false,
    build = ':TSUpdate',

    init = function()
        local errors = require 'utils.errors'

        errors.ignore {
            'treesitter.-Index out of bounds',
        }

        local ensure_installed = {
            'tsx',
            'typescript',
            'go',
            'bash',
            'c',
            'diff',
            'html',
            'lua',
            'luadoc',
            'markdown',
            'markdown_inline',
            'query',
            'vim',
            'vimdoc',
        }

        require('nvim-treesitter').install(ensure_installed)

        vim.api.nvim_create_autocmd('FileType', {
            callback = function()
                pcall(vim.treesitter.start)
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,

    config = function()
        local errors = require 'utils.errors'

        errors.ignore {
            'treesitter.-Index out of bounds',
        }

        local key = require('utils.misc').key

        local function git_plugin()
            if vim.bo.filetype ~= 'lua' then
                vim.notify('Not in a Lua file.', vim.log.levels.WARN)
                return
            end

            local bufnr = vim.api.nvim_get_current_buf()
            local parser = vim.treesitter.get_parser(bufnr, 'lua')
            local tree = parser:parse()[1]
            local root = tree:root()

            local query = vim.treesitter.query.parse(
                'lua',
                [[
                (table_constructor
                  (field
                    (string) @plugin_name)
                  .
                  (field
                    name: ((identifier) @field_name
                      (#match? @field_name "^(opts|config|event)$"))))
                ]]
            )

            for id, node in query:iter_captures(root, bufnr, 0, -1) do
                local name = query.captures[id]
                if name == 'plugin_name' then
                    local plugin = vim.treesitter.get_node_text(node, bufnr):gsub('["\']', '')
                    vim.ui.open('https://github.com/' .. plugin)
                    vim.notify('Opening GitHub repository for ' .. plugin, vim.log.levels.INFO)
                    return plugin
                end
            end
        end

        key('n', '<leader>gp', git_plugin, '[G]o [G]it [P]lugin')

        vim.opt.verbose = 0

        require('nvim-treesitter').setup {}
    end,
}
