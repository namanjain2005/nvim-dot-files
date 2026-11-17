-- clangd bootstrap + CUDA compile database generation.
--
-- clangd is only enabled when the binary exists, so opening .cu files without
-- it installed does not produce spawn errors. :ClangdEnable picks it up after
-- installation without restarting Neovim.
local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function project_root()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.fn.getcwd()
  end
  return vim.fs.root(start, { "build.rs", "Cargo.toml", "CMakeLists.txt", ".git" }) or vim.fn.getcwd()
end

--- Write a compile_commands.json covering the project's .cu files so clangd
--- resolves CUTLASS headers (including the build.rs-generated overlay).
function M.write_compile_db()
  local root = project_root()
  local nvcc = vim.fn.exepath("nvcc")
  if nvcc == "" then
    for _, candidate in ipairs({
      "/usr/local/cuda-12.4/bin/nvcc",
      "/usr/local/cuda/bin/nvcc",
      "/usr/local/cuda-12/bin/nvcc",
    }) do
      if executable(candidate) then
        nvcc = candidate
        break
      end
    end
  end
  if nvcc == "" or not executable(nvcc) then
    vim.notify("CudaCompileDb: nvcc not found", vim.log.levels.ERROR)
    return
  end

  local includes = {}
  local seen = {}
  local function add_include(path)
    if path and not seen[path] and vim.uv.fs_stat(path) then
      seen[path] = true
      includes[#includes + 1] = path
    end
  end

  local cuda_root = vim.fs.dirname(vim.fs.dirname(nvcc))
  add_include(cuda_root .. "/include")
  add_include(root .. "/vendor/cutlass/include")
  add_include(root .. "/vendor/cutlass/examples/41_fused_multi_head_attention")
  add_include(root .. "/vendor/cutlass/tools/util/include")
  for _, dir in ipairs(vim.fn.glob(root .. "/target/*/build/*/out/cutlass-overlay", false, true)) do
    add_include(dir)
  end

  local sources = {}
  for _, file in ipairs(vim.fn.glob(root .. "/**/*.cu", false, true)) do
    local relative = file:sub(#root + 2)
    local generated = relative:match("^%.git/")
      or relative:match("^target/")
      or relative:match("^vendor/")
    if not generated then
      sources[#sources + 1] = file
    end
  end
  table.sort(sources)
  if #sources == 0 then
    vim.notify("CudaCompileDb: no project .cu files under " .. root, vim.log.levels.WARN)
    return
  end

  local db = {}
  for _, file in ipairs(sources) do
    local args = { nvcc, "-std=c++17", "--cuda-gpu-arch=sm_70", "-x", "cuda" }
    for _, inc in ipairs(includes) do
      args[#args + 1] = "-I" .. inc
    end
    vim.list_extend(args, { "-c", file, "-o", "/dev/null" })
    db[#db + 1] = { directory = root, file = file, arguments = args }
  end

  local path = root .. "/compile_commands.json"
  vim.fn.writefile({ vim.json.encode(db) }, path)
  vim.notify(("CudaCompileDb: wrote %d entries to %s"):format(#db, path), vim.log.levels.INFO)
end

function M.setup()
  if executable("clangd") then
    vim.lsp.enable("clangd")
  end

  vim.api.nvim_create_user_command("ClangdEnable", function()
    if not executable("clangd") then
      vim.notify(
        "clangd not found: install it (apt install clangd, or conda install -c conda-forge clang-tools)",
        vim.log.levels.ERROR
      )
      return
    end
    vim.lsp.enable("clangd")
    vim.notify("clangd enabled for C/C++/CUDA buffers")
  end, { desc = "Enable clangd for C/C++/CUDA" })

  vim.api.nvim_create_user_command("CudaCompileDb", function()
    M.write_compile_db()
  end, { desc = "Generate compile_commands.json for the project's .cu files" })
end

return M
