#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Function to display progress
function print_message {
  echo -e "\e[1;34m$1\e[0m"
}

# Clear temporary files
print_message "Cleaning temporary files..."
rm -rf /tmp/* /var/tmp/*

# Clear user-level cache (for all users)
print_message "Cleaning user cache..."
for user in /home/*; do
  if [ -d "$user" ]; then
    rm -rf "$user"/.cache/*
    rm -rf "$user"/.local/share/Trash/*
  fi
done

# Clean package cache for apt (Debian/Ubuntu-based systems)
if command -v apt > /dev/null; then
  print_message "Cleaning apt package cache..."
  apt-get clean
  apt-get autoremove -y
fi

# Clean package cache for yum/dnf (RHEL/CentOS-based systems)
if command -v yum > /dev/null || command -v dnf > /dev/null; then
  print_message "Cleaning yum/dnf package cache..."
  yum clean all || dnf clean all
  yum autoremove -y || dnf autoremove -y
fi

# Clean journal logs
print_message "Cleaning systemd journal logs..."
journalctl --vacuum-time=7d

# Clear system logs
print_message "Cleaning system logs..."
find /var/log -type f -name "*.log" -delete

# Remove orphaned packages
if command -v deborphan > /dev/null; then
  print_message "Removing orphaned packages..."
  deborphan | xargs apt-get -y remove --purge
fi

# Clean Docker system if installed
if command -v docker > /dev/null; then
  print_message "Cleaning Docker system..."
  docker system prune -af
  docker volume prune -f
fi

print_message "System cleanup completed successfully!"

# Install script
if [[ $1 == "--install" ]]; then
  print_message "Installing cleanup script..."
  cp "$0" /home/.cleanup.sh
  chmod +x /home/.cleanup.sh

  print_message "Creating alias 'clean'..."
  echo "alias clean='sudo /home/.cleanup.sh'" >> ~/.bash_aliases
  source ~/.bash_aliases

  print_message "Installation completed! Use 'clean' command to run the script."
  exit 0
fi
