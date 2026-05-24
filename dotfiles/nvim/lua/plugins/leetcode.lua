local SUFIX = 'leet'

return {
    {
        'kawre/leetcode.nvim',

        lazy = SUFIX ~= vim.fn.argv(0),
        build = ':TSUpdate html',
        cmd = 'Leet',

        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'ibhagwan/fzf-lua',
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
        },

        config = function()
            local plugin = require 'leetcode'

            local key = require('utils.misc').key

            key('n', '<leader>Ll', '<CMD>Leet<CR>')
            key('n', '<leader>Lr', '<CMD>Leet run<CR>')
            key('n', '<leader>Ls', '<CMD>Leet submit<CR>')
            key('n', '<leader>Lb', '<CMD>Leet open<CR>')
            key('n', '<leader>Lh', '<CMD>CodeCompanion /dsa<CR>')

            plugin.setup {
                arg = SUFIX,
                lang = os.getenv 'LLANG' or 'rust',
                picker = {
                    provider = 'fzf-lua',
                },
                description = {
                    width = '35%',
                },
                injector = {
                    rust = {
                        before = { '#![allow(dead_code)]', '', 'fn main() {}', 'struct Solution;' },
                    },
                },
                hooks = {
                    question_enter = {
                        function(question)
                            if question.lang ~= 'rust' then
                                return
                            end
                            local cargo_path = require('leetcode.config').user.storage.home .. '/Cargo.toml'
                            local content = [[
                                [package]
                                name = "leetcode"
                                edition = "2024"

                                [lib]
                                name = "%s"
                                path = "%s"

                                [dependencies]
                                rand = "0.8"
                                regex = "1"
                                itertools = "0.14.0"
                            ]]

                            local file = io.open(cargo_path, 'w')
                            if file then
                                local formatted = (content:gsub(' +', '')):format(question.q.frontend_id, question:path())
                                file:write(formatted)
                                file:close()
                                for _, client in ipairs(vim.lsp.get_clients { name = 'rust_analyzer' }) do
                                    vim.lsp.restart_client(client.id)
                                end
                            end
                        end,
                    },
                },
            }
        end,
    },
}
