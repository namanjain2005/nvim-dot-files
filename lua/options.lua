vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.termguicolors = true
vim.opt.mouse = "a"

vim.opt.clipboard = "unnamedplus"
vim.opt.signcolumn = "yes"
vim.opt.completeopt = {
    "menu",
    "menuone",
    "noselect",
}

vim.opt.completeopt = {
    "menu",
    "menuone",
    "noselect",
    "popup",
}

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})