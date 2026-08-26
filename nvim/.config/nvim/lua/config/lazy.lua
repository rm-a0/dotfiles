-- https://github.com/folke/lazy.nvim

-- vim.loop is the deprecated alias for vim.uv.
local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not uv.fs_stat(lazypath) then
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error("Failed to clone lazy.nvim:\n" .. out)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Every file in lua/plugins/ is imported automatically, so adding a
    -- plugin means adding a file -- this list never needs editing.
    { import = "plugins" },
}, {
    ui = { icons = vim.g.have_nerd_font and {} or {} },
    change_detection = { notify = false },
})
