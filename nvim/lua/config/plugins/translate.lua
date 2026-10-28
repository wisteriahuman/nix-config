local translate_code = require("config.translate_code")

return {
  {
    "uga-rosa/translate.nvim",
    event = "VeryLazy",
    config = function()
      vim.g.deepl_api_auth_key = vim.fn.getenv("DEEPL_API_KEY")
      require("translate").setup({
        default = {
          parse_before = "trim,split_case,natural",
          command = "deepl_free",
        },
        parse_before = {
          split_case = translate_code.split_case,
          code = translate_code.code,
        },
        preset = {
          output = {
            floating = {
              -- ホバー (zindex=50) より手前に翻訳結果を表示する。
              zindex = 80,
            },
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
      map("n", "<leader>tc", "<cmd>Translate JA -parse_before=trim,code<CR>", { desc = "コードを日本語に翻訳" })
      map("x", "<leader>tc", ":Translate JA -parse_before=trim,code<CR>", { desc = "コードを日本語に翻訳" })
    end,
  },
}
