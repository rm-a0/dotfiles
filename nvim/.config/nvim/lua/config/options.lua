-- `:help option-list`

local opt = vim.opt

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.breakindent = true

-- Line numbers
opt.number = true
opt.relativenumber = true

opt.mouse = "a"
opt.showmode = false -- the statusline already shows it

-- Share the system clipboard. Under Wayland this goes through wl-clipboard.
opt.clipboard = "unnamedplus"

opt.undofile = true

-- Case-insensitive search unless the pattern contains a capital or \C
opt.ignorecase = true
opt.smartcase = true

opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300 -- also how soon which-key appears

opt.splitright = true
opt.splitbelow = true

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.inccommand = "split" -- live preview of :substitute
opt.cursorline = true
opt.scrolloff = 10
opt.hlsearch = true
