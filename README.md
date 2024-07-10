# QNAP VS Code Remote Container

Visual Studio Code Server on QNAP/QTS

![Overview](images/overview.png)

QTS is a busybox based Linux, so we can not install VS Code Server directly. However, we can run it on the Container Station (Docker Engine).

## Pre-configuration / requirements

### Local machine

- SSH public/private key pair
- Install [Remote-SSH extension](https://code.visualstudio.com/docs/remote/ssh)

### QNAP

- [Container Station](https://www.qnap.com/en-us/how-to/faq/article/frequently-asked-questions-about-container-station)
- [Enable SSH](https://www.qnap.com/en-us/how-to/faq/article/how-do-i-access-my-qnap-nas-using-ssh)
- Create `~/Workspaces` directory (QNAP/Container shared volume)
- Copy SSH public key (`~/.ssh/authorized_keys`)
- For git+ssh access, create/copy SSH private key (`~/.ssh/id_ed25519`)
- For git, create/copy config file (`~/.gitconfig`)

## Install

### QNAP

Copy `Dockerfile` and `compose.yaml` to QNAP.

Build and run the container.

```sh
[user@my-qnap-host somewhere]$ docker compose build
[user@my-qnap-host somewhere]$ docker compose up -d
```

### Local Machine

Add SSH config entry on local machine.

- Remote user: vscode
- Remote SSH port: 2022

```sh
Host vscode-on-qnap                # as you like
    HostName my-qnap-host.local    # QNAP local hostname
    User vscode
    Port 2022
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## VS Code remote access

- Open remote explorer
- Open `vscode-on-qnap` alias host

## Memo

If your UID on QTS is not 500, fix/update `FIXME` tag.
