return {
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    config = function()
      require("diffview").setup()

      local map = vim.keymap.set
      map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Diffview を開く" })
      map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Diffview を閉じる" })
      map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "このファイルの履歴" })
    end,
  },
}
