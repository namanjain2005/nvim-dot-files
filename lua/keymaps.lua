vim.g.mapleader = " "

vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Default LSP mappings
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to References" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
end, { desc = "Format Buffer" })

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = { buffer = ev.buf }

        vim.keymap.set("n", "gd",
            vim.lsp.buf.definition, opts)

        vim.keymap.set("n", "gr",
            vim.lsp.buf.references, opts)

        vim.keymap.set("n", "K",
            vim.lsp.buf.hover, opts)

        vim.keymap.set("n", "<leader>rn",
            vim.lsp.buf.rename, opts)

        vim.keymap.set("n", "<leader>ca",
            vim.lsp.buf.code_action, opts)

        vim.keymap.set("n", "<leader>f",
            function()
                vim.lsp.buf.format({ async = true })
            end, opts)
    end,
})