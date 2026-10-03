return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
      }

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        callback = function(args)
          lint.try_lint()
          if vim.api.nvim_buf_get_name(args.buf):match("/%.github/workflows/[^/]+%.ya?ml$") then
            lint.try_lint("actionlint")
          end
        end,
      })
    end,
  },
}
