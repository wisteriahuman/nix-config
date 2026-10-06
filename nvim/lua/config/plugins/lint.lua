return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
      }

      local function run(args)
        lint.try_lint()
        -- ディスク上のファイルを読むので、未保存の変更がある InsertLeave では走らせない
        if vim.bo[args.buf].filetype == "c" and args.event ~= "InsertLeave" then
          require("config.clang").analyze(args.buf)
        end
        if vim.api.nvim_buf_get_name(args.buf):match("/%.github/workflows/[^/]+%.ya?ml$") then
          lint.try_lint("actionlint")
        end
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, { callback = run })
      -- このプラグイン自体が BufReadPost で読み込まれるので、最初のバッファは自前で走らせる
      vim.schedule(function()
        run({ buf = vim.api.nvim_get_current_buf(), event = "BufReadPost" })
      end)
    end,
  },
}
