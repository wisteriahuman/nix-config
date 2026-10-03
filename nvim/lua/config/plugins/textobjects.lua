return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local objects = {
        af = { "@function.outer", "関数全体" },
        ["if"] = { "@function.inner", "関数の中身" },
        ac = { "@class.outer", "クラス/型全体" },
        ic = { "@class.inner", "クラス/型の中身" },
        aa = { "@parameter.outer", "引数 (区切り込み)" },
        ia = { "@parameter.inner", "引数" },
      }
      for lhs, object in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(object[1], "textobjects")
        end, { desc = object[2] })
      end

      local move = require("nvim-treesitter-textobjects.move")
      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "次の関数へ" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "前の関数へ" })
    end,
  },
}
