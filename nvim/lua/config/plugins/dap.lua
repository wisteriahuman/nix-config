return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "delve", "debugpy", "js" },
        automatic_installation = true,
      })

      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      require("dap-go").setup()
      require("dap-python").setup("python3")

      local map = vim.keymap.set
      map("n", "<leader>dc", dap.continue, { desc = "Debug Continue" })
      map("n", "<leader>do", dap.step_over, { desc = "Debug Step Over" })
      map("n", "<leader>di", dap.step_into, { desc = "Debug Step Into" })
      map("n", "<leader>dO", dap.step_out, { desc = "Debug Step Out" })
      map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
      map("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Condition: "))
      end, { desc = "Conditional Breakpoint" })
      map("n", "<leader>dr", dap.restart, { desc = "Debug Restart" })
      map("n", "<leader>dt", dap.terminate, { desc = "Debug Terminate" })
      map("n", "<leader>du", dapui.toggle, { desc = "Debug UI Toggle" })
    end,
    keys = {
      { "<leader>dc", desc = "Debug Continue" },
      { "<leader>db", desc = "Toggle Breakpoint" },
    },
  },
}
