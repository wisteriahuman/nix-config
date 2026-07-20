return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 2,
          max_width = 80,
          max_height = 30,
        },
      })

      vim.keymap.set("n", "-", "<cmd>Oil --float<CR>", { desc = "Open Oil (float)" })
    end,
  },
}
