return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("snacks").setup({
        notifier = { enabled = true },
        quickfile = { enabled = true },
        bigfile = { enabled = true },
        words = { enabled = true },
        scroll = {
          enabled = true,
          animate = {
            duration = { step = 8, total = 150 },
            easing = "linear",
          },
        },
        indent = {
          enabled = true,
          animate = { enabled = true },
          scope = { enabled = true },
        },
        dashboard = { enabled = true },
        input = { enabled = true },
        statuscolumn = { enabled = true },
        dim = { enabled = true },
      })

      local map = vim.keymap.set
      map("n", "]w", function()
        require("snacks").words.jump(1)
      end, { desc = "Next Word Occurrence" })
      map("n", "[w", function()
        require("snacks").words.jump(-1)
      end, { desc = "Prev Word Occurrence" })
      map("n", "<leader>nn", function()
        require("snacks").notifier.show_history()
      end, { desc = "Notification History" })
      map("n", "<leader>nd", function()
        require("snacks").notifier.hide()
      end, { desc = "Dismiss Notifications" })
    end,
  },
}
