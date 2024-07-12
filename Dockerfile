FROM golang:1.22.5 as builder

RUN go install github.com/boxboat/fixuid@v0.6.0

FROM node:lts

# VS Code remote requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo

RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Development tools
RUN apt-get install -y --no-install-recommends \
    curl \
    vim-tiny \
    less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/bin/fixuid /usr/local/bin

RUN USER=vscode && \
    GROUP=vscode && \
    useradd -m -s /bin/bash $USER && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml && \
    echo '%users ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vscode

USER vscode:vscode

# SSH daemon
EXPOSE 22
CMD ["fixuid", "sudo", "/usr/sbin/sshd", "-D", "-e"]
