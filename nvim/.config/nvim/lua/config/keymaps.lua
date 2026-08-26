-- `:help vim.keymap.set()`
-- Plugin-specific maps live with their plugin in lua/plugins/.

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Diagnostics.
-- vim.diagnostic.goto_prev/goto_next were deprecated in 0.11 and are gone in
-- 0.12; vim.diagnostic.jump replaces both.
map("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous [D]iagnostic" })

map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next [D]iagnostic" })

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Insert mode escape
map("i", "jk", "<Esc>", { desc = "Escape" })

-- Terminal mode escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Window navigation.
-- NOTE: <C-j> is deliberately absent -- toggleterm claims it for the terminal
-- toggle (see lua/plugins/ui.lua). Use <C-w>j to move to the window below.
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
