{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
    bat
    sheldon
  ];

  programs.home-manager.enable = true;

  home.file = {
    ".zshenv".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshenv";
  };

  xdg.configFile = {
    "sheldon/plugins.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/sheldon/plugins.toml";
    "zsh/.zshrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshrc";
    "zsh/.zprofile".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zprofile";
    "zsh/.p10k.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.p10k.zsh";
    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/nvim";
  };
}
