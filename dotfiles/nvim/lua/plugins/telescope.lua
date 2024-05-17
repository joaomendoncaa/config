return {
    -- Find, Filter, Preview, Pick. All lua, all the time.
    -- SEE: https://github.com/nvim-telescope/telescope.nvim
    'nvim-telescope/telescope.nvim',

    branch = '0.1.x',
    lazy = true,
    keys = {
        '<leader>s',
        '<leader>/',
    },

    dependencies = {
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-lua/plenary.nvim',
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },

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

    config = function()
        require('telescope').setup {
            extensions = {
                ['ui-select'] = {
                    require('telescope.themes').get_dropdown(),
                },
            },
        }

        -- enable telescope extensions, if they are installed
        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'ui-select')

        local builtin = require 'telescope.builtin'
        local keymap = vim.keymap.set

        keymap('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp.' })
        keymap('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps.' })
        keymap('n', '<leader>ss', builtin.find_files, { desc = '[S]earch [S]elect files.' })
        keymap('n', '<leader>sS', builtin.builtin, { desc = '[S]earch [S]elect Telescope.' })
        keymap('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep.' })
        keymap('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics.' })
        keymap('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume.' })
        keymap('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat).' })
        keymap('n', '<leader>sb', builtin.buffers, { desc = '[S]earch open [B]uffers.' })

        keymap('n', '<leader>/', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 0,
                previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer.' })

        keymap('n', '<leader>s/', function()
            builtin.live_grep {
                grep_open_files = true,
                prompt_title = 'Live Grep in Open Files.',
            }
        end, { desc = '[S]earch [/] in Open Files.' })

        keymap('n', '<leader>sc', function()
            builtin.find_files { cwd = os.getenv 'HOME' .. '/lab/config' }
        end, { desc = '[S]earch [C]onfig files.' })
    end,
}
