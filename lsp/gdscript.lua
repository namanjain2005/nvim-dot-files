-- Godot 4 editor ships an LSP server on tcp 127.0.0.1:6005.
-- Open the project in the Godot editor (Editor > Editor Settings > Network >
-- Language Server) and this connects automatically. config.gdscript only
-- enables it when the port is actually reachable.
return {
  cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
  filetypes = { "gdscript" },
  root_markers = { "project.godot", ".git" },
}
