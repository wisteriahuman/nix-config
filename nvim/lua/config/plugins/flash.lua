return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    config = function()
      require("flash").setup()

      local map = vim.keymap.set
      map({ "n", "x", "o" }, "s", function()
        require("flash").jump()
      end, { desc = "Flash Jump" })
      map({ "n", "x", "o" }, "S", function()
        require("flash").treesitter()
      end, { desc = "Flash Treesitter" })
    end,
  },
}
