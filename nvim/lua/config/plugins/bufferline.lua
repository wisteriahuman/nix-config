-- separator_style/indicator は config/theme.lua がテーマごとに setup() し直す。
-- ここでは base の見た目とキーマップだけを持つ。
return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local map = vim.keymap.set
      map("n", "<A-,>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Buffer" })
      map("n", "<A-.>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Buffer" })
      map("n", "<A-c>", "<cmd>BufferLinePickClose<CR>", { desc = "Close Buffer" })
    end,
  },
}
