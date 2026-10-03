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
              { icon = " ", key = "f", desc = "ファイル検索", action = ":lua Snacks.dashboard.pick('files')" },
              { icon = " ", key = "n", desc = "新規ファイル", action = ":ene | startinsert" },
              { icon = "󰠮 ", key = "m", desc = "メモ", action = ":lua require('config.memo').today()" },
              { icon = " ", key = "g", desc = "全文検索", action = ":lua Snacks.dashboard.pick('live_grep')" },
              { icon = " ", key = "r", desc = "最近のファイル", action = ":lua Snacks.dashboard.pick('oldfiles')" },
              { icon = " ", key = "c", desc = "設定", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
              { icon = " ", key = "s", desc = "セッション復元", section = "session" },
              { icon = "󰒲 ", key = "L", desc = "Lazy (プラグイン管理)", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
              { icon = " ", key = "q", desc = "終了", action = ":qa" },
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
      end, { desc = "次の同じ単語へ" })
      map("n", "[w", function()
        require("snacks").words.jump(-1)
      end, { desc = "前の同じ単語へ" })
      map("n", "<leader>nn", function()
        require("snacks").notifier.show_history()
      end, { desc = "通知履歴" })
      map("n", "<leader>nd", function()
        require("snacks").notifier.hide()
      end, { desc = "通知を消す" })
    end,
  },
}
