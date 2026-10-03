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
      map({ "n", "v" }, "<leader>tj", "<cmd>Translate JA<CR>", { desc = "日本語に翻訳" })
      map({ "n", "v" }, "<leader>te", "<cmd>Translate EN<CR>", { desc = "英語に翻訳" })
    end,
  },
}
