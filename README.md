# nix-config

Nix (home-manager) で管理する個人の環境設定。

## 前提条件

- `curl` が使えること（他は不要。git・zshは無ければ`bootstrap.sh`がNix経由で用意する）
- SSH鍵は**任意**。GitHubに公開鍵を登録済みならSSHでcloneし、未設定ならHTTPS（読み取り専用）に自動フォールバックする。あとからSSHに切り替えるには:
  ```sh
  git -C ~/Projects/nix-config remote set-url origin git@github.com:wisteriahuman/nix-config.git
  ```

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

`apt`や`sudo`には依存しない。zshはhome-manager（Linuxのみ）で入り、ログインシェルの切り替えは`chsh`が使えれば`chsh`、ダメなら`~/.profile`・`~/.bashrc`から対話シェル時にzshへ`exec`する形にフォールバックする（`NIXCONFIG_NO_ZSH=1`で無効化）。

## CPUアーキテクチャ

roleとCPUアーキテクチャは独立している。`bootstrap.sh`／`nix-sync`が`uname`から`system`（`x86_64-linux`, `aarch64-linux`, `aarch64-darwin`, `x86_64-darwin`）を判定し、`wisteria@<role>-<system>`を選ぶ。手で指定する場合:

```sh
home-manager switch --flake ~/Projects/nix-config#wisteria@linux-minimal-aarch64-linux
```

`wisteria@<role>`（system無し）も別名として残してあり、その role の既定システム（`flake.nix`の`systems`の先頭）を指す。

## ユーザ名

`home.username` / `home.homeDirectory` はハードコードせず、実行中のアカウント（`USER`→`LOGNAME`、ホームは`HOME`）から決める。クラウドVMのように`ubuntu`・`ec2-user`などアカウント名が違うマシンでも、同じroleをそのまま使い回せる。このため`home-manager switch`には`--impure`が必要で、`bootstrap.sh`と`nix-sync`は自動で付ける。手で打つ場合:

```sh
home-manager switch --flake ~/Projects/nix-config#wisteria@linux-minimal-aarch64-linux --impure
```

`NIXCONFIG_USER`で明示的に上書きもできる。（attr名の`wisteria@`は歴史的なラベルで、実際のアカウント名とは無関係）

## 日常の同期

設定を変更してpushした後、他のマシンに反映する:

```sh
nix-sync
```

## 役割(role)の一覧

- `mac-full` — メインの開発機（Mac）。wezterm、mise(フル)、`bin/docker`など一式。`aarch64-darwin` / `x86_64-darwin`
- `linux-minimal` — SSH接続で使うLinuxサーバ向けの最小構成（Neovim中心）。新しいLinux機(WSL含む)はこれを使い回す想定。`x86_64-linux` / `aarch64-linux`

Neovimはnix管理（`common.nix`）なので、`mise install`を待たずbootstrap完了時点で使える。言語ランタイム類は`mise/`側。

新しい役割を追加する場合は、`hosts/`に倣って新規ファイルを作り、`flake.nix`の`roles`に1エントリ（`module`と対応`systems`）を追加する。既存roleを別アーキテクチャに対応させる場合は、その role の`systems`に追記するだけでよい。

## `bin/docker`

Dockerには、手元のPCからSSH経由で別のマシンのDocker daemonを操作する機能（`docker context`）がある。この状態で`docker compose run`のようにディレクトリをコンテナにマウントする操作をすると、マウント元のパスが手元のPC基準のまま相手に送られるため、相手側にそのパスが存在せず失敗する（Docker自体の既知の制限）。

`bin/docker`はこれに対応するラッパー。現在の`docker context`のエンドポイントが`ssh://`の場合にだけ動作し、その接続先へカレントディレクトリ（`docker run -v`の場合は指定したパス）を同期してから、ビルドと実行をリモート側で行い、終わったら結果を手元に同期して戻す。同期先は`docker context`の設定から決まるので、`docker context use`で切り替えれば別のリモートにそのまま向く。プロジェクト側のDockerfileやcompose.yamlの変更は不要。colima・Docker Desktop・OrbStackなどが作るローカルcontextは対象外で、素通しされる。

`.env`、`.env.testing`、`.env.*.sample` も通常のプロジェクトファイルとして双方向同期する。Gitに含めない設定と、自分のリモート開発環境に送らない設定は別物。同期から除外したいファイルは、プロジェクト直下の `.dockerremoteignore` に明示する（例: `.env.production`）。VCSの管理ディレクトリは引き続き除外する。

Mutagenの除外ルールはセッション作成時に固定される。既存セッションに除外ルールの変更を反映する場合は、`mutagen sync list --long` で対象を確認し、`mutagen sync flush <対象セッション>` が成功してから `mutagen sync terminate <対象セッション>` を実行する。次回のラッパー実行で新しいルールのセッションが作られる。セッションの終了や通常の `docker compose down` は、同期先ディレクトリ自体を削除しない。

`docker compose up -d` はリモートでも `-d` をそのまま渡し、Composeの起動処理が終了するまで待つ。起動時の出力と終了コードは手元に返る。サービスが running / healthy になるまで待つ場合は `docker compose up --wait --wait-timeout 120` を使う（healthcheckがないサービスはrunningまでの確認）。ログは `docker compose logs -f` で確認できる。

`-d` / `--wait` のない `docker compose up` は、従来どおりtmux内で実行して再接続できる。以前の `up -d` で作られたtmuxセッションが残っていても、新しい `up -d` はComposeを再実行するため、`--build` などの指定も反映される。同期とポート転送は `docker compose down` まで維持する。

`bin/docker` はHome Managerの `mkOutOfStoreSymlink` で配置している。リンク設定が適用済みの環境では、このファイルの編集は次回の実行から反映される。回帰テストは `python3 -B -m unittest discover -s tests -v` で実行でき、実際のSSH接続やDockerコンテナは使用しない。Mutagenがある環境では、分離したテスト用デーモンとダミーファイルでローカル間の同期も検証する。

## secretsについて

このリポジトリは public。`~/.config/zsh/hidden/`配下や`~/.ssh/`など、秘密情報を含むファイルは意図的に含まれていない。
