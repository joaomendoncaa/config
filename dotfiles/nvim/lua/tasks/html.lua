local overseer = require 'overseer'

overseer.register_template {
    name = 'serve index.html',
    description = 'Serve the current index.html locally.',

    builder = function(_)
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir = vim.fn.fnamemodify(buf_name, ':h')

        return {
            cmd = { 'browser-sync' },
            args = { 'start', '--server', '--files', 'index.html' },
            cwd = dir,
        }
    end,

    condition = {
        -- only run this task if the current buffer is an .html file
        callback = function(_)
            local buf_name = vim.api.nvim_buf_get_name(0)
            local filetype = vim.bo.filetype
            return filetype == 'html' and buf_name:match 'index%.html$' ~= nil
        end,
    },
}
