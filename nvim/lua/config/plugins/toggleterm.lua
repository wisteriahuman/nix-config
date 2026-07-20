return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("toggleterm").setup({
        size = 18,
        open_mapping = [[<C-\>]],
        direction = "float",
        float_opts = {
          border = "single",
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>t1", "<cmd>ToggleTerm 1<CR>", { desc = "Terminal 1" })
      map("n", "<leader>t2", "<cmd>ToggleTerm 2<CR>", { desc = "Terminal 2" })
      map("n", "<leader>t3", "<cmd>ToggleTerm 3<CR>", { desc = "Terminal 3" })
    end,
  },
}
