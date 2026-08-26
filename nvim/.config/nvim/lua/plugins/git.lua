-- Git: gutter signs and hunk actions, plus a full-project diff view.

return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                end

                -- Hunk navigation. Defers to vimdiff's own ]c/[c when in a diff.
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, "Next Git [C]hange")

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, "Previous Git [C]hange")

                map("n", "<leader>hs", gitsigns.stage_hunk, "[H]unk [S]tage")
                map("n", "<leader>hr", gitsigns.reset_hunk, "[H]unk [R]eset")
                map("v", "<leader>hs", function()
                    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "[H]unk [S]tage")
                map("v", "<leader>hr", function()
                    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "[H]unk [R]eset")
                map("n", "<leader>hS", gitsigns.stage_buffer, "[H]unk [S]tage buffer")
                map("n", "<leader>hR", gitsigns.reset_buffer, "[H]unk [R]eset buffer")
                map("n", "<leader>hp", gitsigns.preview_hunk, "[H]unk [P]review (inline diff)")
                map("n", "<leader>hb", gitsigns.blame_line, "[H]unk [B]lame line")
                map("n", "<leader>hd", gitsigns.diffthis, "[H]unk [D]iff this file")
                map("n", "<leader>htb", gitsigns.toggle_current_line_blame, "[T]oggle git [B]lame line")
                map("n", "<leader>htd", gitsigns.toggle_deleted, "[T]oggle git show [D]eleted")
            end,
        },
    },

    {
        -- Closest equivalent to VSCode's Source Control diff panel
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "[G]it [D]iff view (all changes)" },
            { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "[G]it Diff view close" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "[G]it file [H]istory" },
        },
    },
}
