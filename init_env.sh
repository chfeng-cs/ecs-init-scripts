#!/bin/bash

EMAIL=fengchuanheng@sjtu.edu.cn
FULL_NAME=fengchuanheng

CMD=""
if [[ $(command -v apt-get) ]]; then
    CMD="apt-get"
elif [[ $(command -v yum) ]]; then
    CMD="yum"
else
    echo "Unsupported System:"
    lsb_release -a
fi

intsall_sw() {
    SW_LIST="build-essential curl git vim wget zsh"
    sudo $CMD update
    if [[ $(command -v apt-get) ]]; then
        # Ubuntu or Debian
        sudo $CMD -y install aptitude
        sudo aptitude -y install $SW_LIST
    else
        # CentOS
        sudo $CMD -y install $SW_LIST
    fi
}

init_zsh() {
    INSTALL_SH=~/ohmyzsh/tools/install.sh

    cd ~
    # install zsh via gitee instead of github
    git clone https://gitee.com/whisky-root/ohmyzsh.git
    sed -i 's/github.com\/\${REPO}/gitee.com\/\${REPO}/' $INSTALL_SH
    sed -i 's/REPO:-ohmyzsh\/ohmyzsh/REPO:-whisky-root\/ohmyzsh/' $INSTALL_SH
    zsh $INSTALL_SH

    # plugins
    AUTO_SUG_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    if [ ! -f $AUTO_SUG_DIR ];then
        mkdir $AUTO_SUG_DIR
    fi
    git clone https://gitee.com/keman5/zsh-autosuggestions.git $AUTO_SUG_DIR
    wget -q https://gitee.com/chfeng-cs/scripts/raw/master/.zshrc -O ~/.zshrc
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
        git config --global alias.last log -1 HEAD
        git config --global alias.line log --oneline
        git config --global alias.latest for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short) [%(committername)]'
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
