#!/bin/bash

# Запрос данных для переменных
read -p "username (USER): " USER
read -p "hostname (HOST): " HOST
read -p "path to install (e.g., /dev/sda1): " PATH

pacman -Sy
pacman -S archlinux-keyring --noconfirm

mkfs.btrfs -L arch $PATH
mount $PATH /mnt

btrfs su cr /mnt/@
btrfs su cr /mnt/@home

umount -R /mnt

mount -o subvol=/@,noatime,compress=lzo $PATH /mnt
mkdir /mnt/home
mount -o subvol=/@home,noatime,compress=lzo $PATH /mnt/home

pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys 9AE4078033F8024D 3056513887B78AEB
pacman-key --lsign-key 9AE4078033F8024D 3056513887B78AEB

pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e '\n[liquorix]\nServer = https://liquorix.net/archlinux/$repo/$arch' | sudo tee -a '/etc/pacman.conf' > /dev/null
echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a '/etc/pacman.conf' > /dev/null

sudo sed -i 's/^#*\(ParallelDownloads\s*=\s*\).*/\110/' /etc/pacman.conf

pacman -Sy

pacstrap /mnt base base-devel linux-lqx linux-lqx-headers linux-firmware networkmanager chaotic-keyring chaotic-mirrorlist intel-ucode git nano curl zsh aura --needed --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

echo -e '\n[liquorix]\nServer = https://liquorix.net/archlinux/$repo/$arch' | sudo tee -a '/etc/pacman.conf' > /dev/null
echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a '/etc/pacman.conf' > /dev/null

sed -i 's/^#*\(ParallelDownloads\s*=\s*\).*/\110/' /etc/pacman.conf

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

useradd -mG wheel -s /bin/zsh $USER
passwd $USER
echo "$USER ALL=(ALL:ALL) ALL" >> /etc/sudoers
visudo -c

sudo pacman -Sy grub

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

sudo pacman -S xfce4 (garcon thunar thunar-volman tumbler xfce4-appfinder 
xfce4-panel xfce4-power-manager xfce4-session xfce4-settings xfconf xfdesktop xfwm4) [2,3,4,5,6,7,8,9,10,11,12,13]
 
xfce4-goodies (mousepad thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin 
xfce4-pulseaudio-plugin xfce4-taskmanager xfce4-whiskermenu-plugin) [1, 5, 8, 9, 24, 30, 36]

sudo pacman -S lightdm lightdm-gtk-greeter st xorg network-manager-applet --needed
exit
umount -R /mnt
