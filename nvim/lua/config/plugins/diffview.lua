return {
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    config = function()
      require("diffview").setup()

      local map = vim.keymap.set
      map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
      map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
      map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File History" })
    end,
  },
}
