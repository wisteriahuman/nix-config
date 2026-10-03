return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      local parsers = {
        "lua",
        "go",
        "python",
        "typescript",
        "javascript",
        "tsx",
        "html",
        "css",
        "json",
        "bash",
        "regex", -- noice の検索コマンドライン(/)ハイライト用
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "gleam",
        "typespec",
        "mermaid",
        "sql",
        "ruby",
        "embedded_template", -- erb
        "rust",
        "swift",
        "astro",
        "yaml",
        "toml",
        "dockerfile",
        "nix",
        "gomod",
        "gosum",
      }

      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local have = {}
      for _, p in ipairs(installed) do
        have[p] = true
      end
      local missing = {}
      for _, p in ipairs(parsers) do
        if not have[p] then
          table.insert(missing, p)
        end
      end
      if #missing > 0 then
        require("nvim-treesitter").install(missing)
      end

      -- パーサ名とファイルタイプ名は一致しない(tsx→typescriptreact, bash→sh など)
      local filetypes = {}
      for _, p in ipairs(parsers) do
        vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(p))
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function()
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldmethod = "expr"
          vim.wo.foldenable = false
        end,
      })
    end,
  },
}
