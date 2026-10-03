return {
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      -- otter は拡張子表に無い言語を黙って飛ばす
      extensions = { mermaid = "mmd" },
    },
    config = function(_, opts)
      require("otter").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          local otter = require("otter")
          otter.activate({ "mermaid", "lua", "bash", "json" }, true, true, nil)
        end,
      })
    end,
  },
}
