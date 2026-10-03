-- 起動時は読み込まず、<leader>uc で初めてロードして ON にする。
-- fresh: ロード直後（setup 済みで既に ON）なので、最初の1回は切り替えない。
local state = { on = false, fresh = false }

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    keys = {
      {
        "<leader>uc",
        function()
          if state.fresh then
            state.fresh = false
          elseif state.on then
            require("copilot.command").disable()
            state.on = false
          else
            require("copilot.command").enable()
            state.on = true
          end
          vim.notify("Copilot " .. (state.on and "ON" or "OFF"), vim.log.levels.INFO, { title = "Copilot" })
        end,
        desc = "Copilot 切り替え",
      },
    },
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 100,
          keymap = {
            accept = "<C-l>",
            accept_word = false,
            accept_line = "<C-j>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
        filetypes = {
          markdown = true,
          gitcommit = true,
          yaml = true,
          ["*"] = true,
        },
      })
      state.on = true
      state.fresh = true
    end,
  },
}
