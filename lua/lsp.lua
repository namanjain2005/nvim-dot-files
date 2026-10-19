vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },

    filetypes = { "rust" },

    root_markers = {
        "Cargo.toml",
        "rust-project.json",
        ".git",
    },

    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },

            check = {
                command = "clippy",
            },

            procMacro = {
                enable = true,
            },
        },
    },
})

vim.lsp.enable("rust_analyzer")
local completion_timer = {}

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if not client then
            return
        end

        if not client:supports_method("textDocument/completion") then
            return
        end

        vim.lsp.completion.enable(
            true,
            client.id,
            args.buf,
            {
                autotrigger = true,
            }
        )

        -- Trigger completion after a short pause
        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
            buffer = args.buf,

            callback = function()
                -- Cancel previous timer
                if completion_timer[args.buf] then
                    completion_timer[args.buf]:stop()
                    completion_timer[args.buf]:close()
                end

                local timer = vim.uv.new_timer()
                completion_timer[args.buf] = timer

                timer:start(300, 0, vim.schedule_wrap(function()
                    if not vim.api.nvim_buf_is_valid(args.buf) then
                        return
                    end

                    if vim.api.nvim_get_mode().mode ~= "i" then
                        return
                    end

                    -- Don't interrupt an existing completion menu
                    if vim.fn.pumvisible() == 1 then
                        return
                    end

                    vim.lsp.completion.get()
                end))
            end,
        })
    end,
})

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--completion-style=detailed",
    },

    filetypes = {
        "c",
        "cpp",
        "cuda",
    },

    root_markers = {
        "compile_commands.json",
        "compile_flags.txt",
        ".git",
    },
})

vim.lsp.enable("clangd")

vim.filetype.add({
    extension = {
        cu = "cuda",
        cuh = "cuda",
    },
})

local jdtls_dir = vim.fn.expand("~/AppData/Local/jdtls")
local java_bin = "C:/Program Files/Eclipse Adoptium/jdk-25.0.2.10-hotspot/bin/java.exe"
if vim.fn.filereadable(java_bin) == 0 then
    java_bin = "java"
end

vim.lsp.config("jdtls", {
    cmd = {
        "python",
        jdtls_dir .. "/bin/jdtls",
        "--java-executable",
        java_bin,
    },

    filetypes = { "java" },

    root_markers = {
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "settings.gradle",
        "settings.gradle.kts",
        ".git",
    },

    settings = {
        java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
            completion = {
                favoriteStaticMembers = {
                    "org.junit.Assert.*",
                    "org.junit.Assume.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "org.junit.jupiter.api.Assumptions.*",
                    "org.junit.jupiter.api.DynamicContainer.*",
                    "org.junit.jupiter.api.DynamicTest.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                },
            },
        },
    },
})

vim.lsp.enable("jdtls")