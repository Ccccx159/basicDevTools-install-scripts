#!/bin/bash

script_path=$(dirname $(readlink -f $0))

# if [[ "$USER" == "root" ]]; then
  # 替换镜像源，并更新软件源
  echo $1 | sudo -S cp /etc/apt/sources.list /etc/apt/sources.list.bak
  echo $1 | sudo -S sed -i 's/[a-zA-Z0-9.]*\.*archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
  echo $1 | sudo -S sed -i 's/[a-zA-Z0-9.]*\.*security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
  echo $1 | sudo -S apt-get update -y 
  echo $1 | sudo -S apt-get upgrade -y

  # 优先安装 tzdata，避免安装过程中出现交互式配置时阻塞
  echo $1 | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
  echo $1 | sudo -S ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

  # 安装常用开发软件和部分常见依赖模块
  echo $1 | sudo -S apt-get install -y sudo net-tools wget curl git g++ gcc gdb      \
                     make build-essential libssl-dev zlib1g-dev libncurses5-dev      \
                     libncursesw5-dev libreadline-dev libsqlite3-dev libgdbm-dev     \
                     libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev tk-dev        \
                     libffi-dev zsh
  if [[ "$?" -ne "0" ]]; then
    echo "install basic software failed, please check the error message"
    exit 1
  fi
# fi

USER_NAME=$(whoami)
if [[ "$USER_NAME" == "root" ]]; then
  echo "current user is root, please run this script with non-root user"
  exit 1
fi

# 比较两个版本号的大小
# 返回值：0 表示两个版本号相等，1 表示 $1 大于 $2，-1 表示 $1 小于 $2
function version_compare() {
  local v1=$1
  local v2=$2
  local IFS=.
  local i ver1=($v1) ver2=($v2)
  # 比较主版本号、次版本号、修订版本号
  for i in 0 1 2; do
      if [[ -z ${ver1[i]} ]]; then
        # 如果 $1 的版本号位数不足 $2，则 $1 小于 $2
        echo "-1"
        exit 0
      elif [[ -z ${ver2[i]} ]]; then
        # 如果 $2 的版本号位数不足 $1，则 $1 大于 $2
        echo "1"
        exit 0
      elif (( 10#${ver1[i]} > 10#${ver2[i]} )); then
        # 如果 $1 的当前版本号大于 $2，则 $1 大于 $2
        echo "1"
        exit 0
      elif (( 10#${ver1[i]} < 10#${ver2[i]} )); then
        # 如果 $1 的当前版本号小于 $2，则 $1 小于 $2
        echo "-1"
        exit 0
      fi
  done
  # 如果 $1 和 $2 的版本号相等，则返回 0
  echo "0"
  exit 0
}

# 源码编译安装cmake
cm_version=$(curl -fsSL https://cmake.org/download/ | grep "Latest Release" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*")
cur_cm_version=$(cmake --version | grep -oE "[0-9]*\.[0-9]*\.[0-9]*")
# 如果cmake不存在，或者当前版本小于最新版本，则安装cmake
if [[ ! -x "$(command -v cmake)" ]] || [[ "$(version_compare ${cur_cm_version} ${cm_version})" -eq "-1" ]]; then
  echo "cmake is not installed or version is lower than ${version}, install cmake now"
  mkdir -p /tmp/cmake && cd /tmp/cmake && wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v${cm_version}/cmake-${cm_version}.tar.gz
  tar -xzvf cmake-${cm_version}.tar.gz && cd cmake-${cm_version}
  ./configure --prefix=${HOME}/.local/cmake && make -j`nproc` && make install -j`nproc`
  if [[ "$?" -ne "0" ]]; then
    echo "cmake install failed, please check the error message" >> ${script_path}/error.log
  else
    echo "export PATH=${HOME}/.local/cmake/bin:\$PATH" >> ${HOME}/.local/env.sh
    source ${HOME}/.local/env.sh
    cd ${script_path} && rm -rf /tmp/cmake
  fi
else
  echo "cmake is already installed and version is higher than ${cm_version}, skip install cmake"
fi

# 编译安装 openssl
if [[ -d "${HOME}/.local/openssl" ]]; then
  echo "openssl is already installed, skip install openssl"
else
  cd /tmp && git clone https://github.com/openssl/openssl.git
  cd openssl && ./Configure --prefix=${HOME}/.local/openssl && make -j`nproc` && make install -j`nproc`
  if [[ "$?" -ne "0" ]]; then
    echo "openssl install failed, please check the error message" >> ${script_path}/error.log
  else
    echo "export PATH=${HOME}/.local/openssl/bin:\$PATH" >> ${HOME}/.local/env.sh
    echo "export LD_LIBRARY_PATH=${HOME}/.local/openssl/lib64:\$LD_LIBRARY_PATH" >> ${HOME}/.local/env.sh
    source ${HOME}/.local/env.sh
  fi
  cd ${script_path} && rm -rf /tmp/openssl
fi


# 源码编译安装python
py_verison=$(curl -fsSL https://www.python.org/ | grep -i 'latest' | grep -oE "[0-9]*\.[0-9]*\.[0-9]*")
cur_py_version=$(python3 --version | grep -oE "[0-9]*\.[0-9]*\.[0-9]*")
if [[ ! -x $(command -v python3) ]] || [[ "$(version_compare "${cur_py_version}" "${py_verison}")" -eq "-1" ]]; then
  echo "python3 is not installed or version is lower than ${py_verison}, install python3 now"
  mkdir -p /tmp/python3 && cd /tmp/python3
  curl -O https://www.python.org/ftp/python/${py_verison}/Python-${py_verison}.tgz
  tar -xzvf Python-${py_verison}.tgz && cd Python-${py_verison}
  ./configure --prefix=${HOME}/.local/python3 --enable-shared --disable-test-modules && make -j`nproc` && make install -j`nproc`
  if [[ "$?" -ne "0" ]]; then
    echo "python3 install failed, please check the error message"
  else
    echo "export PATH=${HOME}/.local/python3/bin:\$PATH" >> ${HOME}/.local/env.sh
    echo "export LD_LIBRARY_PATH=${HOME}/.local/python3/lib:\$LD_LIBRARY_PATH" >> ${HOME}/.local/env.sh
    source ${HOME}/.local/env.sh
  fi
  cd ${script_path} && rm -rf /tmp/python3
else
  echo "python3(${cur_py_version}) is already installed and version is higher than ${py_verison}, skip install python3"
fi

# 源码编译安装vim-plus
# 检查是否已经安装了 vim-plus
if [[ -d "${HOME}/.vimplus" ]]; then
  echo "vim-plus is already installed, skip install vim-plus"
else
  echo "vim-plus is not installed, install vim-plus now"
  git clone https://github.com/chxuan/vimplus.git ${HOME}/.vimplus
  cp ${script_path}/vimplus-install.sh ${HOME}/.vimplus && cd ${HOME}/.vimplus && chmod +x vimplus-install.sh && ./vimplus-install.sh
fi

# 安装 oh-my-zsh
if [[ -d "${HOME}/.oh-my-zsh" ]]; then
  echo "oh-my-zsh is already installed, skip install oh-my-zsh"
else
  echo "oh-my-zsh is not installed, install oh-my-zsh now"
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
  cp ${script_path}/my_awesomepanda.zsh-theme ${HOME}/.oh-my-zsh/custom/themes/
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="my_awesomepanda"/g' ${HOME}/.zshrc
  # 安装命令行语法高亮插件
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  # 安装命令行
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  sed -i 's/plugins=(git)/plugins=(git z extract zsh-syntax-highlighting zsh-autosuggestions)/g' ${HOME}/.zshrc
  cp ${script_path}/.keybind.zsh ${HOME}/.oh-my-zsh/
  echo "source ${HOME}/.oh-my-zsh/.keybind.zsh" >> ${HOME}/.local/env.sh 
fi

# 安装 code-server
if [[ -x $(command -v code-server) ]]; then
  echo "code-server is already installed, skip install code-server"
else
  echo "code-server is not installed, install code-server now"
  cs_version=$(curl -fsSL https://code-server.dev/install.sh | sh -s -- --dry-run | grep -oE 'code-server_[0-9]*\.[0-9]*\.[0-9]*' | grep --max-count=1 -oE '[0-9]*\.[0-9]*\.[0-9]*')
  echo "code-server version is ${cs_version}"
  echo "download binary file from https://github.com/coder/code-server/releases/download/v${cs_version}/code-server_${cs_version}_amd64.deb"
  mkdir -p /tmp/code-server && cd /tmp/code-server
  curl -fLO https://github.com/coder/code-server/releases/download/v${cs_version}/code-server_${cs_version}_amd64.deb
  echo $1 | sudo -S dpkg -i code-server_${cs_version}_amd64.deb
  if [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
    echo $1 | sudo -S systemctl enable --now code-server@$USER
    if [[ $(systemctl status code-server@$USER | awk '$2 ~ /active/ && $3 ~ /running/ {print "Success"}') != "Success" ]]; then
      echo "E: code-server start failed, please check the error message"
    else
      echo "code-server start success"
    fi
  else
    echo "No systemd, skip enable code-server service"
    echo "You need to start code-server manually"
  fi
  
  rm -rf /tmp/code-server
fi


# 将环境设置写入到 .bashrc 文件中，启动终端时自动加载
if [[ -f "${HOME}/.local/env.sh" ]]; then
  if [[ -f "${HOME}/.zshrc" ]]; then
    if grep -q "zsh" ${HOME}/.profile; then
      echo "zsh is already set as default shell, skip set zsh as default shell"
    else
      echo "zsh" >> ${HOME}/.profile
    fi
    if grep -q ".local/env.sh" ${HOME}/.zshrc; then
      echo "env.sh is already loaded in .zshrc, skip load env.sh in .zshrc"
    else
      echo "source ${HOME}/.local/env.sh" >> ${HOME}/.zshrc
    fi
  elif [[ -f "${HOME}/.bashrc" ]]; then
    if grep -q ".local/env.sh" ${HOME}/.bashrc; then
      echo "env.sh is already loaded in .bashrc, skip load env.sh in .bashrc"
    else
      echo "source ${HOME}/.local/env.sh" >> ${HOME}/.bashrc
    fi
  else
    if grep -q ".local/env.sh" ${HOME}/.profile; then
      echo "env.sh is already loaded in .profile, skip load env.sh in .profile"
    else
      echo "source ${HOME}/.local/env.sh" >> ${HOME}/.profile
    fi
  fi
fi

cd ${script_path}