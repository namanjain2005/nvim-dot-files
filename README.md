# Neovim dotfiles

A zero-plugin Neovim configuration built around the LSP, completion, and
diagnostics support that ships with Neovim 0.11+.

## Install

```bash
# Back up an existing config first
mv ~/.config/nvim ~/.config/nvim.bak

git clone https://github.com/namanjain2005/nvim-dot-files.git ~/.config/nvim
```

Start Neovim with `nvim`. No plugin manager or `:PlugInstall` step is needed.

## Requirements

- **Neovim 0.11 or newer** (uses `vim.lsp.config`, `vim.lsp.enable`, and
  `vim.lsp.completion`).
- **A patched Nerd Font** is optional; the config does not require one.
- **Git** for the clone and for LSP project-root detection.

Language servers and formatters are optional. Each one is only enabled when
its executable is available.

| Language | Tool | Install |
| --- | --- | --- |
| Rust | `rust-analyzer` | `rustup component add rust-analyzer` |
| C / C++ / CUDA | `clangd` | distro package, or `conda install -c conda-forge clang-tools` |
| Go | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| Python | `pyright-langserver` | `npm install -g pyright` |
| Java | JDTLS bundle | unpack a snapshot into `~/.local/share/jdtls` |
| GDScript | Godot 4 editor LSP | open the project in the Godot editor |
| GDScript lint/format | `gdlint`, `gdformat` | `pipx install gdtoolkit` |

### Java/JDTLS

Either place a JDTLS bundle under `~/.local/share/jdtls` (the directory must
contain `plugins/org.eclipse.equinox.launcher_*.jar` and a `config_*`
directory), or install a `jdtls` launcher on `PATH`. A Java runtime is also
required; the config checks `JAVA_HOME`, `~/.local/jdk-25`, `~/.local/jdk-21`,
`~/.local/jdk-17`, and `java` on `PATH`.

### GDScript

Open the project in the Godot editor first. The editor exposes its language
server on `127.0.0.1:6005`, and this config connects automatically when that
port is reachable. Use `:GodotLsp` to retry, `:GdLint` / `:GdFormat` for the
current buffer, or the `<leader>g` mappings in `.gd` buffers.

## Structure

```
init.lua                     entry point
lua/config/options.lua       editor options
lua/config/keymaps.lua       global keymaps
lua/config/diagnostics.lua   diagnostic presentation
lua/config/completion.lua    debounced LSP auto-completion
lua/config/lsp.lua           shared LSP capabilities and enablement
lua/config/clangd.lua        clangd bootstrap + CUDA compile database
lua/config/gdscript.lua      Godot LSP, gdlint, gdformat
lsp/*.lua                    per-server vim.lsp.config definitions
after/ftplugin/*.lua         buffer-local settings for Rust, Java, GDScript
```

## Useful commands

- `:LspRestart` – restart LSP clients for the current buffer
- `:ClangdEnable` – enable clangd after installing it
- `:CudaCompileDb` – generate `compile_commands.json` for `.cu` files
- `:GodotLsp`, `:GdLint`, `:GdFormat` – GDScript helpers
- `:checkhealth vim.lsp` – inspect LSP setup
