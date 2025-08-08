return {
    {
        'ibhagwan/fzf-lua',

        event = 'VeryLazy',

        dependencies = {
            'nvim-tree/nvim-web-devicons',
            enabled = vim.g.NVIM_NERD_FONT,
        },

        config = function()
            ---@module 'fzf-lua'
            local fzf = require 'fzf-lua'
            local key = require('utils.misc').key

            local function search_themes()
                fzf.colorschemes { winopts = { height = 0.33, width = 0.33 } }
            end

            local function search_files_config()
                fzf.files {
                    cwd = os.getenv 'HOME' .. '/.config.jmmm.sh',
                }
            end

            local function search_plugins_config()
                local core = require 'lazy.core.config'
                local plugin_list = core.plugins
                local entries = {}

                for name, plugin in pairs(plugin_list) do
                    if plugin.url then
                        table.insert(entries, string.format('%s | %s', name, plugin.url))
                    end
                end

                fzf.fzf_exec(entries, {
                    prompt = ' Plugins> ',
                    winopts = {
                        height = 0.5,
                        width = 0.65,
                    },
                    actions = {
                        ['default'] = function(selected)
                            local url = selected[1]:match '| (.+)$'

                            if url then
                                vim.ui.open(url)
                                vim.notify('Opening ' .. url, vim.log.levels.INFO)
                            end
                        end,
                    },
                })
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

            local function list_lsp_references()
                local clients = vim.lsp.get_clients { bufnr = 0 }
                if #clients == 0 then
                    vim.notify('No LSP client attached', vim.log.levels.ERROR)
                    return
                end

                local params = vim.lsp.util.make_position_params()
                params.context = { includeDeclaration = true }
                local results = vim.lsp.buf_request_sync(0, 'textDocument/references', params, 1000)
                if not results then
                    vim.notify('No LSP results received (timeout)', vim.log.levels.WARN)
                    return
                end

                local refs = {}
                for client_id, result in pairs(results) do
                    if result.error then
                        vim.notify(string.format('LSP Error from client %d: %s', client_id, vim.inspect(result.error)), vim.log.levels.ERROR)
                        return
                    end

                    if result.result then
                        for _, location in ipairs(result.result) do
                            table.insert(refs, location)
                        end
                    end
                end

                if #refs == 0 then
                    vim.notify('No references found', vim.log.levels.INFO)
                    return
                end

                if #refs == 1 then
                    vim.lsp.util.jump_to_location(refs[1])
                    return
                end

                fzf.lsp_references()
            end

            key({ 'n', 'v' }, '<leader>sp', fzf.complete_path, '[S]earch [P]ath')
            key('n', '<leader>ss', fzf.files, '[S]earch [S]elected CWD directory files')
            key('n', 'gr', fzf.lsp_references, '[G]oto [R]eferences')
            key('n', 'gd', fzf.lsp_definitions, '[G]oto [D]efinition')
            key('n', 'gD', fzf.lsp_declarations, '[G]oto [D]eclaration')
            key('n', 'gI', fzf.lsp_implementations, '[G]oto [I]mplementation')
            key('n', 'gf', fzf.lsp_finder, '[G]oto [F]ind all locations')
            key('n', '<leader>sg', fzf.live_grep, '[S]earch by [G]rep')
            key('n', '<leader>sm', fzf.marks, '[S]earch [M]arks')
            key('n', '<leader>sf', fzf.builtin, '[S]earch [F]zf Builtins')
            key('n', '<leader>sk', fzf.keymaps, '[S]earch [K]eymaps')
            key('n', '<leader>sh', fzf.helptags, '[S]earch [H]elp')
            key('n', '<leader>sH', fzf.highlights, '[S]earch [H]ighlights')
            key('n', '<leader>sb', fzf.buffers, '[S]earch open [B]uffers')
            key('n', '<leader>sd', fzf.diagnostics_document, '[S]earch [D]iagnostics')
            key('n', '<leader>sD', fzf.diagnostics_workspace, '[S]earch [D]iagnostics')
            key('n', '<leader>D', fzf.lsp_typedefs, 'Type [D]efinition')
            key('n', '<leader>ds', fzf.lsp_document_symbols, '[D]ocument [S]ymbols')
            key('n', '<leader>sw', fzf.lsp_workspace_symbols, '[W]orkspace [S]ymbols')
            key('n', '<leader>sSs', search_spelling, '[S]earch [S]pelling suggestions')
            key('n', '<leader>scf', search_files_config, '[S]earch [C]onfig [F]iles')
            key('n', '<leader>scp', search_plugins_config, '[S]earch [C]onfig [P]lugins')
            key('n', '<leader>se', search_enviroment, '[S]earch [E]nvironment Variables')
            key('n', '<leader>st', search_themes, '[S]earch [T]heme')

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

            -- fzf.register_ui_select()
        end,
    },
}
