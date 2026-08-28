-- Editor furniture: file explorer, buffer tabs, integrated terminal.
-- Roughly the VSCode layout equivalents.

return {
    {
        -- <C-j> toggles it; the shell session survives being hidden.
        -- NOTE: this claims <C-j>, which is why config/keymaps.lua binds
        -- only <C-h>/<C-k>/<C-l> for window navigation.
        "akinsho/toggleterm.nvim",
        version = "*",
        opts = {
            open_mapping = [[<c-j>]],
            direction = "horizontal",
            size = 15,
            shade_terminals = true,
            start_in_insert = true,
        },
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
            "MunifTanjim/nui.nvim",
        },
        cmd = "Neotree",
        -- <C-b> pairs with the <C-j> terminal above. Normal-mode <C-b> is
        -- page-back, covered by <C-u>; cmp's is insert-mode only.
        keys = {
            { "<C-b>", "<cmd>Neotree toggle<CR>", desc = "[T]oggle [E]xplorer" },
            { "<leader>te", "<cmd>Neotree toggle<CR>", desc = "[T]oggle [E]xplorer" },
        },
        opts = {
            filesystem = {
                follow_current_file = { enabled = true },
                hijack_netrw_behavior = "open_current",

                -- Default hides both. visible=true dims them instead, via
                -- NeoTreeGitIgnored/NeoTreeDotfile.
                filtered_items = {
                    visible = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    never_show = { ".git", "__pycache__", ".DS_Store" },
                },

                -- Without this the tree only refreshes on focus.
                use_libuv_file_watcher = true,
            },
            window = {
                width = 30,
                mappings = {
                    -- <LeftRelease>, not <LeftMouse>: the cursor has moved
                    -- by the time the button comes up.
                    ["<LeftRelease>"] = "open",

                    -- neo-tree binds <C-b> to scroll_preview buffer-locally,
                    -- which shadows the global toggle inside the tree.
                    ["<C-b>"] = "close_window",
                },
            },
        },
    },

    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        event = "VimEnter",
        opts = {
            options = {
                diagnostics = "nvim_lsp",
                always_show_bufferline = true,
                show_buffer_icons = vim.g.have_nerd_font,
                show_buffer_close_icons = false,
                show_close_icon = false,
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "Explorer",
                        highlight = "Directory",
                        text_align = "left",
                    },
                },
            },
        },
        keys = {
            { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer tab" },
            { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer tab" },
            -- :bdelete closes the window too, tearing down splits.
            {
                "<leader>bd",
                function() require("mini.bufremove").delete(0, false) end,
                desc = "[B]uffer [D]elete",
            },
        },
    },
}
