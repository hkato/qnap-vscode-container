FROM ubuntu:20.04

# VS Code remote requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    libatomic1 \
    sudo

RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Development tools
RUN apt-get install -y --no-install-recommends \
    git \
    curl \
    vim-tiny \
    less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Host/container user mapping
ARG USERNAME=vscode
ARG UID=500
ARG GID=100

RUN useradd -m -s /bin/bash -u $UID -g $GID $USERNAME
RUN echo '%users ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vscode

USER $USERNAME

RUN mkdir /home/$USERNAME/.ssh
RUN chmod 700 /home/$USERNAME/.ssh

# SSH daemon
EXPOSE 22
CMD ["sudo", "/usr/sbin/sshd", "-D"]
