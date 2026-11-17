-- clangd: C, C++ and CUDA (.cu/.cuh).
-- clangd uses its embedded Clang frontend for CUDA. Do not query nvcc: clangd's
-- include probe passes `-x cuda`, which nvcc rejects. The generated compile
-- database adds the CUDA include directory explicitly; GCC drivers provide
-- host standard-library paths for ordinary C/C++ files.
local drivers = {}
local seen = {}

local function add_driver(path)
  if path and path ~= "" and not seen[path] and vim.uv.fs_stat(path) then
    seen[path] = true
    drivers[#drivers + 1] = path
  end
end

for _, name in ipairs({ "clang", "clang++", "gcc", "g++", "cc", "c++" }) do
  add_driver(vim.fn.exepath(name))
end

local cmd = {
  "clangd",
  "--background-index",
  "--clang-tidy",
  "--header-insertion=never",
  "--completion-style=detailed",
}

if #drivers > 0 then
  cmd[#cmd + 1] = "--query-driver=" .. table.concat(drivers, ",")
end

return {
  cmd = cmd,
  filetypes = { "c", "cpp", "cuda" },
  root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", "Makefile", "build.rs", ".git" },
}
