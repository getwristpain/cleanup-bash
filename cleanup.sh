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

# Check if script is already installed
if [[ -f "$HOME/.cleanup.sh" ]]; then
  if [[ "$0" == *"clean"* ]]; then
    print_message "Skrip sudah terinstal, menggunakan perintah 'clean'. Tidak perlu --install lagi."
    exit 0
  else
    print_message "Cleanup script sudah diinstal sebelumnya. Menonaktifkan --install flag."
  fi
fi

# Clear temporary files
print_message "Cleaning temporary files..."
rm -rf /tmp/* /var/tmp/* || { echo "Failed to clean temporary files"; exit 1; }

# Clear user-level cache (for all users)
print_message "Cleaning user cache..."
for user in /home/*; do
  if [ -d "$user" ]; then
    rm -rf "$user"/.cache/* || { echo "Failed to clean cache for $user"; exit 1; }
    rm -rf "$user"/.local/share/Trash/* || { echo "Failed to clean Trash for $user"; exit 1; }
  fi
done

# Clean package cache for apt (Debian/Ubuntu-based systems)
if command -v apt > /dev/null; then
  print_message "Cleaning apt package cache..."
  apt-get clean || { echo "Failed to clean apt cache"; exit 1; }
  apt-get autoremove -y || { echo "Failed to autoremove apt packages"; exit 1; }
fi

# Clean package cache for yum/dnf (RHEL/CentOS-based systems)
if command -v yum > /dev/null || command -v dnf > /dev/null; then
  print_message "Cleaning yum/dnf package cache..."
  if command -v yum > /dev/null; then
    yum clean all || { echo "Failed to clean yum cache"; exit 1; }
    yum autoremove -y || { echo "Failed to autoremove yum packages"; exit 1; }
  elif command -v dnf > /dev/null; then
    dnf clean all || { echo "Failed to clean dnf cache"; exit 1; }
    dnf autoremove -y || { echo "Failed to autoremove dnf packages"; exit 1; }
  fi
fi

# Clean journal logs
print_message "Cleaning systemd journal logs..."
journalctl --vacuum-time=7d || { echo "Failed to clean journal logs"; exit 1; }

# Clear system logs
print_message "Cleaning system logs..."
find /var/log -type f -name "*.log" -exec rm -f {} \; || { echo "Failed to clean system logs"; exit 1; }

# Remove orphaned packages (Debian-based systems)
if command -v deborphan > /dev/null; then
  print_message "Removing orphaned packages..."
  deborphan | xargs apt-get -y remove --purge || { echo "Failed to remove orphaned packages"; exit 1; }
fi

# Clean Docker system if installed
if command -v docker > /dev/null; then
  print_message "Cleaning Docker system..."
  docker system prune -af || { echo "Failed to prune Docker system"; exit 1; }
  docker volume prune -f || { echo "Failed to prune Docker volumes"; exit 1; }
fi

print_message "System cleanup completed successfully!"

# Install script if --install argument is passed
if [[ $1 == "--install" ]]; then
  print_message "Installing cleanup script..."

  # Get the original user who ran the script with sudo
  if [ -z "$SUDO_USER" ]; then
    echo "Error: SUDO_USER is not set. Please run this script with sudo."
    exit 1
  fi

  # Get home directory of the original user
  USER_HOME=$(eval echo ~$SUDO_USER)

  if [ ! -d "$USER_HOME" ]; then
    echo "Error: Home directory for user $SUDO_USER does not exist."
    exit 1
  fi

  # Use absolute path to the script
  SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")  # Get the absolute path of the script
  echo "Copying script from $SCRIPT_PATH to $USER_HOME/.cleanup.sh"
  cp "$SCRIPT_PATH" "$USER_HOME/.cleanup.sh" || { echo "Failed to copy cleanup script"; exit 1; }

  chmod +x "$USER_HOME/.cleanup.sh" || { echo "Failed to make cleanup script executable"; exit 1; }

  print_message "Creating alias 'clean'..."

  # Check if the alias 'clean' already exists
  if ! grep -q "alias clean=" "$USER_HOME/.bash_aliases"; then
    echo "alias clean='sudo $USER_HOME/.cleanup.sh'" >> "$USER_HOME/.bash_aliases" || { echo "Failed to create alias"; exit 1; }
  else
    print_message "Alias 'clean' already exists. Skipping alias creation."
  fi

  # Ensure .bash_aliases is sourced in .bashrc
  if ! grep -q "source $USER_HOME/.bash_aliases" "$USER_HOME/.bashrc"; then
    echo "source $USER_HOME/.bash_aliases" >> "$USER_HOME/.bashrc" || { echo "Failed to add source command to .bashrc"; exit 1; }
  fi

  # Reload the shell configuration files
  echo "Sourcing $USER_HOME/.bash_aliases and $USER_HOME/.bashrc to apply changes..."
  source $USER_HOME/.bash_aliases || { echo "Failed to source .bash_aliases"; exit 1; }
  source $USER_HOME/.bashrc || { echo "Failed to source .bashrc"; exit 1; }

  print_message "Installation completed! Use 'clean' command to run the script."
  exit 0
fi

