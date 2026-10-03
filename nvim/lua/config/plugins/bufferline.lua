-- separator_style/indicator は config/theme.lua がテーマごとに setup() し直す。
-- ここでは base の見た目とキーマップだけを持つ。
return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local map = vim.keymap.set
      map("n", "<A-,>", "<cmd>BufferLineCyclePrev<CR>", { desc = "前のバッファ" })
      map("n", "<A-.>", "<cmd>BufferLineCycleNext<CR>", { desc = "次のバッファ" })
      map("n", "<A-c>", "<cmd>BufferLinePickClose<CR>", { desc = "バッファを閉じる" })
      for i = 1, 9 do
        map("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "バッファへ移動 " .. i })
      end
    end,
  },
}
