return {
    {
        -- Improved fzf.vim written in lua
        -- SEE: https://github.com/ibhagwan/fzf-lua
        'ibhagwan/fzf-lua',

        event = 'VeryLazy',

        dependencies = {
            'nvim-tree/nvim-web-devicons',
            enabled = vim.g.NVIM_NERD_FONT,
        },

        config = function()
            local fzf = require 'fzf-lua'

            local keymap = vim.keymap.set

            local function search_themes()
                fzf.colorschemes { winopts = { height = 0.33, width = 0.33 } }
            end

            local function search_files_config()
                fzf.files {
                    cwd = os.getenv 'HOME' .. '/.config.jmmm.sh',
                }
            end

            local function search_spelling()
                fzf.spell_suggest {
                    winopts = {
                        relative = 'cursor',
                        row = 1.01,
                        col = 0,
                        height = 0.2,
                        width = 0.2,
                    },
                }
            end

            local function search_enviroment()
                local env_table = {}
                for k, v in pairs(vim.fn.environ()) do
                    table.insert(env_table, k .. '=' .. v)
                end
                fzf.fzf_exec(env_table)
            end

            keymap({ 'n', 'v' }, '<leader>sp', fzf.complete_path, { desc = '[S]earch [P]ath.' })
            keymap('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep.' })
            keymap('n', '<leader>sf', fzf.builtin, { desc = '[S]earch [F]zf Builtins.' })
            keymap('n', '<leader>sk', fzf.keymaps, { desc = '[S]earch [K]eymaps.' })
            keymap('n', '<leader>sh', fzf.helptags, { desc = '[S]earch [H]elp.' })
            keymap('n', '<leader>sH', fzf.highlights, { desc = '[S]earch [H]ighlights.' })
            keymap('n', '<leader>sb', fzf.buffers, { desc = '[S]earch open [B]uffers.' })
            keymap('n', '<leader>ss', fzf.files, { desc = '[S]earch [S]elected CWD directory files.' })
            keymap('n', '<leader>sS', search_spelling, { desc = '[S]earch [S]pelling suggestions.' })
            keymap('n', '<leader>sc', search_files_config, { desc = '[S]earch [S]elected directory files.' })
            keymap('n', '<leader>se', search_enviroment, { desc = '[S]earch [E]nvironment Variables.' })
            keymap('n', '<leader>st', search_themes, { desc = '[S]earch [T]heme.' })
            keymap('n', 'gd', fzf.lsp_definitions, { desc = '[G]oto [D]efinition.' })
            keymap('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' })
            keymap('n', 'gI', fzf.lsp_implementations, { desc = '[G]oto [I]mplementation.' })
            keymap('n', 'gr', fzf.lsp_references, { desc = '[G]oto [R]eferences.' })
            keymap('n', '<leader>D', fzf.lsp_typedefs, { desc = 'Type [D]efinition.' })
            keymap('n', '<leader>ds', fzf.lsp_document_symbols, { desc = '[D]ocument [S]ymbols.' })
            keymap('n', '<leader>sw', fzf.lsp_workspace_symbols, { desc = '[W]orkspace [S]ymbols.' })

            fzf.setup {
                file_ignore_patterns = { 'node_modules' },
                winopts = {
                    preview = {
                        layout = 'vertical',
                    },
                },
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
