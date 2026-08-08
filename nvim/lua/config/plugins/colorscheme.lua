-- 実際の setup()/colorscheme 適用は config/theme.lua が担当する。
-- ここではプラグインのインストールと eager load だけを宣言する。
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
  },
  {
    "echasnovski/mini.nvim",
    lazy = false,
    priority = 1000,
  },
}
