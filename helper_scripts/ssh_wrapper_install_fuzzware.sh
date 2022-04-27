#!/bin/sh

set -e

GIT_REPO_SITE=${GIT_REPO_SITE:-"github.com"}
GIT_REPO_OWNER=${GIT_REPO_OWNER:-"fuzzware-fuzzer"}

OWN_COMMIT="$(git rev-parse HEAD)"
if [ $# -lt 1 ]; then
    echo "Install fuzzware on a fresh ubuntu machine given an (ssh config configured) remote host and optionally, a ssh key to be used to access the git repository."
    echo "usage: $0 <remote_host> [<git_ssh_key>]"
    exit 1
fi

HOST="$1"
if [ $# -ge 2 ]; then
    SSH_KEY="$2"

    if [ ! -f "$SSH_KEY" ]; then
        echo "ssh key file '$SSH_KEY' does not exist"; exit 2
    fi
fi

# 1. update system
ssh -o StrictHostKeyChecking=no "root@$HOST" "apt update && apt upgrade -y"
ssh "root@$HOST" "apt-get install -y tmux git"

# 2. create user and set password-less sudo
ssh "root@$HOST" 'id -u worker &>/dev/null || useradd -m -s /bin/bash -U -G sudo worker'
ssh "root@$HOST" 'if [ ! -e /home/worker/.ssh ]; then cp -r /root/.ssh /home/worker && chown -R worker:worker /home/worker/.ssh; fi'

# 3. copy over ssh key, if required
if [ ! -z "$SSH_KEY" ]; then
    scp "$SSH_KEY" "worker@$HOST:~/.ssh/gitaccess.key"
    ssh "worker@$HOST" "touch ~/.ssh/config && grep -q $GIT_REPO_SITE ~/.ssh/config || (echo -e \"\nHost $GIT_REPO_SITE\n\tUser git\n\tIdentityFile ~/.ssh/gitaccess.key\n\tStrictHostKeyChecking no\n\nHost *\n\tIdentitiesOnly yes\n\" >> ~/.ssh/config)"
    # SSH key: ssh-based git access
    GIT_REPO_BASE="$GIT_REPO_SITE:$GIT_REPO_OWNER"
else
    # No SSH key: https-based git access
    GIT_REPO_BASE="https://$GIT_REPO_SITE/$GIT_REPO_OWNER"
fi

# 4. clone fuzzware, check out specific versions, and pull submodules
ssh "worker@$HOST" "cd ~ && [ -e fuzzware ] || git clone $GIT_REPO_BASE/fuzzware; cd fuzzware; git checkout \$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //') && git pull && if [ ! -z '$FUZZWARE_VERSION' ]; then git checkout '$FUZZWARE_VERSION'; fi; git submodule update --init --recursive"
ssh "worker@$HOST" "cd ~ && [ -e fuzzware-experiments ] || git clone $GIT_REPO_BASE/fuzzware-experiments; cd fuzzware-experiments; git checkout \$(git remote show origin | grep 'HEAD branch' | sed 's/.*: //') && git pull && git checkout $OWN_COMMIT"

# 5. install pipeline locally
if [ $USE_DOCKER_INSTALL -eq 1 ]; then
    # Docker install and docker group add
    ssh "worker@$HOST" 'cd ~/fuzzware && ./ubuntu_install_docker.sh || echo "docker already installed"'
    ssh "worker@$HOST" "sudo usermod -a -G docker worker"
    ssh "worker@$HOST" "cd ~/fuzzware && ./build_docker.sh"
else
    # Local install
    ssh "root@$HOST" "apt-get install -y python3-pip automake redis cmake clang gnuplot"
    ssh "root@$HOST" "pip3 install virtualenv virtualenvwrapper"
    ssh "worker@$HOST" 'grep -q VIRTUALENVWRAPPER_PYTHON ~/.bashrc || (echo -e "\nexport WORKON_HOME=~/.virtualenvs\nexport VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3\nsource /usr/local/bin/virtualenvwrapper.sh\n" >> ~/.bashrc)'
    ssh "worker@$HOST" 'cd ~/fuzzware && bash ./install_local.sh'
fi
