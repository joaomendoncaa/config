return {
    -- A task runner and job management plugin for Neovim.
    -- SEE: https://github.com/stevearc/overseer.nvim
    'stevearc/overseer.nvim',

    event = 'VeryLazy',

    init = function()
        local keymap = vim.keymap.set

        keymap('n', '<leader>rp', '<CMD>OverseerToggle<CR>', { desc = 'Toggle [R]un tasks [P]anel.' })
        keymap('n', '<leader>rt', '<CMD>OverseerRun<CR>', { desc = '[R]un [T]asks.' })
    end,

    config = function()
        require('overseer').setup {
            task_list = {
                direction = 'bottom',
                default_detail = 1,
            },
        }

        -- load all task files defined at `tasks/`
        -- SEE: https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#template-definition
        for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/tasks/*.lua', true)) do
            loadfile(ft_path)()
        end
    end,
}
