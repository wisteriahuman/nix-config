return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-python",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-golang"),
          require("neotest-python"),
        },
      })

      local map = vim.keymap.set
      local neotest = require("neotest")
      map("n", "<leader>nr", function()
        neotest.run.run()
      end, { desc = "カーソル位置のテストを実行" })
      map("n", "<leader>nf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { desc = "このファイルのテストを実行" })
      map("n", "<leader>ns", function()
        neotest.summary.toggle()
      end, { desc = "テスト一覧" })
      map("n", "<leader>no", function()
        neotest.output_panel.toggle()
      end, { desc = "テスト出力" })
    end,
    keys = {
      { "<leader>nr", desc = "カーソル位置のテストを実行" },
      { "<leader>nf", desc = "このファイルのテストを実行" },
    },
  },
}
