return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      local wisteria = require("wisteria")
      wisteria.setup()

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
          width = 54,
          preset = {
            keys = {
              {
                icon = "󰍉 ",
                key = "f",
                desc = "ファイル検索",
                action = ":lua Snacks.dashboard.pick('files')",
              },
              { icon = "󰝒 ", key = "n", desc = "新規ファイル", action = ":ene | startinsert" },
              { icon = "󰠮 ", key = "m", desc = "メモ", action = ":lua require('config.memo').today()" },
              { icon = "󱎸 ", key = "g", desc = "全文検索", action = ":lua Snacks.dashboard.pick('live_grep')" },
              {
                icon = "󰋚 ",
                key = "r",
                desc = "最近のファイル",
                action = ":lua Snacks.dashboard.pick('oldfiles')",
              },
              {
                icon = "󰒓 ",
                key = "c",
                desc = "設定",
                action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
              },
              { icon = "󰦛 ", key = "s", desc = "セッション復元", section = "session" },
              {
                icon = "󰒲 ",
                key = "L",
                desc = "プラグイン管理",
                action = ":Lazy",
                enabled = package.loaded.lazy ~= nil,
              },
              { icon = "󰍃 ", key = "q", desc = "終了", action = ":qa" },
            },
          },
          sections = {
            wisteria.spacer,
            { section = "header", padding = 1 },
            { section = "keys", padding = 1 },
            { pane = 2, wisteria.spacer },
            {
              pane = 2,
              icon = "󰈙 ",
              title = "最近のファイル",
              section = "recent_files",
              indent = 2,
              padding = 1,
            },
            { pane = 2, icon = "󰉋 ", title = "プロジェクト", section = "projects", indent = 2, padding = 1 },
            { section = "startup" },
          },
        },
        input = { enabled = true },
        statuscolumn = { enabled = true },
        dim = { enabled = true },
      })

      local map = vim.keymap.set
      map("n", "<leader>h", function()
        if vim.bo.filetype ~= "snacks_dashboard" then
          require("snacks").dashboard.open()
        end
      end, { desc = "タイトル画面" })

      -- 最後のファイルを閉じたら [No Name] ではなくタイトル画面に戻る
      vim.api.nvim_create_autocmd("BufDelete", {
        callback = function(ev)
          if ev.file == "" or vim.bo[ev.buf].buftype ~= "" then
            return
          end
          vim.schedule(function()
            local cur = vim.api.nvim_get_current_buf()
            local empty = vim.api.nvim_buf_get_name(cur) == ""
              and vim.bo[cur].buftype == ""
              and not vim.bo[cur].modified
              and vim.api.nvim_buf_line_count(cur) == 1
              and vim.api.nvim_buf_get_lines(cur, 0, 1, false)[1] == ""
            if not empty then
              return
            end
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if buf ~= cur and vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
                return
              end
            end
            require("snacks").dashboard.open({ buf = cur, win = vim.api.nvim_get_current_win() })
          end)
        end,
      })
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
