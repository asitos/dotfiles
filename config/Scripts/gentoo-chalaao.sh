#!/bin/bash
echo "Mounting Gentoo and entering chroot..."

# Mount root
sudo mount /dev/nvme0n1p4 /mnt

# Safety check: Ensure the boot folder exists before mounting
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

# Pass internet (THE FIX IS HERE)
sudo cp -L /etc/resolv.conf /mnt/etc/

# Mount hardware APIs
sudo mount -t proc /proc /mnt/proc
sudo mount --rbind /sys /mnt/sys
sudo mount --make-rslave /mnt/sys
sudo mount --rbind /dev /mnt/dev
sudo mount --make-rslave /mnt/dev
sudo mount --bind /run /mnt/run
sudo mount --make-slave /mnt/run

# Enter the matrix
sudo chroot /mnt /bin/bash -c "source /etc/profile; export PS1='(gentoo) \w \$ '; exec bash"

# Cleanup after you type 'exit'
echo "Exiting chroot. Unmounting drives cleanly..."
sudo umount -R /mnt
echo "Done!"
