-- Catppuccin Mocha, matching the rest of the rice.

return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000, -- load before everything else

        opts = {
            flavour = "mocha",


            -- kitty is translucent; an opaque bg would punch through it.
            transparent_background = true,
            integrations = {
                cmp = true,
                gitsigns = true,
                treesitter = true,
                telescope = { enabled = true },
                neotree = true,
                which_key = true,
                mini = { enabled = true },
                native_lsp = { enabled = true },
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin-mocha")
            vim.cmd.hi("Comment gui=none")
        end,
    },
}
