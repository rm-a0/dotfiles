-- Neovim entry point. Settings in lua/config/, plugins in lua/plugins/.

-- Before lazy, or plugins bind the wrong leader.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Gates devicons everywhere; false falls back to ASCII.
vim.g.have_nerd_font = true

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
