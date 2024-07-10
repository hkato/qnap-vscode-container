# QNAP(QTS)でVS Codeを使いファイル編集する

## とりあえず結果の概要

![](https://raw.githubusercontent.com/hkato/qnap-vscode-container/5ae98e9fdd1e92dcc0fda8a4b96a368684641dd4/images/overview.png)

Docker上でUbuntuを動かしその中でSSHdとVS Codeサーバーを動かしマウントしたVolume上のファイルを編集する。

## やりたいこと

QNAPを持っているが、この上でDockerが動くのでちょっとした私家アプリケーションを動かしたい。しかしQNAPのエントリーモデル用OSであるQTSはLinuxであるもののBusyboxベースなので、コマンドオプションが異なっていたり、最小限のコマンドしか入っていないのでなかなか使いにくい(一応viは入っている)。

VS CodeでリモートからQNAPにアクセスしファイル編集でたら良いのになぁ…。

## とりあえず動かない理由

VS Code Serverのインストーラーがgrepを使っているが、GNU grepを前提としており、busyboxのgrepはオプションが異なるため、まずそこで引っ掛かる。もし仮にgrepをGNU版に入れ替え、そこは通ったとしてもその先で使用するコマンドオプションやら必要とするライブラリーで苦労するはず。

なお、私の持っているQNAPはTS-231でArm32アークテクチャ。VS Codeは Arm32にも対応しているので、deb系, rpm系なら動くはず…。

## Container Station上で動かす

ということでQNAPのアプリケーションContainer Station = Docker EngineでUbuntuを動かし、その上でVS Code Server動かすこととした。

### 事前条件

- QNAPにSSH接続するための設定は[こちら](https://www.qnap.com/ja-jp/how-to/faq/article/how-to-access-qnap-nas-by-ssh)
- コマンドラインでDockerを使うための話は[こちら](https://qiita.com/abeshi-X1/items/11f1d04ec85fe4cbf45e)
- SSH公開鍵認証の話は[こちら](https://qiita.com/kazokmr/items/754169cfa996b24fcbf5)。

上記が揃ったところで、

### Dockerfile

#### VS Codeを動かすために必要なもの

SSH Remoteで接続するので`openssh-server`、`libatomic1`はVS Codeが必要とするライブラリー、`sudo`は後述するファイルのパーミッションを合わせるためrootでないユーザーで動かすため`sudo`で`sshd`を起動するため。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    libatomic1 \
    sudo
```

#### SSHdの設定

こちらを参考に

https://docs.docker.jp/engine/examples/running_ssh_service.html

```dockerfile
RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
```

#### 開発ツール

VS Codeでファイル編集してもそのファイルをgitで管理したりコピーしたりしたい。なので基本的なコマンドはインストールしておく。

```dockerfile
# Development tools
RUN apt-get install -y --no-install-recommends \
    git \
    curl \
    vim-tiny \
    less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

#### VS Code実行ユーザー

コンテナーをrootユーザーで動かすと、ホストOSのユーザーとUID/GIDがマッチせず、root権限のファイルがホストOS上に作成されてしまう。このため一般ユーザーを作ってそちらに切り替える。UID=500はQNAPで最初に作成したユーザーのUIDになる。基本的におうちサーバーを想定しているので、管理者=最初のユーザーがVS Codeを使うことになるだろう、家族は501,502,…になる。だから、まあ、500ってことで。そうじゃない場合はUIDを変更。

それとユーザーを切り替えて動かすのでsshdが実行できなくなるためsudoを使いたいがパスワードを要求されないようにsudoersに入れておく。

あとはsshの設定を入れるディレクトリーだけ作成しておく。

```dockerfile
# Host/container user mapping
ARG USERNAME=vscode     # FIXME
ARG UID=500             # FIXME
ARG GID=100             # FIXME

RUN useradd -m -s /bin/bash -u $UID -g $GID $USERNAME
RUN echo '%users ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vscode

USER $USERNAME

RUN mkdir /home/$USERNAME/.ssh
RUN chmod 700 /home/$USERNAME/.ssh
```

#### SSHd実行

ポート22を公開しsudo経由でsshdをデーモンモードで実行。上記の通りsudoers設定にてパスワードは要求されない。

```dockerfile
# SSH daemon
EXPOSE 22
CMD ["sudo", "/usr/sbin/sshd", "-D"]
```

#### Dockerfileまとめ

まとめるとこちら、

https://github.com/hkato/qnap-vscode-container/blob/main/Dockerfile

### Composeファイル

`docker run`コマンドで実行しても良いがオプションが長くなるので`compose.yaml`を設定し`docker compose`で実行する。

- `user:` にてホストOSと同じユーザーで実行（ファイル権限を合わせるため)
- `port:` にてSSHdのポートを2022にマッピングして公開
- `volumes:`
  - `Workspaces`を作業用・共有ヴォリュームとした。
  - `authorized_keys`はQNAP上に置いといてマウント、パスワードなしでログインするためホストOS側の公開鍵を入れておく
  - 秘密鍵はgit+sshでGitサーバーにアクセスしファイル管理したいため
  - `.gitconfig`はGitの設定

```yml
services:
  vscode:
    build: .
    restart: always
    user: 500:100     # FIXME
    ports:
      - 2022:22
    volumes:
      - $HOME/Workspaces:/home/vscode/Workspaces:rw
      - $HOME/.ssh/authorized_keys:/home/vscode/.ssh/authorized_keys:ro
      - $HOME/.ssh/id_ed25519:/home/vscode/.ssh/id_ed25519:ro
      - $HOME/.gitconfig:/home/vscode/.gitconfig:ro
```

これで`docker compose build && docker compose up -d`しておく。

### ローカルホスト側設定

ポート2022と固定ユーザーvscodeでログインしたいので`.ssh/config`に次のエントリーを設定しておく。

```sh
Host vscode-on-qnap                # as you like
    HostName my-qnap-host.local    # QNAP local hostname
    User vscode
    Port 2022
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

`HostName`はQNAP本体のホスト名あるいはIPアドレス。`Host`は好きな名前で。`StrictHostKeyChecking`と`UserKnownHostsFile`はコンテナーをビルドするたびにSSHホスト鍵が変わってしまうのでその回避(あまり良くない)。

## 接続

あとはVS Codeのリモートエクスプローラーから上記の設定だと`vscode-on-qnap`に接続すれば、いつも通りにVS Code Serverのインストールが始まり、フォルダー選択とワークスペースが開き、ファイルの編集ができるようになる。
