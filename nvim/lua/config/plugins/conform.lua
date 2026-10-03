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
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = 'fallback',
        },
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
