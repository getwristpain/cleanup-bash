#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Function to display styled messages
function print_message {
  echo -e "\e[1;34m$1\e[0m"
}

# Function to display help
function display_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --help      Display this help message and exit."
  echo "  --install   Install this script to the user's home directory and set up alias."
  echo ""
  echo "Description:"
  echo "This script performs a comprehensive system cleanup by removing unnecessary files,"
  echo "orphaned packages, hidden cache files, and old kernels. It also offers options for"
  echo "installing the script to your home directory and setting up an alias for quick access."
  exit 0
}

# Function to install the script and create alias
function install_script {
  print_message "Installing the cleanup script to the user's home directory..."

  # Get the current user's home directory
  user_home=$(eval echo ~$SUDO_USER)

  # Define the installation location
  install_path="$user_home/cleanup_script.sh"

  # Copy the script to the user's home directory
  cp "$0" "$install_path" || { echo "Failed to copy the script to $install_path"; exit 1; }

  # Set permissions to make the script executable
  chmod +x "$install_path" || { echo "Failed to set execute permission"; exit 1; }

  # Add alias to .bash_aliases
  if [[ -f "$user_home/.bash_aliases" ]]; then
    echo "alias cleanup='bash $install_path'" >> "$user_home/.bash_aliases"
  else
    echo "alias cleanup='bash $install_path'" > "$user_home/.bash_aliases"
  fi

  # Inform the user to reload their shell or source the .bash_aliases
  print_message "Script installed successfully!"
  print_message "Alias 'cleanup' has been added to your .bash_aliases."
  print_message "Please run 'source ~/.bash_aliases' or restart your terminal to activate the alias."
  exit 0
}

# Check for command-line arguments
if [[ "$1" == "--help" ]]; then
  display_help
elif [[ "$1" == "--install" ]]; then
  install_script
fi

# Function to clean up unnecessary files
function clean_files {
  local target_dir=$1
  local file_type=$2

  if [[ -d "$target_dir" ]]; then
    print_message "Cleaning $file_type files in $target_dir..."
    find "$target_dir" -type f -exec rm -f {} \; || {
      echo "Failed to clean $file_type files in $target_dir"
      return 1
    }
    print_message "Cleaned $file_type files in $target_dir successfully!"
  else
    echo "Directory $target_dir does not exist, skipping..."
  fi
}

# Deep clean function
function deep_clean {
  print_message "Starting deep clean for all unnecessary system files..."

  # Remove all files in /tmp and /var/tmp
  clean_files "/tmp" "temporary"
  clean_files "/var/tmp" "temporary"

  # Clear systemd journals
  print_message "Clearing all systemd journals..."
  journalctl --vacuum-size=50M || { echo "Failed to clean systemd journals"; exit 1; }

  # Remove unnecessary apt/yum/dnf cache
  if command -v apt > /dev/null; then
    print_message "Cleaning APT cache..."
    apt-get clean || { echo "Failed to clean APT cache"; exit 1; }
  fi

  if command -v yum > /dev/null || command -v dnf > /dev/null; then
    print_message "Cleaning YUM/DNF cache..."
    if command -v yum > /dev/null; then
      yum clean all || { echo "Failed to clean YUM cache"; exit 1; }
    elif command -v dnf > /dev/null; then
      dnf clean all || { echo "Failed to clean DNF cache"; exit 1; }
    fi
  fi

  # Clean hidden caches in home directories
  for user_dir in /home/*; do
    if [[ -d "$user_dir" ]]; then
      print_message "Cleaning hidden cache files in $user_dir..."
      rm -rf "$user_dir"/.cache/* || { echo "Failed to clean .cache for $user_dir"; exit 1; }
      rm -rf "$user_dir"/.local/share/Trash/* || { echo "Failed to clean trash for $user_dir"; exit 1; }
      rm -rf "$user_dir"/.config/* || { echo "Failed to clean .config for $user_dir"; exit 1; }
    fi
  done

  # Clean orphaned packages on Debian systems
  if command -v deborphan > /dev/null; then
    print_message "Removing orphaned packages..."
    deborphan | xargs apt-get -y remove --purge || { echo "Failed to remove orphaned packages"; exit 1; }
  fi

  # Clean Docker system (if installed)
  if command -v docker > /dev/null; then
    print_message "Cleaning up Docker system..."
    docker system prune -af || { echo "Failed to prune Docker system"; exit 1; }
    docker volume prune -f || { echo "Failed to prune Docker volumes"; exit 1; }
    docker image prune -a --filter "until=24h" -f || { echo "Failed to prune Docker images"; exit 1; }
  fi

  # Additional system-wide cleanup
  print_message "Removing old kernels (if applicable)..."
  if command -v dpkg > /dev/null; then
    dpkg --list | grep 'linux-image' | awk '{ print $2 }' | grep -v $(uname -r) | xargs apt-get -y purge || {
      echo "Failed to remove old kernels"
      exit 1
    }
  fi

  print_message "Deep clean completed successfully!"
}

# Confirm and execute deep clean
while true; do
  read -p "Do you want to perform a deep clean of the system? (yes/no) [yes]: " deep_clean_choice
  deep_clean_choice=${deep_clean_choice:-yes}
  case "$deep_clean_choice" in
    [Yy]*)
      deep_clean
      break
      ;;
    [Nn]*)
      print_message "Deep clean skipped."
      exit 0
      ;;
    *)
      echo "Please answer yes or no."
      ;;
  esac
done

# Confirm and execute system reboot
while true; do
  read -p "Do you want to reboot the system now? (yes/no) [yes]: " reboot_choice
  reboot_choice=${reboot_choice:-yes}
  case "$reboot_choice" in
    [Yy]*)
      print_message "Rebooting the system..."
      reboot
      break
      ;;
    [Nn]*)
      print_message "Reboot skipped. You can reboot later if needed."
      break
      ;;
    *)
      echo "Please answer yes or no."
      ;;
  esac
done

