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
      end, { desc = "Test Nearest" })
      map("n", "<leader>nf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { desc = "Test File" })
      map("n", "<leader>ns", function()
        neotest.summary.toggle()
      end, { desc = "Test Summary" })
      map("n", "<leader>no", function()
        neotest.output_panel.toggle()
      end, { desc = "Test Output" })
      map("n", "<leader>nd", function()
        neotest.run.run({ strategy = "dap" })
      end, { desc = "Test Debug" })
    end,
    keys = {
      { "<leader>nr", desc = "Test Nearest" },
      { "<leader>nf", desc = "Test File" },
    },
  },
}
