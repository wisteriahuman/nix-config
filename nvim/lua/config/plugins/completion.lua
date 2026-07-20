return {
  {
    "saghen/blink.cmp",
    version = "*",
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
