{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  home.username = "wisteria";
  home.homeDirectory = "/home/wisteria";

  # 最初にswitchしたhome-managerのリリースに合わせて固定する値。
  # 後から上げるのは任意だが、下げてはいけない。
  home.stateVersion = "25.05";
}
