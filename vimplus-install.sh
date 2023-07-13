#!/bin/bash

# 获取linux发行版名称
function get_linux_distro()
{
    if grep -Eq "Ubuntu" /etc/*-release; then
        echo "Ubuntu"
    else
        echo "Unknown"
    fi
}

# 获取当前时间戳
function get_now_timestamp()
{
    cur_sec_and_ns=`date '+%s-%N'`
    echo ${cur_sec_and_ns%-*}
}


# 获取日期
function get_datetime()
{
    time=$(date "+%Y%m%d%H%M%S")
    echo $time
}

# 判断文件是否存在
function is_exist_file()
{
    filename=$1
    if [ -f $filename ]; then
        echo 1
    else
        echo 0
    fi
}

# 判断目录是否存在
function is_exist_dir()
{
    dir=$1
    if [ -d $dir ]; then
        echo 1
    else
        echo 0
    fi
}

#备份原有的.vimrc文件
function backup_vimrc_file()
{
    old_vimrc=$HOME"/.vimrc"
    is_exist=$(is_exist_file $old_vimrc)
    if [ $is_exist == 1 ]; then
        time=$(get_datetime)
        backup_vimrc=$old_vimrc"_bak_"$time
        read -p "Find "$old_vimrc" already exists,backup "$old_vimrc" to "$backup_vimrc"? [Y/N] " ch
        if [[ $ch == "Y" ]] || [[ $ch == "y" ]]; then
            cp $old_vimrc $backup_vimrc
        fi
    fi
}

#备份原有的.vimrc.custom.plugins文件
function backup_vimrc_custom_plugins_file()
{
    old_vimrc_plugins=$HOME"/.vimrc.custom.plugins"
    is_exist=$(is_exist_file $old_vimrc_plugins)
    if [ $is_exist == 1 ]; then
        time=$(get_datetime)
        backup_vimrc_plugins=$old_vimrc_plugins"_bak_"$time
        read -p "Find "$old_vimrc_plugins" already exists,backup "$old_vimrc_plugins" to "$backup_vimrc_plugins"? [Y/N] " ch
        if [[ $ch == "Y" ]] || [[ $ch == "y" ]]; then
            cp $old_vimrc_plugins $backup_vimrc_plugins
        fi
    fi
}

#备份原有的.vimrc.custom.config文件
function backup_vimrc_custom_config_file()
{
    old_vimrc_config=$HOME"/.vimrc.custom.config"
    is_exist=$(is_exist_file $old_vimrc_config)
    if [ $is_exist == 1 ]; then
        time=$(get_datetime)
        backup_vimrc_config=$old_vimrc_config"_bak_"$time
        read -p "Find "$old_vimrc_config" already exists,backup "$old_vimrc_config" to "$backup_vimrc_config"? [Y/N] " ch
        if [[ $ch == "Y" ]] || [[ $ch == "y" ]]; then
            cp $old_vimrc_config $backup_vimrc_config
        fi
    fi
}

#备份原有的.vim目录
function backup_vim_dir()
{
    old_vim=$HOME"/.vim"
    is_exist=$(is_exist_dir $old_vim)
    if [ $is_exist == 1 ]; then
        time=$(get_datetime)
        backup_vim=$old_vim"_bak_"$time
        read -p "Find "$old_vim" already exists,backup "$old_vim" to "$backup_vim"? [Y/N] " ch
        if [[ $ch == "Y" ]] || [[ $ch == "y" ]]; then
            cp -R $old_vim $backup_vim
        fi
    fi
}

# 备份原有的.vimrc和.vim
function backup_vimrc_and_vim()
{
    backup_vimrc_file
    backup_vimrc_custom_plugins_file
    backup_vimrc_custom_config_file
    backup_vim_dir
}

# 获取ubuntu版本
function get_ubuntu_version()
{
    line=$(cat /etc/lsb-release | grep "DISTRIB_RELEASE")
    arr=(${line//=/ })
    version=(${arr[1]//./ })

    echo ${version[0]}
}

# 在ubuntu上源代码安装vim
function compile_vim_on_ubuntu()
{
    # 编译 vim 支持 python3，由于 configure 将 python3 的 configuration 目录作为 python 动态库的链接目录，导致 vim 链接了静态库，编译不会报错
    # 但是在后续执行 vim 时，YouCompleteMe 插件会提示 python 的一个依赖库找不到符号，因此需要手动将当前 python3 的动态库拷贝到 configuration 目录下
    # py_dll=$(ldd $(command -v python3) | grep -i "python3" | awk '{print $3}')
    # py_dll_path=${py_dll%/*}
    # py_conf_path=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_config_var("LIBPL"))')
    # echo "python3 dll path: "$py_dll_path
    # echo "python3 conf path: "$py_conf_path
    # cp $py_dll_path/lib*.* $py_conf_path
    # sudo apt-get install -y libncurses5-dev libncurses5 libgnome2-dev libgnomeui-dev \
    #     libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    #     libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev python3-dev ruby-dev lua5.1 lua5.1-dev
    git clone https://github.com/vim/vim.git /tmp/vim
    cd /tmp/vim
    sed -i 's/print(sys\.version\[\:[0-9]\])/major,minor=sys\.version_info\[\:2\];print(f"{major}.{minor}")/' src/auto/configure
    LDFLAGS="-rdynamic" ./configure --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp \
        --enable-python3interp=yes \
        --enable-perlinterp \
        --enable-luainterp \
        --enable-gui=gtk2 \
        --enable-cscope \
        --prefix=/${HOME}/.local/vim82
    make -j`nproc` && make -j`nproc` install && echo "export PATH=${HOME}/.local/vim82/bin:\$PATH" >> ${HOME}/.local/env.sh && source ${HOME}/.local/env.sh
    cd -
    # rm -rf /tmp/vim82
}

# 安装ubuntu必备软件
function install_prepare_software_on_ubuntu()
{
    # sudo apt-get update

    # version=$(get_ubuntu_version)
    # if [ $version -eq 14 ];then
    #     sudo apt-get install -y cmake3
    # else
    #     sudo apt-get install -y cmake
    # fi

    # sudo apt-get install -y build-essential python python-dev python3-dev fontconfig libfile-next-perl ack-grep git
    # sudo apt-get install -y universal-ctags || sudo apt-get install -y exuberant-ctags
    
    if [[ ! -x $(command -v vim) ]] || [[ $(vim --version | awk '$5 ~ /[0-9]\.[0-9]/ {print $5}') < "8.2" ]];then
        compile_vim_on_ubuntu
        
    else
        echo "vim version is greater than 8.2"
    fi
}

# 拷贝文件
function copy_files()
{
    rm -rf ~/.vimrc
    ln -s ${PWD}/.vimrc ~

    rm -rf ~/.vimrc.custom.plugins
    cp ${PWD}/.vimrc.custom.plugins ~

    rm -rf ~/.vimrc.custom.config
    cp ${PWD}/.vimrc.custom.config ~

    rm -rf ~/.ycm_extra_conf.py
    ln -s ${PWD}/.ycm_extra_conf.py ~

    mkdir ~/.vim
    rm -rf ~/.vim/colors
    ln -s ${PWD}/colors ~/.vim

    rm -rf ~/.vim/ftplugin
    ln -s ${PWD}/ftplugin ~/.vim

    rm -rf ~/.vim/autoload
    ln -s ${PWD}/autoload ~/.vim
}

# 安装linux平台字体
function install_fonts_on_linux()
{
    mkdir -p ~/.local/share/fonts
    rm -rf ~/.local/share/fonts/Droid\ Sans\ Mono\ Nerd\ Font\ Complete.otf
    cp ./fonts/Droid\ Sans\ Mono\ Nerd\ Font\ Complete.otf ~/.local/share/fonts

    fc-cache -vf ~/.local/share/fonts
}

# 安装ycm插件
function install_ycm()
{
    git clone --recursive https://github.com/ycm-core/YouCompleteMe.git ~/.vim/plugged/YouCompleteMe

    cd ~/.vim/plugged/YouCompleteMe
    distro=`get_linux_distro`
    if [[ -x $(command -v python3) ]];then
        version="3"
    elif [[ -x $(command -v python2) ]];then
        version="2"
    else
        read -p "Not found python2 or python3, please input python version(2/3): " version
    fi
    if [[ $version == "2" ]]; then
        echo "Compile ycm with python2."
        # alpine 忽略 --clang-completer 并将 let g:ycm_clangd_binary_path 注入 .vimrc
        {
            if [ ${distro} == "Alpine" ]; then
                echo "##########################################"
                echo "Apline Build, need without GLIBC."
                echo "##########################################"
                sed -i "273ilet g:ycm_clangd_binary_path='/usr/bin/clang'" ~/.vimrc
                python2.7 ./install.py
                return
            fi
        } || {
            python2.7 ./install.py --clang-completer
        } || {
            echo "##########################################"
            echo "Build error, trying rebuild without Clang."
            echo "##########################################"
            python2.7 ./install.py
        }
    else
        echo "Compile ycm with python3."
        python3 ./install.py
    fi
}

# 打印logo
function print_logo()
{
    color="$(tput setaf 6)"
    normal="$(tput sgr0)"
    printf "${color}"
    echo '        __                __           '
    echo '__   __/_/___ ___  ____  / /_  _______ '
    echo '\ \ / / / __ `__ \/ __ \/ / / / / ___/ '
    echo ' \ V / / / / / / / /_/ / / /_/ (__  )  '
    echo '  \_/_/_/ /_/ /_/ ,___/_/\____/____/   '
    echo '               /_/                     ...is now installed!'
    echo ''
    echo ''
    echo 'Just enjoy it!'
    echo 'p.s. Follow me at https://github.com/chxuan.'
    echo ''
    printf "${normal}"
}

# 安装vim插件
function install_vim_plugin()
{
    vim -c "PlugInstall" -c "q" -c "q"
}

# 开始安装vimplus
function begin_install_vimplus()
{
    copy_files
    install_fonts_on_linux
    install_ycm
    install_vim_plugin
    print_logo
}

# 在ubuntu上安装vimplus
function install_vimplus_on_ubuntu()
{
    backup_vimrc_and_vim
    install_prepare_software_on_ubuntu
    begin_install_vimplus
}

# 在linux平上台安装vimplus
function install_vimplus_on_linux()
{
    distro=`get_linux_distro`
    echo "Linux distro: "${distro}

    if [ ${distro} == "Ubuntu" ]; then
        install_vimplus_on_ubuntu
    else
        echo "Not support linux distro: "${distro}
    fi
}

# main函数
function main()
{
    begin=`get_now_timestamp`

    type=$(uname)
    echo "Platform type: "${type}

    if [[ ${type} == "Linux" ]]; then
        install_vimplus_on_linux
    else
        echo "Not support platform type: "${type}
    fi

    end=`get_now_timestamp`
    second=`expr ${end} - ${begin}`
    min=`expr ${second} / 60`
    echo "It takes "${min}" minutes."
}

# 调用main函数
source ${HOME}/.local/env.sh
echo "python version: "$(python3 --version)
echo "cmake  version: "$(cmake --version)
main