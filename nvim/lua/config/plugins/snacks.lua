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
        dashboard = {
          enabled = true,
          preset = {
            keys = {
              { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
              { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
              { icon = "󰠮 ", key = "m", desc = "Memo", action = ":lua require('config.memo').today()" },
              { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
              { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
              { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
              { icon = " ", key = "s", desc = "Restore Session", section = "session" },
              { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
              { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
          },
        },
        input = { enabled = true },
        statuscolumn = { enabled = true },
        dim = { enabled = true },
        -- WezTerm は kitty の placeholder 非対応のため、インライン不可でフロート表示のみ
        image = {
          enabled = true,
          doc = { inline = false, float = true },
        },
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
