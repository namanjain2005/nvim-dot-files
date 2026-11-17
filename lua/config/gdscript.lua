-- GDScript support.
--   * LSP  : connects to the Godot editor's language server (tcp 6005).
--   * lint : gdlint from gdtoolkit, merged into the same diagnostic list.
--   * fmt  : gdformat on save, only when installed.
local M = {}

local HOST, PORT = "127.0.0.1", 6005
local ns = vim.api.nvim_create_namespace("gdlint")
local lsp_warned = false

local function executable(name)
  return vim.fn.executable(name) == 1
end

--- Call cb(true) if something is listening on host:port, cb(false) otherwise.
local function port_open(host, port, timeout_ms, cb)
  -- `ss` checks the listen table without opening a throwaway connection, which
  -- matters because Godot's LSP accepts a single client at a time.
  if host == "127.0.0.1" and vim.fn.executable("ss") == 1 then
    local out = vim.fn.system({ "ss", "-Hltn", ("sport = :%d"):format(port) })
    local listening = vim.v.shell_error == 0 and out:find((":%d"):format(port), 1, true) ~= nil
    vim.schedule(function()
      cb(listening)
    end)
    return
  end

  local uv = vim.uv or vim.loop
  local tcp = uv.new_tcp()
  local timer = uv.new_timer()
  local done = false

  local function finish(ok)
    if done then
      return
    end
    done = true
    timer:stop()
    timer:close()
    tcp:close()
    vim.schedule(function()
      cb(ok)
    end)
  end

  timer:start(timeout_ms, 0, function()
    finish(false)
  end)
  tcp:connect(host, port, function(err)
    finish(err == nil)
  end)
end

local function start_lsp(bufnr)
  local config = vim.lsp.config["gdscript"]
  if not config then
    return
  end
  local root = vim.fs.root(bufnr, { "project.godot", ".git" }) or vim.fn.getcwd()
  config = vim.tbl_deep_extend("force", {}, config, { root_dir = root })
  vim.lsp.start(config, { bufnr = bufnr })
end

--- Connect the current (or given) buffer to Godot's LSP, retrying on demand.
function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "gdscript" then
    vim.notify("Not a gdscript buffer", vim.log.levels.WARN)
    return
  end
  port_open(HOST, PORT, 200, function(open)
    if not open then
      vim.notify(
        ("GDScript LSP: nothing listening on %s:%d - open the project in the Godot editor first"):format(HOST, PORT),
        vim.log.levels.ERROR
      )
      return
    end
    vim.lsp.enable("gdscript")
    start_lsp(bufnr)
  end)
end

-- ---------------------------------------------------------------------------
-- gdlint
-- ---------------------------------------------------------------------------
local function parse_gdlint(output)
  local diagnostics = {}
  for line in output:gmatch("[^\r\n]+") do
    local _, lnum, severity, message = line:match("^(.-):(%d+):%s*(%a+):%s*(.+)$")
    if lnum then
      local rule = message:match("%s*%(([%w%-_]+)%)%s*$")
      if rule then
        message = message:gsub("%s*%([%w%-_]+%)%s*$", "")
      end
      local level = severity:lower()
      local diag_severity = vim.diagnostic.severity.INFO
      if level:find("error", 1, true) then
        diag_severity = vim.diagnostic.severity.ERROR
      elseif level:find("warn", 1, true) then
        diag_severity = vim.diagnostic.severity.WARN
      end
      diagnostics[#diagnostics + 1] = {
        lnum = math.max(tonumber(lnum) - 1, 0),
        col = 0,
        message = message,
        severity = diag_severity,
        source = "gdlint",
        code = rule,
      }
    end
  end
  return diagnostics
end

function M.lint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not executable("gdlint") then
    vim.notify_once("gdlint not found (pipx install gdtoolkit)", vim.log.levels.WARN)
    return
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.bo[bufnr].modified then
    return
  end
  vim.system({ "gdlint", name }, { text = true }, function(out)
    local diagnostics = parse_gdlint((out.stdout or "") .. "\n" .. (out.stderr or ""))
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.set(ns, bufnr, diagnostics)
      end
    end)
  end)
end

-- ---------------------------------------------------------------------------
-- gdformat
-- ---------------------------------------------------------------------------
function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not executable("gdformat") then
    vim.notify_once("gdformat not found (pipx install gdtoolkit)", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out = vim.system({ "gdformat", "-" }, {
    stdin = table.concat(lines, "\n") .. "\n",
    text = true,
  }):wait(3000)

  if out.code ~= 0 then
    vim.notify("gdformat failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split(out.stdout or "", "\n", { plain = true })
  if formatted[#formatted] == "" then
    table.remove(formatted)
  end
  if vim.deep_equal(lines, formatted) then
    return
  end

  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  vim.fn.winrestview(view)
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------
function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function(args)
      local buf = args.buf
      if vim.b[buf].gd_lsp_checked then
        return
      end
      vim.b[buf].gd_lsp_checked = true
      port_open(HOST, PORT, 200, function(open)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        if open then
          vim.lsp.enable("gdscript")
          start_lsp(buf)
        elseif not lsp_warned then
          lsp_warned = true
          vim.notify(
            ("GDScript LSP: Godot editor not running on %s:%d; run :GodotLsp once it is"):format(HOST, PORT),
            vim.log.levels.INFO
          )
        end
      end)
    end,
  })

  -- gdlint diagnostics after every write (and for an untouched buffer on enter).
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = "*.gd",
    callback = function(args)
      M.lint(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*.gd",
    callback = function(args)
      if not vim.bo[args.buf].modified then
        M.lint(args.buf)
      end
    end,
  })

  vim.api.nvim_create_user_command("GodotLsp", function()
    M.attach(0)
  end, { desc = "Connect the current GDScript buffer to the Godot editor LSP" })

  vim.api.nvim_create_user_command("GdLint", function()
    M.lint(0)
  end, { desc = "Run gdlint on the current buffer" })

  vim.api.nvim_create_user_command("GdFormat", function()
    M.format(0)
  end, { desc = "Run gdformat on the current buffer" })
end

return M
