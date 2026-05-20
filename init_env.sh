#!/bin/bash

EMAIL=ethan.fengch@gmail.com
FULL_NAME=Ethan Feng

CMD=""
if command -v nala >/dev/null 2>&1; then
    CMD="nala"
elif command -v apt-get >/dev/null 2>&1; then
    CMD="apt-get"
elif command -v yum >/dev/null 2>&1; then
    CMD="yum"
else
    echo "Unsupported System:"
    lsb_release -a
fi

ensure_nala() {
    if [[ "$CMD" == "apt-get" ]] && ! command -v nala >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nala
        if command -v nala >/dev/null 2>&1; then
            CMD="nala"
        fi
    fi
}

intsall_sw() {
    SW_LIST="build-essential curl git vim wget zsh"
    ensure_nala
    sudo $CMD update
    if [[ "$CMD" == "nala" ]]; then
        # Ubuntu or Debian
        sudo $CMD install -y $SW_LIST
    elif [[ "$CMD" == "apt-get" ]]; then
        # Ubuntu or Debian
        sudo $CMD -y install $SW_LIST
    else
        # CentOS
        sudo $CMD -y install $SW_LIST
    fi
}

init_zsh() {
    INSTALL_SH=~/ohmyzsh/tools/install.sh

    # check if zsh is installed
    if [ ! `which zsh` ]; then
        sudo $CMD -y install zsh
    fi

    cd ~
    # install zsh via gitee instead of github
    git clone https://gitee.com/whisky-root/ohmyzsh.git
    sed -i 's/github.com\/\${REPO}/gitee.com\/\${REPO}/' $INSTALL_SH
    sed -i 's/REPO:-ohmyzsh\/ohmyzsh/REPO:-whisky-root\/ohmyzsh/' $INSTALL_SH
    sh "$INSTALL_SH" --unattended
    TARGET_USER=${SUDO_USER:-${USER}}
    if [ "$TARGET_USER" != "root" ]; then
        sudo chsh -s "$(command -v zsh)" "$TARGET_USER"
    fi

    # plugins
    AUTO_SUG_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    if [ ! -f $AUTO_SUG_DIR ];then
        mkdir $AUTO_SUG_DIR
    fi
    git clone https://gitee.com/keman5/zsh-autosuggestions.git $AUTO_SUG_DIR
    wget -q https://gitee.com/chfeng-cs/scripts/raw/master/.zshrc -O ~/.zshrc

    # powerlevel10k theme
    POWER_LEVEL_10K_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ ! -d $POWER_LEVEL_10K_DIR ];then
        git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git $POWER_LEVEL_10K_DIR
    fi
    download_with_fallback() {
        local primary_url="$1"
        local fallback_url="$2"
        local target_file="$3"

        wget -q "$primary_url" -O "$target_file" || true
        if [ ! -s "$target_file" ]; then
            wget -q "$fallback_url" -O "$target_file"
        fi
        if [ ! -s "$target_file" ]; then
            echo "Failed to download $target_file"
            return 1
        fi
    }

    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k-vscode.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k-vscode.zsh \
        ~/.p10k-vscode.zsh
    download_with_fallback \
        https://gitee.com/chfeng-cs/scripts/raw/master/.p10k.zsh \
        https://raw.githubusercontent.com/chfeng-cs/ecs-init-scripts/master/.p10k.zsh \
        ~/.p10k.zsh

}

guarantee_pk() {
    if [ $# != 3 ]; then return; fi;
	echo guarantee $3
	if [ `cat authorized_keys | grep $2 | wc -l` == 0 ]; then
		echo $* >> authorized_keys
		echo $3 added
	fi;
}

init_ssh() {
    cd ~
    if [ ! -d .ssh ]; then
        mkdir -m 700 .ssh
    fi
    cd .ssh
    if [ ! -f authorized_keys ]; then 
		touch authorized_keys
		chmod 600 authorized_keys
	fi
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDBf5jaDI4zVycmTJNzBbV46xwyudolNQYpxYkdRkURvDIX3NGzzM34kjWX6gKjze7p75tCyQpHL/mIZMyp05jD7QiAzgmx8OGdz7eKKSx2W5msdqxT+7rnTtGZSLlLeOs4hJqT5FGx+0BvIla+JlhiWzbl1hAp1gXyFcvFd8jEX6V3Ry1fZGJ5dcWrh3ZOwHts6a5aRHXKMhvO+Jtt6DY2CyCiLzJprtQ65mLs1l7O0geLRINDgjoZUzLA+uPjvEn2Ka9CT+URPV6Dzohh1WZUFn+l0H9rBto9ZfIkuGO+kG/wZ3h12dhXz6YeKK4SaPBkCkCOF/l4lGwC0iGT7EB dande@fch-pc # My PC public key
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/FDGrk167CNnOxTu+IB2zelSBjaHntL5pa9nhd/JVsqURcRH64dWvxsDbDUrdp3g/uoRqBDorCuZiNeL/JOhqpkw7K/Mm9J6TC+VybhiiMXG/0ca482ek6vY1xXvfmwjo/jyMTlHUNIohFbyrI4DOK968hM2bWsl0rV5hAkmjSXRaSLwjUbOWYbuZYeYeS6UX5JcQlWE4E02hit8VGtyW+ArIbcHBoFnoERAPh7LwfgQKqBmU3DKCewgJJ98F6GRhHHcUZtSCYBj1TCKPgJ304lPlfnwVvwAkiUbHn8k/7XRq+GFU4zMOw1YNh/rn28AZM+HNHCa8/uLugBLqADh+915vrjqvo+6OMHrDmpXyAoixZYpq7lgTjc1Sbuv/oSO/kiuU89uJpm95EiS84Xg9+j2zj4SS8b+DEe06/QTaz76BhkygWLQJqtJAV+3BJU4IgijKuna4aXh23OIwT/VQ8EBm7e7oP3c49lk5+uR1jFzLYC39lpC1pWaYc8odPbM= feng@DESKTOP-4BCF5JK # Add work pk

    cd ~
}

# vim
init_vim() {
    cd ~
    if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
        git clone https://gitee.com/mirrors/Vundle.git ~/.vim/bundle/Vundle.vim
    fi
    if [ ! -f .vimrc ]; then
        echo "Creating .vimrc"
        wget -q https://gitee.com/chfeng-cs/simple-scripts/raw/master/.vimrc -O .vimrc
    else
        echo ".vimrc is existing. Do nothing ......"
    fi
}

# bash
init_bash() {
    cd ~
    if [ ! -f .bashrc ]; then
        echo "Creating .bashrc"
    else
        echo ".bashrc is existing. Overwriting ......"
    fi
    wget -q https://gitee.com/chfeng-cs/scripts/raw/master/.bashrc -O .bashrc
    if [ ! -f .profile ]; then
        echo "Creating .profile"
    else
        echo ".profile is existing. Overwriting ......"
    fi
    wget -q https://gitee.com/chfeng-cs/scripts/raw/master/.profile -O .profile
    # if [ ! -f .bashrc ]; then
    #     wget -q https://gitee.com/chfeng-cs/simple-scripts/raw/master/.bashrc
    # fi
    # if [ ! -f .profile ]; then
    #     wget -q https://gitee.com/chfeng-cs/simple-scripts/raw/master/.profile
    # fi
}

# git
init_git() {
    if [ `which git` ]; then
        git config --global user.name $FULL_NAME
        git config --global user.email $EMAIL
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global alias.mg merge
        git config --global alias.md commit --amend
        git config --global alias.dt difftool
        git config --global alias.mt mergetool
        git config --global alias.cf config
        git config --global alias.last log -1 HEAD 2>/dev/null
        git config --global alias.line log --oneline 2>/dev/null
        git config --global alias.latest for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short) [%(committername)]' 2>/dev/null
    else
        echo "git is not installed on you system."
    fi
}

main() {
    intsall_sw
    init_ssh
    init_bash
    init_git
    init_vim
    init_zsh
}

main
