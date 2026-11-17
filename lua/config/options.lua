local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.splitright = true
opt.splitbelow = true
opt.pumheight = 12
opt.pumblend = 10
opt.winblend = 0
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.shortmess:append("I")

-- Timing
opt.updatetime = 250
opt.timeoutlen = 400

-- Editing
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.shiftround = true
opt.smartindent = true
opt.mouse = "a"
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.confirm = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false

-- Completion (fed by vim.lsp.completion)
opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- Over SSH, send yanks through the terminal using OSC 52 so they reach the
-- local machine's clipboard without needing a remote clipboard executable.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.g.clipboard = "osc52"
  opt.clipboard = "unnamedplus"
-- Locally, use a clipboard provider only when one is installed.
elseif vim.fn.executable("wl-copy") == 1 or vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1 then
  opt.clipboard = "unnamedplus"
end

-- Folds are handled by the LSP/treesitter when available; keep them manual.
opt.foldlevel = 99
opt.foldlevelstart = 99

-- 100-column ruler only for Rust/GDScript (colorcolumn is window-local, so it
-- has to be refreshed whenever a buffer is shown).
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("config_colorcolumn", { clear = true }),
  callback = function()
    local ft = vim.bo.filetype
    vim.wo.colorcolumn = (ft == "rust" or ft == "gdscript") and "100" or ""
  end,
})
