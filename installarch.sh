#!/usr/bin/env bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Запрос данных для переменных
read -p "username (USER): " USER
read -p "hostname (HOST): " HOST
read -p "path to install (e.g., /dev/sda1): " DRIVE

pacman -Sy
pacman -S archlinux-keyring --noconfirm

mkfs.ext4 -L arch $DRIVE
mount $DRIVE /mnt

umount -R /mnt

mount -o -o noatime,commit=60,discard=async $DRIVE /mnt
mkdir /mnt/home
mount -o noatime,commit=60,discard=async $DRIVE /mnt/home

pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys 9AE4078033F8024D 3056513887B78AEB
pacman-key --lsign-key 9AE4078033F8024D 3056513887B78AEB

pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
echo -e '\n[liquorix]\nServer = https://liquorix.net/archlinux/$repo/$arch\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf > /dev/null && sudo sed -i 's/^#*\(ParallelDownloads\s*=\s*\).*/\110/' /etc/pacman.conf

pacman -Sy

pacstrap /mnt base base-devel linux-lqx linux-lqx-headers linux-firmware networkmanager chaotic-keyring chaotic-mirrorlist intel-ucode git nano curl zsh paru --needed --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash -c "
echo -e '\n[liquorix]\nServer = https://liquorix.net/archlinux/\$repo/\$arch\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | tee -a /etc/pacman.conf > /dev/null &&
sed -i 's/^#*\(ParallelDownloads\s*=\s*\).*/\110/' /etc/pacman.conf &&
echo '$HOST' > /etc/hostname &&
echo -e '127.0.0.1 localhost\n::0 localhost\n127.0.0.1 $HOST' >> /etc/hosts &&
systemctl enable NetworkManager &&
systemctl mask NetworkManager-wait-online.service &&
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime &&
hwclock --systohc &&
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen &&
locale-gen &&
echo 'LANG=en_US.UTF-8' > /etc/locale.conf &&
echo 'Set root password' &&
passwd &&
useradd -mG wheel -s /bin/zsh '$USER' &&
echo 'Set password for user $USER' &&
passwd '$USER' &&
echo '$USER ALL=(ALL:ALL) ALL' >> /etc/sudoers &&
visudo -c &&
pacman -Sy grub --noconfirm &&
grub-install /dev/sda &&
grub-mkconfig -o /boot/grub/grub.cfg &&
pacman -S garcon thunar thunar-volman tumbler xfce4-appfinder xfce4-panel xfce4-power-manager xfce4-session xfce4-settings xfconf xfdesktop xfwm4 mousepad thunar-media-tags-plugin xfce4-battery-plugin xfce4-clipman-plugin xfce4-pulseaudio-plugin xfce4-taskmanager xfce4-whiskermenu-plugin --noconfirm &&
pacman -S lightdm lightdm-gtk-greeter st xorg network-manager-applet --needed --noconfirm &&
systemctl enable lightdm.service

# Загрузка конфигов XFCE4
mkdir -p /etc/xdg/xfce4-configs &&
curl -L 'https://raw.githubusercontent.com/DavidsTens/archinstall/refs/heads/main/xfce4-configs/xfce4-panel.xml' -o /etc/xdg/xfce4-configs/xfce4-panel.xml &&
curl -L 'https://raw.githubusercontent.com/DavidsTens/archinstall/refs/heads/main/xfce4-configs/xfce4-desktop.xml' -o /etc/xdg/xfce4-configs/xfce4-desktop.xml &&

# Копирование конфигов в домашнюю папку пользователя
mkdir -p /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml &&
cp /etc/xdg/xfce4-configs/xfce4-panel.xml /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/ &&
cp /etc/xdg/xfce4-configs/xfce4-desktop.xml /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/ &&
chown -R $USER:$USER /home/$USER/.config/xfce4 &&
echo 'XFCE4 configuration applied successfully.'
"

umount -R /mnt
