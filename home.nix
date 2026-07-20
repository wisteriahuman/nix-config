{ pkgs, ... }:

{
  home.username = "wisteria";
  home.homeDirectory = "/Users/wisteria";

  # 最初にswitchしたhome-managerのリリースに合わせて固定する値。
  # 後から上げるのは任意だが、下げてはいけない。
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
    bat
  ];

  # home-manager自体をこの環境のパッケージとして管理する
  programs.home-manager.enable = true;
}
