local M = {}

function M.setup()
    local commands = require 'utils.commands'

    local GODOT_LSP_PORT = tonumber(os.getenv 'GDScript_Port') or 6005

    local godot_job = nil
    local godot_timer = nil
    local godot_pending = {}
    local godot_starting = false

    local function godot_port_open(port)
        local ok, channel = pcall(vim.fn.sockconnect, 'tcp', '127.0.0.1:' .. port, { timeout = 100 })
        if ok and channel > 0 then
            pcall(vim.fn.chanclose, channel)
            return true
        end
        return false
    end

    local function stop_godot_timer()
        if godot_timer then
            godot_timer:stop()
            pcall(function()
                godot_timer:close()
            end)
            godot_timer = nil
        end
    end

    local function connect_godot_lsp(bufnr, root, port)
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end
        if vim.bo[bufnr].filetype ~= 'gdscript' then
            return
        end
        for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
            if c.name == 'gdscript' then
                return
            end
        end
        local client_id = vim.lsp.start({
            name = 'gdscript',
            cmd = vim.lsp.rpc.connect('127.0.0.1', port),
            root_dir = root,
            capabilities = vim.lsp.protocol.make_client_capabilities(),
        }, { bufnr = bufnr })
        if not client_id then
            vim.notify('Failed to start gdscript LSP client', vim.log.levels.WARN)
        end
    end

    local function spawn_godot_lsp(bufnr, root)
        if godot_job or godot_starting then
            table.insert(godot_pending, { bufnr = bufnr, root = root })
            return
        end
        godot_starting = true
        table.insert(godot_pending, { bufnr = bufnr, root = root })
        vim.notify('Starting headless Godot LSP...', vim.log.levels.INFO)
        godot_job = vim.system({ 'godot', '--headless', '--editor', '--lsp-port', tostring(GODOT_LSP_PORT), '--path', root }, { detach = false }, function(result)
            vim.schedule(function()
                stop_godot_timer()
                godot_job = nil
                godot_starting = false
                if result.code ~= 0 then
                    vim.notify('Headless Godot exited with code ' .. result.code, vim.log.levels.ERROR)
                end
                godot_pending = {}
            end)
        end)
        local elapsed = 0
        godot_timer = vim.uv.new_timer()
        godot_timer:start(500, 500, function()
            vim.schedule(function()
                elapsed = elapsed + 500
                if not godot_job and godot_starting then
                    stop_godot_timer()
                    godot_starting = false
                    godot_pending = {}
                    return
                end
                if godot_port_open(GODOT_LSP_PORT) then
                    stop_godot_timer()
                    godot_starting = false
                    local pending = godot_pending
                    godot_pending = {}
                    for _, item in ipairs(pending) do
                        connect_godot_lsp(item.bufnr, item.root, GODOT_LSP_PORT)
                    end
                    if #pending > 0 then
                        vim.notify('Connected to headless Godot LSP', vim.log.levels.INFO)
                    end
                elseif elapsed >= 30000 then
                    stop_godot_timer()
                    godot_starting = false
                    godot_pending = {}
                    vim.notify('Headless Godot LSP did not start in time', vim.log.levels.WARN)
                end
            end)
        end)
    end

    commands.auto('FileType', {
        pattern = 'gdscript',
        group = commands.augroup('GodotLspHeadless'),
        callback = function(event)
            local root = vim.fs.root(event.buf, { 'project.godot', '.git' })
            if not root then
                return
            end
            if godot_port_open(GODOT_LSP_PORT) then
                connect_godot_lsp(event.buf, root, GODOT_LSP_PORT)
                return
            end
            spawn_godot_lsp(event.buf, root)
        end,
    })

    commands.auto('VimLeavePre', {
        group = commands.augroup('GodotLspCleanup'),
        callback = function()
            stop_godot_timer()
            if godot_job then
                godot_job:kill('term')
            end
        end,
    })
end

return M
