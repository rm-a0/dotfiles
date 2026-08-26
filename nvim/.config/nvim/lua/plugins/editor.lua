-- General editing behaviour: indentation detection, comments, text objects,
-- surround, statusline, TODO highlighting, and the keymap hint popup.

return {
    -- Detect tabstop/shiftwidth from the file being edited
    "tpope/vim-sleuth",

    -- "gc" to comment a visual region or line
    { "numToStr/Comment.nvim", opts = {} },

    {
        "folke/todo-comments.nvim",
        event = "VimEnter",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { signs = false },
    },

    {
        "folke/which-key.nvim",
        event = "VimEnter",
        opts = {},
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)

            -- which-key v3: .add(), not .register() (gone, fails silently).
            wk.add({
                { "<leader>c", group = "[C]ode" },
                { "<leader>d", group = "[D]ocument" },
                { "<leader>r", group = "[R]ename" },
                { "<leader>s", group = "[S]earch" },
                { "<leader>w", group = "[W]orkspace" },
                { "<leader>t", group = "[T]oggle" },
                { "<leader>g", group = "[G]it" },
                { "<leader>b", group = "[B]uffer" },
                { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
            })
        end,
    },

    {
        "echasnovski/mini.nvim",
        config = function()
            -- Around/inside text objects: va) yinq ci'
            require("mini.ai").setup({ n_lines = 500 })

            -- Add/delete/replace surroundings: saiw) sd' sr)'
            require("mini.surround").setup()

            local statusline = require("mini.statusline")
            statusline.setup({ use_icons = vim.g.have_nerd_font })

            ---@diagnostic disable-next-line: duplicate-set-field
            statusline.section_location = function()
                return "%2l:%-2v"
            end
        end,
    },
}
