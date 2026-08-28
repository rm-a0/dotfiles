-- LSP: server management via mason, keymaps bound on attach.

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "williamboman/mason.nvim", config = true }, -- must load before dependants
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            { "j-hui/fidget.nvim", opts = {} },

            -- lua_ls tuned for editing Neovim config.
            {
                "folke/lazydev.nvim",
                ft = "lua",
                opts = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    },
                },
            },
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("rice-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    local builtin = require("telescope.builtin")
                    map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
                    map("gr", builtin.lsp_references, "[G]oto [R]eferences")
                    map("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
                    map("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")
                    map("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
                    map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    map("K", vim.lsp.buf.hover, "Hover Documentation")
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    -- <LeftMouse> first, or the jump uses the old cursor
                    -- position rather than what was clicked.
                    vim.keymap.set(
                        "n",
                        "<C-LeftMouse>",
                        "<LeftMouse><cmd>lua require('telescope.builtin').lsp_definitions()<CR>",
                        { buffer = event.buf, desc = "LSP: Goto definition (ctrl+click)" }
                    )

                    local client = vim.lsp.get_client_by_id(event.data.client_id)

                    -- ruff's hover duplicates pyright's and is thinner.
                    if client and client.name == "ruff" then
                        client.server_capabilities.hoverProvider = false
                    end

                    -- Highlight other references to the symbol under the cursor.
                    if client and client:supports_method("textDocument/documentHighlight") then
                        local group = vim.api.nvim_create_augroup("rice-lsp-highlight", { clear = false })

                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = group,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = group,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = vim.api.nvim_create_augroup("rice-lsp-detach", { clear = true }),
                            callback = function(detach)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({
                                    group = "rice-lsp-highlight",
                                    buffer = detach.buf,
                                })
                            end,
                        })
                    end

                    if client and client:supports_method("textDocument/inlayHint") then
                        map("<leader>th", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                        end, "[T]oggle Inlay [H]ints")
                    end
                end,
            })

            -- Point pyright at the project venv so third-party imports
            -- resolve. Without it pyright uses the `python` on PATH and
            -- flags everything outside stdlib as a missing import.
            -- Prefers an activated venv, else .venv/venv under the root.
            local function venv_python(root)
                if vim.env.VIRTUAL_ENV then
                    return vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin", "python")
                end
                for _, name in ipairs({ ".venv", "venv" }) do
                    local py = vim.fs.joinpath(root or vim.fn.getcwd(), name, "bin", "python")
                    if vim.uv.fs_stat(py) then
                        return py
                    end
                end
            end

            -- Adding a key here installs and enables it.
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = { completion = { callSnippet = "Replace" } },
                    },
                },

                -- Without a server, gd falls back to vim's builtin: a
                -- backwards textual search that stops at the import line.
                -- Honours [tool.pyright] in pyproject.toml.
                pyright = {
                    before_init = function(_, config)
                        local py = venv_python(config.root_dir)
                        if py then
                            config.settings.python = config.settings.python or {}
                            config.settings.python.pythonPath = py
                        end
                    end,
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "basic",
                                diagnosticMode = "openFilesOnly",
                            },
                        },
                    },
                },

                -- Lint and code actions only; pyright owns hover and goto.
                ruff = {},
            }

            -- `*` supplies defaults to every server.
            vim.lsp.config("*", {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })

            for name, cfg in pairs(servers) do
                vim.lsp.config(name, cfg)
            end

            require("mason").setup()

            -- Formatter for conform, not a server.
            local ensure_installed = vim.tbl_keys(servers)
            vim.list_extend(ensure_installed, { "stylua" })
            require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

            require("mason-lspconfig").setup({
                -- Explicit list, not `true` -- that also enables formatters
                -- like stylua as if they were servers.
                automatic_enable = vim.tbl_keys(servers),
            })
        end,
    },

    -- Workspace diagnostics. <leader>e floats one, <leader>q dumps to
    -- quickfix; neither survives moving the cursor.
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (workspace)" },
            { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
            { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols outline" },
            { "<leader>xl", "<cmd>Trouble lsp toggle win.position=right<CR>", desc = "Definitions / references" },
            { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
            { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "TODO comments" },
        },
    },
}
