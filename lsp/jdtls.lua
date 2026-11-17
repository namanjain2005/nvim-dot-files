-- Eclipse JDT Language Server. Install locally under ~/.local/share/jdtls.
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

local function find_java_home()
  local candidates = {
    -- This JDTLS distribution has Eclipse bundles requiring JavaSE-25.
    vim.fn.expand("~/.local/jdk-25"),
    vim.env.JAVA_HOME,
    vim.fn.expand("~/.local/jdk-21"),
  }
  for _, home in ipairs(candidates) do
    if home and home ~= "" and vim.fn.executable(home .. "/bin/java") == 1 then
      return home
    end
  end
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
    local java_home = find_java_home()
    local java = java_home and (java_home .. "/bin/java") or vim.fn.exepath("java")
    local launchers = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)
    local launcher = launchers[1]

    if java == "" or not launcher then
      error("JDTLS or its required Java runtime is missing; see ~/.config/nvim/lsp/jdtls.lua")
    end

    local root = config.root_dir or vim.fn.getcwd()
    -- Use a fresh index for the explicit source-root layout; keep old workspace data intact.
    local workspace_key = root .. "|source-paths-v1"
    local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.sha256(workspace_key)
    vim.fn.mkdir(workspace, "p")

    local cmd = {
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
      jdtls_dir .. "/config_linux",
      "-data",
      workspace,
    }

    local env = {}
    if java_home then
      env.JAVA_HOME = java_home
    end
    return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root, env = env })
  end,
  init_options = {
    bundles = {},
    extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
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
