return {
  {
    "uga-rosa/translate.nvim",
    event = "VeryLazy",
    config = function()
      vim.g.deepl_api_auth_key = vim.fn.getenv("DEEPL_API_KEY")
      require("translate").setup({
        default = {
          command = "deepl_free",
        },
        preset = {
          output = {
            split = {
              append = true,
            },
          },
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>tj", "<cmd>Translate JA<CR>", { desc = "日本語に翻訳" })
      map("n", "<leader>te", "<cmd>Translate EN<CR>", { desc = "英語に翻訳" })
      -- <cmd> だと移動なしの V で選択範囲を取り損ねる
      map("x", "<leader>tj", ":Translate JA<CR>", { desc = "日本語に翻訳" })
      map("x", "<leader>te", ":Translate EN<CR>", { desc = "英語に翻訳" })
    end,
  },
}
