-- `:help lua-guide-autocommands`

-- Briefly highlight yanked text.
-- vim.highlight.on_yank was deprecated in 0.11 in favour of vim.hl.on_yank;
-- the fallback keeps this working on older Neovim.
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("rice-highlight-yank", { clear = true }),
    callback = function()
        (vim.hl or vim.highlight).on_yank()
    end,
})
