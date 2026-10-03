return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      { "saghen/blink.compat", version = "2.*", lazy = true, opts = {} },
      "rafamadriz/friendly-snippets",
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
          ["<C-CR>"] = { "snippet_forward", "fallback" },
          ["<C-S-CR>"] = { "snippet_backward", "fallback" },
        },
        sources = {
          default = { "lsp", "path", "buffer", "snippets" },
          per_filetype = {
            sql = { "snippets", "dbee", "buffer" },
            markdown = { "slash", "lsp", "path", "snippets", "buffer" },
          },
          providers = {
            snippets = { opts = { extended_filetypes = { ruby = { "rails" } } } },
            slash = { name = "Slash", module = "config.slash", score_offset = 100 },
            dbee = { name = "cmp-dbee", module = "blink.compat.source" },
          },
        },
        completion = {
          menu = {
            border = "rounded",
            draw = {
              columns = {
                { "kind_icon" },
                { "label", "label_description", gap = 1 },
                { "kind" },
                { "source_name" },
              },
            },
          },
          documentation = {
            auto_show = true,
            window = { border = "rounded" },
          },
          ghost_text = {
            -- Copilot の ghost text と重なるので、Copilot が ON の間は出さない
            enabled = function()
              local copilot = package.loaded["copilot.client"]
              return not (copilot and not copilot.is_disabled())
            end,
          },
        },
        signature = {
          enabled = true,
          window = { border = "rounded" },
        },
      })
    end,
  },
}
