return {
    'nvim-treesitter/nvim-treesitter',

    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSInstall', 'TSBufEnable', 'TSBufDisable', 'TSModuleInfo' },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',

    config = function()
        local config = require 'nvim-treesitter.configs'
        local key = require('utils.functions').key

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

        config.setup {
            auto_install = true,
            ensure_installed = {
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
            },
            textobjects = {
                select = {
                    enable = false,
                    keymaps = {
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner',
                        ['ac'] = '@class.outer',
                        ['ic'] = '@class.inner',
                    },
                },
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = { 'ruby' },

                disable = function(_, buf)
                    local max_filesize = 50 * 1024

                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        return true
                    end
                end,
            },
            indent = { enable = true, disable = { 'ruby' } },
        }
    end,
}
