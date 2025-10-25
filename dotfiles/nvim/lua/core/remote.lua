pcall(function()
    local run = vim.fn.stdpath 'run'
    if run == '' or vim.fn.isdirectory(run) == 0 then
        vim.notify('nvim remote: invalid runtime dir: ' .. run, vim.log.levels.WARN)
        return
    end

    local sock = string.format('%s/nvim-%d.sock', run, vim.fn.getpid())
    local ok, err = pcall(vim.fn.serverstart, sock)

    if not ok then
        vim.notify('nvim remote: failed to start server on ' .. sock .. '\n' .. tostring(err), vim.log.levels.WARN)
        return
    end

    vim.fn.setenv('NVIM_LISTEN_ADDRESS', sock)
end)
