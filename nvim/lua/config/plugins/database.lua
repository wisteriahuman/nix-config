-- 接続情報はリポジトリに置かず、dbee の UI から追加する（~/.local/state/nvim/dbee/persistence.json）。
return {
  {
    "kndndrj/nvim-dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function()
      require("dbee").install()
    end,
    keys = {
      {
        "<leader>Db",
        function()
          require("dbee").toggle()
        end,
        desc = "DB 画面 (dbee)",
      },
    },
    config = function()
      require("dbee").setup()
    end,
  },
  {
    "MattiasMTS/cmp-dbee",
    dependencies = { "kndndrj/nvim-dbee" },
    ft = "sql",
    opts = {},
  },
}
