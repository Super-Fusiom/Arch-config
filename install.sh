#!/bin/bash
if [ "$USER" == 'root' ] ; then
    lsblk
    read -rp "Disk to install?  " disk     
    timedatectl set-ntp true 
    cfdisk "$disk"
    read -rp "root partition number?  " rroot
    read -rp "efi partition number?  " refi
    mkfs.ext4 "${disk}${rroot}" 
    mkfs.fat -F32 "${disk}${refi}" 
    mount "${disk}${rroot}" /mnt 
    mkdir /mnt/boot /mnt/boot/efi
    mount "${disk}${refi}" /mnt/boot/efi 
    pacstrap /mnt base base-devel linux linux-firmware ntp networkmanager grub efibootmgr zsh 
    genfstab -U /mnt >> /mnt/etc/fstab 
    arch-chroot /mnt /bin/bash "ln -sf /usr/share/zoneinfo/NZ /etc/localtime; 
    vim /etc/locale.gen;
    locale-gen; echo 'LANG=en_NZ.UTF-8' >> /etc/locale.conf; echo '' >> /etc/hostname; 
    systemctl enable Networkmanager; 
    useradd -m paul; passwd paul; 
    EDITOR=vim visudo; 
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB; 
    grub-mkconfig -o /boot/grub/grub.cfg; 
    chsh -s /bin/zsh paul;
    exit;"
    cp Arch-config /mnt/home/paul
    echo "source ~/Arch-config/install.sh" >> /mnt/paul/.zshrc
    reboot;
else
    mkdir ~/.config
    mkdir ~/.themes
    cp -r dotconfig/* ~/.config
    cp dotxinitrc ~/.xinitrc
    cp -r dotthemes/* ~/.themes
    # Installing yay and getting the required packages
    cd
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd
    rm -rf yay
    yay -S bashtop bspwm gnome-shell kitty nvim polybar rofi sxhkd nautilus feh picom xorg-server dunst xorg-xinit nerd-fonts-fira-code ttf-font-awesome betterlockscreen flameshot firefox ntp
    # Enable ntp for accurate time
    sudo systemctl enable --now ntpd
    #Copy the default dunst rc file to the home directory... it will change once i've made my own config
    sudo cp /etc/dunst/dunstrc ~/.config/dunst/dunstrc
    #Ask what GPU is used for proper drivers
    while true; do
        read -rp "Do you use an amd (AMD) or nvidia (NVIDIA) gpu or is this a virtual machine(VM)?" nav
        if [ "$nav" == 'NVIDIA' ] || [ "$nav" == 'Nvidia' ] || [ "$nav" == 'nvidia' ] ; then
            yay -S nvidia nvidia-utils; break
        elif [ "$nav" == 'AMD' ] || [ "$nav" == 'amd' ] || [ "$nav" == 'Amd' ] ; then
            yay -S xf86-video-amdgpu; break
        elif [ "$nav" == 'vm' ] || [ "$nav" == 'VM' ] || [ "$nav" == 'Vm' ] ; then
            yay -S virtualbox-guest-utils; sudo systemctl enable --now vboxservice; break
        else
            echo 'Wrong choice, use either nvidia, amd or vm'
        fi
    done
    echo "PATH='$HOME/.config/rofi/bin:$PATH'" >> ~/.bashrc
    cd
    rm -rf Arch-config
    startx
fi
