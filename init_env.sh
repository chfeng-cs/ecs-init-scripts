#!/bin/bash

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
    guarantee_pk ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZrWxOBZ+u91Dt/anhBFt+jm1UN1918WpLY0s6HPkbDCZ+oDlfUJyGbvakycwweuznY9HvFQVOm17tdZVLdd60wtgEpcUI/3LOstyWNt+EXirIbkvIir/Pn+eC1erJFJj3NBX47m4cUFe34DtDUYg8/+whPxugpQm1PswPuzGISuOnM4Hss5e5QgfetvQ/Es8Ybo8l8rccNekFXUIn0tAASRotSmtMWyeteJPVGbse8GU0Xh+ekAHj3mzW1PXv63F2REDOpSZ1oMEjsb/aXjpY9DO4bg8EZBqH//8WZvWk/NZ090Yp4wqjrjGqFgekYxc961g+njR/ACVOPxxBMNEb chuanheng@ddst-PowerEdge-R8201  # Springboard public key
    cd ~
}

# vim
init_vim() {
    cd ~
    if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
        git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
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
    wget -q https://gitee.com/chfeng-cs/simple-scripts/raw/master/.bashrc -O .bashrc
    if [ ! -f .profile ]; then
        echo "Creating .profile"
    else
        echo ".profile is existing. Overwriting ......"
    fi
    wget -q https://gitee.com/chfeng-cs/simple-scripts/raw/master/.profile -O .profile
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
        git config --global user.name "chfeng"
        git config --global user.email "fengchuanheng@sjtu.edu.cn"
    else
        echo "git is not installed on you system."
    fi
}

main() {
    init_ssh
    init_vim
    init_bash
    init_git
}

main
