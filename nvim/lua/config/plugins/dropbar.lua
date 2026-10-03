return {
  {
    "Bekaboo/dropbar.nvim",
    event = "BufRead",
    config = function()
      require("dropbar").setup({})

      vim.keymap.set("n", "<leader>dp", function()
        require("dropbar.api").pick()
      end, { desc = "パンくずから選ぶ" })
    end,
  },
}
