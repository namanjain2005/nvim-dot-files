-- ~/.config/nvim/init.lua
-- Zero-plugin setup: built-in LSP, completion and diagnostics (Neovim 0.11+).
-- Rust  -> rust-analyzer + rustfmt/clippy + cargo :make targets
-- Java  -> Eclipse JDT Language Server
-- GDScript -> Godot editor LSP (tcp 127.0.0.1:6005) + gdlint/gdformat when installed

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.lsp")
require("config.completion").setup()
require("config.clangd").setup()
require("config.gdscript").setup()

-- .gd is detected by Neovim's runtime; these cover the project files on
-- versions that do not know them yet.
vim.filetype.add({
  extension = {
    gd = "gdscript",
    gdshader = "gdshader",
    cu = "cuda",
    cuh = "cuda",
  },
})
