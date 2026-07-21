# nix-config

Nix (home-manager) で管理する個人の環境設定。

## 前提条件

- SSH鍵を用意し、GitHubに公開鍵を登録しておくこと（`ssh-keygen` → GitHubの Settings > SSH keys）

## 新しいマシンでのセットアップ

```sh
curl -fsSL https://raw.githubusercontent.com/wisteriahuman/nix-config/main/bootstrap.sh | sh
```

設定は**役割(role)**単位で用意している（例: 「Mac用フルセット」「Linux用最小構成」。詳細は後述）。上記コマンドは接続しているOSから役割を自動判定し、確認プロンプトを出す。明示的に指定したい場合:

```sh
sh bootstrap.sh mac-full
# または
NIXCONFIG_ROLE=linux-minimal curl -fsSL https://raw.githubusercontent.com/wisteriahuman/nix-config/main/bootstrap.sh | sh
```

Nixのインストール直後は新しいシェルセッションを開いてから再実行が必要。

## 日常の同期

設定を変更してpushした後、他のマシンに反映する:

```sh
nix-sync
```

## 役割(role)の一覧

- `mac-full` — メインの開発機（Mac）。wezterm、mise(フル)、`bin/docker`など一式
- `linux-minimal` — SSH接続で使うLinuxサーバ向けの最小構成（Neovim中心）。新しいLinux機(WSL含む)はこれを使い回す想定

新しい役割を追加する場合は、`hosts/`に倣って新規ファイルを作り、`flake.nix`の`homeConfigurations`に1エントリ追加する。

## `bin/docker`

Dockerには、手元のPCからSSH経由で別のマシンのDocker daemonを操作する機能（`docker context`）がある。この状態で`docker compose run`のようにディレクトリをコンテナにマウントする操作をすると、マウント元のパスが手元のPC基準のまま相手に送られるため、相手側にそのパスが存在せず失敗する（Docker自体の既知の制限）。

`bin/docker`はこれに対応するラッパー。現在の`docker context`のエンドポイントが`ssh://`の場合にだけ動作し、その接続先へカレントディレクトリ（`docker run -v`の場合は指定したパス）を同期してから、ビルドと実行をリモート側で行い、終わったら結果を手元に同期して戻す。同期先は`docker context`の設定から決まるので、`docker context use`で切り替えれば別のリモートにそのまま向く。プロジェクト側のDockerfileやcompose.yamlの変更は不要。colima・Docker Desktop・OrbStackなどが作るローカルcontextは対象外で、素通しされる。

## secretsについて

このリポジトリは public。`~/.config/zsh/hidden/`配下や`~/.ssh/`など、秘密情報を含むファイルは意図的に含まれていない。
