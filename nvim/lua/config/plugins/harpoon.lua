return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      local map = vim.keymap.set
      map("n", "<leader>ha", function()
        harpoon:list():add()
      end, { desc = "Harpoon Add" })
      map("n", "<leader>hh", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon Menu" })
      map("n", "<leader>1", function()
        harpoon:list():select(1)
      end, { desc = "Harpoon 1" })
      map("n", "<leader>2", function()
        harpoon:list():select(2)
      end, { desc = "Harpoon 2" })
      map("n", "<leader>3", function()
        harpoon:list():select(3)
      end, { desc = "Harpoon 3" })
      map("n", "<leader>4", function()
        harpoon:list():select(4)
      end, { desc = "Harpoon 4" })
    end,
  },
}
