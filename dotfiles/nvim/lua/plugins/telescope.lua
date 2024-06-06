return {
    -- Find, Filter, Preview, Pick. All lua, all the time.
    -- SEE: https://github.com/nvim-telescope/telescope.nvim
    'nvim-telescope/telescope.nvim',

    branch = '0.1.x',

    keys = {
        '<leader>s',
        '<leader>/',
    },
    cmd = {
        'Telescope',
    },

    dependencies = {
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-lua/plenary.nvim',
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g._NERD_FONT },

        {
            -- FZF sorter for telescope written in C.
            -- SEE: https://github.com/nvim-telescope/telescope-fzf-native.nvim
            'nvim-telescope/telescope-fzf-native.nvim',

            -- `build` is used to run some command when the plugin is installed/updated.
            -- This is only run then, not every time Neovim starts up.
            build = 'make',

            -- `cond` is a condition used to determine whether this plugin should be
            -- installed and loaded.
            cond = function()
                return vim.fn.executable 'make' == 1
            end,
        },
    },

    -- This config houses custom pickers and actions.
    -- to read more about them, check the following:
    -- SEE: https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md
    config = function()
        local telescope = require 'telescope'
        local builtin = require 'telescope.builtin'
        local pickers = require 'telescope.pickers'
        local finders = require 'telescope.finders'
        local themes = require 'telescope.themes'
        local conf = require('telescope.config').values
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'

        local keymap = vim.keymap.set

        local search_enviroment = function(opts)
            opts = themes.get_dropdown {
                winblend = 0,
                width = 0.5,
                previewer = false,
                prompt_title = 'Environment Variables',
            }

            local env_table = {}

            for k, v in pairs(vim.fn.environ()) do
                table.insert(env_table, k .. '=' .. v)
            end

            pickers
                .new(opts, {
                    finder = finders.new_table {
                        results = env_table,
                    },

                    sorter = conf.generic_sorter(opts),

                    attach_mappings = function(prompt_bufnr, _)
                        actions.select_default:replace(function()
                            local selection = action_state.get_selected_entry()

                            actions.close(prompt_bufnr)

                            -- TODO: update the value of a variable inside nvim by prompting for it after selection
                            print(require('utils.strings').fromTable(selection))
                        end)
                        return true
                    end,
                })
                :find()
        end

        local search_files = function()
            builtin.find_files {
                hidden = true,
            }
        end

        local search_files_config = function()
            builtin.find_files {
                cwd = os.getenv 'HOME' .. '/lab/config',
                hidden = true,
            }
        end

        local fuzzy_inside_open_buffer = function()
            builtin.current_buffer_fuzzy_find(themes.get_dropdown {
                winblend = 0,
                previewer = false,
            })
        end

        local fuzzy_inside_open_files = function()
            builtin.live_grep {
                grep_open_files = true,
                prompt_title = 'Live Grep in Open Files.',
            }
        end

        keymap('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp.' })
        keymap('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps.' })
        keymap('n', '<leader>sS', builtin.builtin, { desc = '[S]earch [S]elect Telescope.' })
        keymap('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep.' })
        keymap('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics.' })
        keymap('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat).' })
        keymap('n', '<leader>sb', builtin.buffers, { desc = '[S]earch open [B]uffers.' })
        keymap('n', '<leader>st', builtin.colorscheme, { desc = '[S]earch colorsh[T]heme.' })
        keymap('n', '<leader>se', search_enviroment, { desc = '[S]earch [E]nvironment Variables.' })
        keymap('n', '<leader>ss', search_files, { desc = '[S]earch [S]elect files.' })
        keymap('n', '<leader>sc', search_files_config, { desc = '[S]earch [C]onfig files.' })
        keymap('n', '<leader>/', fuzzy_inside_open_buffer, { desc = '[/] Fuzzily search in current buffer.' })
        keymap('n', '<leader>s/', fuzzy_inside_open_files, { desc = '[S]earch [/] in Open Files.' })

        pcall(telescope.load_extension, 'fzf')
        pcall(telescope.load_extension, 'ui-select')

        telescope.setup {
            extensions = {
                ['ui-select'] = {
                    themes.get_dropdown(),
                },
            },
            defaults = {
                file_ignore_patterns = { '.git', 'node_modules' },
            },
        }
    end,
}
