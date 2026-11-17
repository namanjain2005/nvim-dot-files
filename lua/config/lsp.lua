local lsp = vim.lsp

-- Capabilities merged into every server (0.11+ already sends a sane baseline).
lsp.config("*", {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
          documentationFormat = { "markdown", "plaintext" },
          resolveSupport = {
            properties = { "documentation", "detail", "additionalTextEdits" },
          },
        },
      },
      hover = { contentFormat = { "markdown", "plaintext" } },
      publishDiagnostics = { relatedInformation = true },
    },
  },
})

-- Enable a server only when it can actually run, so a fresh clone does not
-- produce spawn errors for tools that have not been installed yet.
local function enable_if(server, available)
  if available then
    lsp.enable(server)
  end
end

local function executable(name)
  return vim.fn.executable(name) == 1
end

enable_if("rust_analyzer", executable("rust-analyzer"))
enable_if("gopls", executable("gopls"))
enable_if("pyright", executable("pyright-langserver"))
-- JDTLS can be a bundle in ~/.local/share/jdtls or a `jdtls` executable.
local has_java = executable("java")
  or executable(vim.fn.expand("~/.local/jdk-25/bin/java"))
  or executable(vim.fn.expand("~/.local/jdk-21/bin/java"))
  or executable(vim.fn.expand("~/.local/jdk-17/bin/java"))
local has_jdtls = executable("jdtls")
  or vim.fn.isdirectory(vim.fn.expand("~/.local/share/jdtls")) == 1

if has_jdtls and has_java then
  -- Set this explicitly so plugins that also ship lsp/jdtls.lua (such as
  -- nvim-jdtls) cannot override the launcher below.
  lsp.config("jdtls", dofile(vim.fn.stdpath("config") .. "/lsp/jdtls.lua"))
  lsp.enable("jdtls")
end
-- gdscript is enabled on demand by config.gdscript (Godot must be running).
-- clangd is enabled on demand by config.clangd when the binary exists.

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/inlayHint", bufnr) then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client:supports_method("textDocument/completion", bufnr) then
      lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      vim.keymap.set("i", "<C-Space>", function()
        vim.lsp.completion.get()
      end, { buffer = bufnr, silent = true, desc = "Trigger LSP completion" })
    end

    -- Jump maps (buffer-local so non-LSP buffers keep Vim's builtin gd).
    local function bufmap(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
    local go_to_definition = vim.lsp.buf.definition
    if client.name == "jdtls" then
      go_to_definition = function()
        local source_buf = vim.api.nvim_get_current_buf()
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        client:request("textDocument/definition", params, function(err, result)
          if not vim.api.nvim_buf_is_valid(source_buf) then
            return
          end
          if err then
            vim.notify(err.message or "Java definition request failed", vim.log.levels.ERROR)
            return
          end
          if not result then
            vim.notify("No Java definition found", vim.log.levels.INFO)
            return
          end

          local locations = vim.islist(result) and result or { result }
          for _, location in ipairs(locations) do
            local uri = location.uri or location.targetUri
            if uri and uri:match("^jdt://") then
              vim.lsp.util.show_document(location, client.offset_encoding, { focus = true })
              return
            end
          end

          -- Keep Neovim's usual navigation for project files and other URI schemes.
          vim.lsp.buf.definition()
        end, source_buf)
      end
    end
    bufmap("gd", go_to_definition, "Go to definition")
    bufmap("gD", vim.lsp.buf.declaration, "Go to declaration")
    bufmap("gy", vim.lsp.buf.type_definition, "Go to type definition")
    bufmap("gI", vim.lsp.buf.implementation, "Go to implementation")
    bufmap("<C-]>", vim.lsp.buf.definition, "Go to definition")

    if client:supports_method("textDocument/documentHighlight", bufnr) then
      local group = vim.api.nvim_create_augroup("lsp_highlight_" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = bufnr,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = bufnr,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- Show the server name in :messages when it attaches.
    if vim.g.lsp_attach_notify then
      vim.notify(("LSP: %s attached"):format(client.name), vim.log.levels.DEBUG)
    end
  end,
})

vim.api.nvim_create_user_command("LspRestart", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local configs = {}
  for _, client in ipairs(lsp.get_clients({ bufnr = bufnr })) do
    configs[#configs + 1] = client.config
    client:stop()
  end
  if #configs == 0 then
    vim.notify("No LSP client attached", vim.log.levels.WARN)
    return
  end
  vim.defer_fn(function()
    for _, config in ipairs(configs) do
      lsp.start(config, { bufnr = bufnr })
    end
  end, 150)
end, { desc = "Restart LSP clients for the current buffer" })
