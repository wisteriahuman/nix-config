return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      -- `:wq` などのコマンドラインをフロート化する本命
      cmdline = {
        enabled = true,
        view = "cmdline_popup", -- 画面中央上に浮かせる
        format = {
          cmdline = { pattern = "^:", icon = " ", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = "  ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = "  ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "  ", lang = "bash" },
          lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "  ", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖 " },
        },
      },

      -- 通知/メッセージは既存の snacks.nvim(notifier) に任せて競合させない
      messages = { enabled = false },
      notify = { enabled = false },

      -- 補完候補/ワイルドメニューもフロート化(blink.cmp とは別レイヤー)
      popupmenu = {
        enabled = true,
        backend = "nui",
      },

      -- K のホバー等だけ noice の整形を借りる(blink の補完ドキュメントには触らない)
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },

      presets = {
        command_palette = true, -- cmdline と候補を中央上にまとめて配置
        long_message_to_split = true, -- 長いメッセージは split に
        lsp_doc_border = true, -- ホバーに枠線
      },
    },
  },
}
