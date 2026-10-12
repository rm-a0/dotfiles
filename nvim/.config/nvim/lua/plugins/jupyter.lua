-- Jupyter notebooks: .ipynb opens as a Python buffer with "# %%" cell markers
-- (jupytext), cells run in a real Jupyter kernel (molten), and plots render
-- inline in kitty (image.nvim).
--
-- Python side lives in its own venv so system Python stays untouched;
-- install.sh's jupyter_phase creates it (pynvim, jupyter_client, ipykernel,
-- nbformat) and puts jupytext on PATH. --system-site-packages: the kernel
-- then sees apt's numpy/scipy/matplotlib.

local venv = vim.fn.stdpath("data") .. "/jupyter-venv"

-- Cell = lines between "# %%" markers around the cursor.
local function cell_range()
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local first, last = 1, #lines
    for i = cur, 1, -1 do
        if lines[i]:match("^# %%%%") then
            first = i + 1
            break
        end
    end
    for i = cur + 1, #lines do
        if lines[i]:match("^# %%%%") then
            last = i - 1
            break
        end
    end
    return first, last
end

-- Markdown/raw cells are "# %% [markdown]" / "# %% [raw]".
local function is_code_cell(header)
    return header:match("^# %%%%") and not header:match("^# %%%% %[")
end

local function run_cell()
    local first, last = cell_range()
    if first <= last then
        vim.fn.MoltenEvaluateRange(first, last)
    end
end

local function run_all()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local starts = {}
    for i, line in ipairs(lines) do
        if is_code_cell(line) then
            table.insert(starts, i)
        end
    end
    for _, start in ipairs(starts) do
        -- A code cell ends at the next marker of any kind.
        local last = #lines
        for i = start + 1, #lines do
            if lines[i]:match("^# %%%%") then
                last = i - 1
                break
            end
        end
        if start + 1 <= last then
            vim.fn.MoltenEvaluateRange(start + 1, last)
        end
    end
end

-- Start the notebook's own kernel and show the outputs saved in the file.
local function init_notebook(file)
    vim.schedule(function()
        local ok, nb = pcall(function()
            return vim.json.decode(io.open(file, "r"):read("a"))
        end)
        local kernel = ok and nb.metadata and nb.metadata.kernelspec and nb.metadata.kernelspec.name
        if not vim.tbl_contains(vim.fn.MoltenAvailableKernels(), kernel) then
            kernel = "python3"
        end
        vim.cmd("MoltenInit " .. kernel)
        vim.cmd("MoltenImportOutput")
    end)
end

return {
    {
        "3rd/image.nvim",
        -- Its rockspec makes lazy try luarocks (not installed); magick_cli
        -- below needs no rock, so skip the build.
        build = false,
        opts = {
            backend = "kitty",
            processor = "magick_cli",
            max_width = 100,
            max_height = 12,
            max_height_window_percentage = math.huge,
            max_width_window_percentage = math.huge,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        },
    },

    {
        "GCBallesteros/jupytext.nvim",
        lazy = false, -- must hook BufReadCmd before the first .ipynb opens
        opts = { style = "percent", output_extension = "auto", force_ft = "python" },
    },

    {
        "benlubas/molten-nvim",
        -- main, not the ^1 tag: v1.9.2 predates fixes needed on Nvim 0.12
        -- (e.g. remove_comments.lua 'region' nil crash, fixed in 24f6e16).
        lazy = false, -- the autocmds below need its commands at startup
        dependencies = { "3rd/image.nvim" },
        -- Remote (Python) plugin: its commands appear only after this.
        build = ":UpdateRemotePlugins",
        init = function()
            vim.g.python3_host_prog = venv .. "/bin/python"
            -- molten writes kernel connection files to <jupyter data>/runtime
            -- (hard-coded) but never creates it; without it MoltenInit fails
            -- with ENOENT on a machine where Jupyter itself never ran.
            vim.fn.mkdir(vim.fn.fnamemodify(vim.fn.stdpath("data"), ":h") .. "/jupyter/runtime", "p")
            vim.g.molten_image_provider = "image.nvim"
            vim.g.molten_output_win_max_height = 20
            vim.g.molten_wrap_output = true
            -- Text output as virtual lines under the cell; images open in
            -- the float when the cursor enters a cell (<leader>jo forces it).
            vim.g.molten_virt_text_output = true
            vim.g.molten_virt_lines_off_by_1 = true

            local group = vim.api.nvim_create_augroup("rice-jupyter", { clear = true })

            -- BufAdd for :e from inside nvim; BufAdd skips files given on the
            -- command line, so `nvim file.ipynb` needs the BufEnter one.
            vim.api.nvim_create_autocmd("BufAdd", {
                group = group,
                pattern = "*.ipynb",
                callback = function(e)
                    init_notebook(e.file)
                end,
            })
            vim.api.nvim_create_autocmd("BufEnter", {
                group = group,
                pattern = "*.ipynb",
                callback = function(e)
                    if vim.v.vim_did_enter ~= 1 then
                        init_notebook(e.file)
                    end
                end,
            })

            -- No MoltenExportOutput on save: it rebuilds outputs from molten's
            -- own state and drops imported print/stream output. jupytext's
            -- --update already keeps the file's saved outputs; outputs made
            -- here stay in nvim.
        end,
        keys = {
            { "<leader>ji", "<cmd>MoltenInit python3<CR>", desc = "[J]upyter [I]nit kernel" },
            { "<leader>jr", run_cell, desc = "[J]upyter [R]un cell" },
            { "<leader>ja", run_all, desc = "[J]upyter run [A]ll cells" },
            { "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv<Esc>", mode = "v", desc = "[J]upyter [R]un selection" },
            { "<leader>jo", "<cmd>noautocmd MoltenEnterOutput<CR>", desc = "[J]upyter [O]utput window" },
            { "<leader>jh", "<cmd>MoltenHideOutput<CR>", desc = "[J]upyter [H]ide output" },
            { "<leader>jx", "<cmd>MoltenInterrupt<CR>", desc = "[J]upyter interrupt" },
            { "<leader>jR", "<cmd>MoltenRestart!<CR>", desc = "[J]upyter [R]estart kernel" },
        },
    },
}
