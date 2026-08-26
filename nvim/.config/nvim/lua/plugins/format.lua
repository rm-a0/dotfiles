-- Formatting on save, with an explicit <leader>f for manual runs.

return {
    {
        "stevearc/conform.nvim",
        lazy = false,

        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = "",
                desc = "[F]ormat buffer",
            },
        },
        opts = {
            -- Was false, which is how the broken vim.text.diff call above went
            -- unnoticed -- formatting simply did nothing on every save with no
            -- indication why. Failures should be visible.
            notify_on_error = true,
            format_on_save = function(bufnr)
                -- C/C++ have no single agreed style, so leave them alone
                -- rather than reformatting to whatever the LSP prefers.
                local disable_filetypes = { c = true, cpp = true }
                return {
                    timeout_ms = 500,
                    lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
            },
        },
    },
}
