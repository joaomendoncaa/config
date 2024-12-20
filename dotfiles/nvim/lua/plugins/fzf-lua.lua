return {
    {
        -- Improved fzf.vim written in lua
        -- SEE: https://github.com/ibhagwan/fzf-lua
        'ibhagwan/fzf-lua',

        dependencies = { 'nvim-tree/nvim-web-devicons', enabled = vim.g.NVIM_NERD_FONT },

        config = function()
            -- @module fzf-lua
            local fzf = require 'fzf-lua'

            local keymap = vim.keymap.set

            local function search_themes()
                fzf.colorschemes { winopts = { height = 0.33, width = 0.33 } }
            end

            local function search_files_config()
                fzf.files {
                    cwd = os.getenv 'HOME' .. '/lab/config',
                }
            end

            local function search_enviroment()
                local env_table = {}
                for k, v in pairs(vim.fn.environ()) do
                    table.insert(env_table, k .. '=' .. v)
                end
                fzf.fzf_exec(env_table)
            end

            keymap('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep.' })
            keymap('n', '<leader>sS', fzf.builtin, { desc = '[S]earch [S]elect Builtin.' })
            keymap('n', '<leader>sk', fzf.keymaps, { desc = '[S]earch [K]eymaps.' })
            keymap('n', '<leader>sh', fzf.helptags, { desc = '[S]earch [H]elp.' })
            keymap('n', '<leader>sH', fzf.highlights, { desc = '[S]earch [H]ighlights.' })
            keymap('n', '<leader>sb', fzf.buffers, { desc = '[S]earch open [B]uffers.' })
            keymap('n', '<leader>ss', fzf.files, { desc = '[S]earch [S]elected directory files.' })
            keymap({ 'n', 'v', 'i' }, '<leader>sp', fzf.complete_path, { desc = '[S]earch [P]ath.' })
            keymap('n', '<leader>sc', search_files_config, { desc = '[S]earch [S]elected directory files.' })
            keymap('n', '<leader>se', search_enviroment, { desc = '[S]earch [E]nvironment Variables.' })
            keymap('n', '<leader>st', search_themes, { desc = '[S]earch [T]heme.' })

            fzf.setup {
                previewers = {
                    builtin = {
                        syntax_limit_b = 1024 * 100,
                    },
                },
                keymap = {
                    builtin = {
                        ['<C-u>'] = 'preview-page-up',
                        ['<C-d>'] = 'preview-page-down',
                    },
                    fzf = {
                        ['ctrl-q'] = 'select-all+accept',
                    },
                },
            }

            fzf.register_ui_select()
        end,
    },
}
