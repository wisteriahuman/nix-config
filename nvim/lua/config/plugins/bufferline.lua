return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          numbers = "ordinal",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          show_buffer_close_icons = true,
          show_close_icon = false,
          separator_style = "slant",
          offsets = {
            {
              filetype = "neo-tree",
              text = "File Explorer",
              text_align = "left",
              separator = true,
            },
          },
        },
      })

      local map = vim.keymap.set
      map("n", "<A-,>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Buffer" })
      map("n", "<A-.>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Buffer" })
      map("n", "<A-c>", "<cmd>BufferLinePickClose<CR>", { desc = "Close Buffer" })
    end,
  },
}
