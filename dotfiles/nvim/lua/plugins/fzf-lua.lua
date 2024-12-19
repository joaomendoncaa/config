return {
    {
        -- Improved fzf.vim written in lua
        -- SEE: https://github.com/ibhagwan/fzf-lua
        'ibhagwan/fzf-lua',

        dependencies = { 'nvim-tree/nvim-web-devicons', enabled = vim.g.NVIM_NERD_FONT },

        config = function()
            -- @module fzf-lua
            local plugin = require 'fzf-lua'

            local keymap = vim.keymap.set

            local function search_themes()
                plugin.colorschemes { winopts = { height = 0.33, width = 0.33 } }
            end

            local function search_files_config()
                plugin.files {
                    cwd = os.getenv 'HOME' .. '/lab/config',
                }
            end

            local function search_enviroment()
                local env_table = {}
                for k, v in pairs(vim.fn.environ()) do
                    table.insert(env_table, k .. '=' .. v)
                end
                plugin.fzf_exec(env_table)
            end

            keymap('n', '<leader>sg', plugin.live_grep, { desc = '[S]earch by [G]rep.' })
            keymap('n', '<leader>sS', plugin.builtin, { desc = '[S]earch [S]elect Builtin.' })
            keymap('n', '<leader>sk', plugin.keymaps, { desc = '[S]earch [K]eymaps.' })
            keymap('n', '<leader>sh', plugin.helptags, { desc = '[S]earch [H]elp.' })
            keymap('n', '<leader>sH', plugin.highlights, { desc = '[S]earch [H]ighlights.' })
            keymap('n', '<leader>sb', plugin.buffers, { desc = '[S]earch open [B]uffers.' })
            keymap('n', '<leader>ss', plugin.files, { desc = '[S]earch [S]elected directory files.' })
            keymap({ 'n', 'v', 'i' }, '<leader>sp', plugin.complete_path, { desc = '[S]earch [P]ath.' })
            keymap('n', '<leader>sc', search_files_config, { desc = '[S]earch [S]elected directory files.' })
            keymap('n', '<leader>se', search_enviroment, { desc = '[S]earch [E]nvironment Variables.' })
            keymap('n', '<leader>st', search_themes, { desc = '[S]earch [T]heme.' })

            require('fzf-lua').setup {
                keymap = {
                    builtin = {
                        ['<C-u>'] = 'preview-page-up',
                        ['<C-d>'] = 'preview-page-down',
                    },
                },
            }
        end,
    },
}
