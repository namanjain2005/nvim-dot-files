-- Eclipse JDT Language Server.
-- Works with either a local bundle (~/.local/share/jdtls, the default) or a
-- `jdtls` executable on PATH. Install the bundle from
-- https://download.eclipse.org/jdtls/snapshots/ and unpack it under
-- ~/.local/share/jdtls, or install a `jdtls` launcher.
local jdtls_dir = vim.fn.expand("~/.local/share/jdtls")
local markers = {
  "pom.xml",
  "mvnw",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "gradlew",
  ".git",
}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function find_java_home()
  local candidates = {
    vim.fn.expand("~/.local/jdk-25"),
    vim.env.JAVA_HOME,
    vim.fn.expand("~/.local/jdk-21"),
    vim.fn.expand("~/.local/jdk-17"),
  }

  for _, home in ipairs(candidates) do
    if home and home ~= "" and executable(home .. "/bin/java") then
      return home
    end
  end

  -- Fall back to whatever java is on PATH.
  local java = vim.fn.exepath("java")
  if java ~= "" then
    return vim.fs.dirname(vim.fs.dirname(java))
  end
end

local function bundle_config_dir()
  local suffix = "linux"
  if vim.fn.has("mac") == 1 then
    suffix = "mac"
  elseif vim.fn.has("win32") == 1 then
    suffix = "win"
  end

  local candidates = {
    jdtls_dir .. "/config_" .. suffix,
    jdtls_dir .. "/config_" .. suffix .. "_arm",
  }
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return candidates[1]
end

local function project_root(bufnr)
  local root = vim.fs.root(bufnr, markers)
  if root then
    return root
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename ~= "" then
    return vim.fs.dirname(filename)
  end
  return vim.fn.getcwd()
end

return {
  filetypes = { "java" },
  root_dir = function(bufnr, on_dir)
    on_dir(project_root(bufnr))
  end,
  cmd = function(dispatchers, config)
    local root = config.root_dir or vim.fn.getcwd()
    local java_home = find_java_home()
    local java = java_home and (java_home .. "/bin/java") or vim.fn.exepath("java")
    local launchers = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)
    local launcher = launchers[1]

    local cmd
    if java ~= "" and launcher then
      -- Use a fresh index for the explicit source-root layout; keep old
      -- workspace data intact.
      local workspace_key = root .. "|source-paths-v1"
      local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.sha256(workspace_key)
      vim.fn.mkdir(workspace, "p")

      cmd = {
        java,
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Xmx1G",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        launcher,
        "-configuration",
        bundle_config_dir(),
        "-data",
        workspace,
      }
    elseif executable("jdtls") then
      cmd = { "jdtls" }
    else
      error("JDTLS not found: install it under ~/.local/share/jdtls or add `jdtls` to PATH")
    end

    local env = {}
    if java_home then
      env.JAVA_HOME = java_home
    end
    return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root, env = env })
  end,
  init_options = {
    bundles = {},
  },
  settings = {
    java = {
      project = { sourcePaths = { "." } },
      configuration = { updateBuildConfiguration = "interactive" },
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      references = { includeDecompiledSources = true },
      format = { enabled = true },
    },
  },
}
