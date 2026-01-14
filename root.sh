#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      Foxytoux INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#                           Now with Debian 11 (Bullseye)"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Debian 11? (YES/no): " install_debian
fi

case $install_debian in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-${ARCH_ALT}.tar.gz"
    
    # Fallback URL nếu link trên không hoạt động
    if [ $? -ne 0 ]; then
      echo "Trying alternative Debian 11 rootfs URL..."
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "https://github.com/debuerreotype/docker-debian-artifacts/raw/dist-${ARCH_ALT}/bullseye/rootfs.tar.xz"
    fi
    
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Debian installation."
    ;;
esac

if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir $ROOTFS_DIR/usr/local/bin -p
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  
  # Tạo file sources.list cho Debian 11
  cat > ${ROOTFS_DIR}/etc/apt/sources.list << 'EOF'
# Debian 11 Bullseye
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
  
  # Xóa cache Ubuntu nếu có
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin ${ROOTFS_DIR}/var/lib/apt/lists/*
  
  # Chạy lệnh cơ bản để cài đặt trong Debian
  $ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    /usr/bin/apt-get update || true
  
  touch $ROOTFS_DIR/.installed
fi

CYAN='\e[0;36m'
WHITE='\e[0;37m'

RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
  echo -e "           ${CYAN}Debian 11 (Bullseye) Installed!${RESET_COLOR}"
}

clear
display_gg

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
