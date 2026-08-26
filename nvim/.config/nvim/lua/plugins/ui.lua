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
        keys = {
            { "<leader>te", "<cmd>Neotree toggle<CR>", desc = "[T]oggle [E]xplorer" },
        },
        opts = {
            filesystem = {
                follow_current_file = { enabled = true },
                hijack_netrw_behavior = "open_current",
            },
            window = { width = 30 },
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
            { "<leader>bd", "<cmd>bdelete<CR>", desc = "[B]uffer [D]elete" },
        },
    },
}
