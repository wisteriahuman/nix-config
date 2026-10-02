return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      { "saghen/blink.compat", version = "2.*", lazy = true, opts = {} },
    },
    event = "InsertEnter",
    config = function()
      require("blink.cmp").setup({
        keymap = {
          preset = "default",
          ["<C-space>"] = { "show" },
          ["<C-e>"] = { "cancel" },
          ["<CR>"] = { "accept", "fallback" },
          ["<Tab>"] = { "select_next", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
        },
        sources = {
          default = { "lsp", "path", "buffer", "snippets" },
          per_filetype = {
            sql = { "snippets", "dbee", "buffer" },
            markdown = { "slash", "lsp", "path", "snippets", "buffer" },
          },
          providers = {
            slash = { name = "Slash", module = "config.slash", score_offset = 100 },
            dbee = { name = "cmp-dbee", module = "blink.compat.source" },
          },
        },
        completion = {
          documentation = {
            auto_show = true,
          },
        },
      })
    end,
  },
}
