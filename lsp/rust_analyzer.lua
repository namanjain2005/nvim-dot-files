-- rust-analyzer (installed via rustup: rustup component add rust-analyzer)
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json" },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = false,
        buildScripts = { enable = true },
      },
      check = {
        command = "clippy",
        onSave = true,
      },
      checkOnSave = true, -- older rust-analyzer releases
      diagnostics = {
        enable = true,
        experimental = { enable = true },
      },
      inlayHints = {
        bindingModeHints = { enable = false },
        closureReturnTypeHints = { enable = "with_block" },
        discriminantHints = { enable = "never" },
        lifetimeElisionHints = { enable = "never" },
        parameterHints = { enable = true },
        typeHints = { enable = true },
        chainingHints = { enable = true },
      },
      completion = {
        callable = { snippets = "add_parentheses" },
        autoimport = { enable = true },
      },
      imports = {
        granularity = { group = "module" },
        prefix = "self",
      },
      procMacro = { enable = true },
      files = { excludeDirs = { "target", "vendor", ".git" } },
      rustfmt = { extraArgs = { "--edition", "2024" } },
    },
  },
}
