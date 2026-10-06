return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    config = function()
      -- prettier の設定があるプロジェクトでは biome で上書きしない
      local function js_formatter(bufnr)
        local prettier = vim.fs.root(bufnr, {
          '.prettierrc',
          '.prettierrc.json',
          '.prettierrc.js',
          '.prettierrc.cjs',
          '.prettierrc.mjs',
          '.prettierrc.yml',
          '.prettierrc.yaml',
          'prettier.config.js',
          'prettier.config.cjs',
          'prettier.config.mjs',
        })
        return { prettier and 'prettier' or 'biome' }
      end

      -- ~/.clang-format は gq 用の既定なので数えない。数えると、設定を持たない他人の
      -- リポジトリでも保存のたびにファイル全体が整形される
      local function has_project_clang_format(bufnr)
        local root = vim.fs.root(bufnr, { '.clang-format', '_clang-format' })
        return root ~= nil and root ~= vim.fs.normalize('~')
      end

      require('conform').setup({
        formatters_by_ft = {
          lua = { 'stylua' },
          go = { 'goimports' },
          python = { 'ruff_format' },
          javascript = js_formatter,
          typescript = js_formatter,
          javascriptreact = js_formatter,
          typescriptreact = js_formatter,
          json = { 'biome' },
          css = { 'biome' },
          sh = { 'shfmt' },
          bash = { 'shfmt' },
          c = { 'clang-format' },
          cpp = { 'clang-format' },
        },
        format_on_save = function(bufnr)
          local ft = vim.bo[bufnr].filetype
          if (ft == 'c' or ft == 'cpp') and not has_project_clang_format(bufnr) then
            return
          end
          return { timeout_ms = 500, lsp_format = 'fallback' }
        end,
      })

      vim.keymap.set('n', 'gq', function()
        require('conform').format({ async = true })
        if vim.bo.filetype == 'markdown' then
          require('config.mermaid').format_blocks()
        end
      end, { desc = '整形' })
    end,
  },
}
