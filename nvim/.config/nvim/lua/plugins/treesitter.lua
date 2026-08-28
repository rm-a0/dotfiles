-- Syntax highlighting and indentation.
--
-- main, not master: master is locked at Nvim 0.11, and its markdown
-- injections use a #set-lang-from-info-string! directive that 0.12 cannot
-- resolve, so every fenced code block throws. main installs parsers and
-- nothing else, so highlight and indent start per buffer below.
--
-- Needs tree-sitter CLI >= 0.26.1 on PATH; trixie ships 0.22.

-- No jsonc: main ships none, and the jsonc filetype maps to json.
local parsers = {
    "bash", "c", "cpp", "css", "diff", "dockerfile", "go", "html",
    "javascript", "json", "lua", "luadoc", "make",
    "markdown", "markdown_inline", "php", "python", "rust", "toml",
    "vim", "vimdoc", "yaml",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup()

            -- No zsh grammar exists; bash is close enough.
            vim.treesitter.language.register("bash", "zsh")

            -- install() is async and skips what is already present.
            require("nvim-treesitter").install(parsers)

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("rice-treesitter", { clear = true }),
                callback = function(event)
                    local ft = vim.bo[event.buf].filetype
                    local lang = vim.treesitter.language.get_lang(ft)
                    if not lang then
                        return
                    end

                    -- start() throws when the parser is missing;
                    -- language.add() returns success there, so it cannot guard.
                    if not pcall(vim.treesitter.start, event.buf, lang) then
                        return
                    end

                    -- ruby: indent rules need vim's regex highlighting.
                    -- python: main-branch TS indent over-indents (8 after a
                    -- newline); the stock indent/python.vim is better.
                    local stock_indent = { ruby = true, python = true }
                    if not stock_indent[ft] then
                        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
