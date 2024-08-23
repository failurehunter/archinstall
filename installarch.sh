#!/bin/bash

# Запрос данных для переменных
read -p "Введите имя будущего пользователя (USER): " USER
read -p "Введите имя компьютера (HOST): " HOST
read -p "Введите путь до раздела диска для установки (например, /dev/sda1): " PATH

sudo pacman -Sy
sudo pacman -S archlinux-keyring

mkfs.btrfs -L arch $PATH
mount $PATH /mnt

btrfs su cr /mnt/@
btrfs su cr /mnt/@home

umount -R /mnt

mount -o subvol=/@,noatime,compress=lzo $PATH /mnt
mkdir /mnt/home
mount -o subvol=/@home,noatime,compress=lzo $PATH /mnt/home

echo "liquorix"
sudo pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys 9AE4078033F8024D
sudo pacman-key --lsign-key 9AE4078033F8024D

echo -e '\n[liquorix]\nServer = https://liquorix.net/archlinux/$repo/$arch' | sudo tee -a '/etc/pacman.conf' > /dev/null

echo "chaotic-aur"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a '/etc/pacman.conf' > /dev/null

sudo pacman -Sy

pacstrap /mnt base base-devel linux-lqx linux-lqx-headers linux-firmware networkmanager intel-ucode git nano curl wget
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

echo $HOST > /etc/hostname
echo -e "127.0.0.1 localhost\n::0 localhost\n127.0.0.1 $HOST" >> /etc/hosts

systemctl enable NetworkManager
systemctl mask NetworkManager-wait-online.service

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

passwd

useradd -m $USER
passwd $USER
echo "$USER ALL=(ALL:ALL) ALL" >> /etc/sudoers
visudo -c

sudo pacman -S grub

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
reboot