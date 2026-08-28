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

-- Vim expands whatever window remains, so closing the last file buffer
-- leaves a full-width file tree.
vim.api.nvim_create_autocmd("QuitPre", {
    desc = "Close neo-tree if it would be left alone",
    group = vim.api.nvim_create_augroup("rice-neotree-last-window", { clear = true }),
    callback = function()
        local floating = 0
        local normal = 0
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(w).relative ~= "" then
                floating = floating + 1
            elseif vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "neo-tree" then
                normal = normal + 1
            end
        end
        -- normal counts the window being quit, so 1 means it is the last one.
        if normal == 1 and floating == 0 then
            vim.cmd("Neotree close")
        end
    end,
})
