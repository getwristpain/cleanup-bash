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
    [Yy][Ee][Ss])
      deep_clean
      break
      ;;
    [Nn][Oo])
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
  reboot_choice=${reboot_choice:-yes} # Default to "yes" if no input is provided
  case "$reboot_choice" in
    [Yy][Ee][Ss])
      print_message "Rebooting the system..."
      reboot
      break
      ;;
    [Nn][Oo])
      print_message "Reboot skipped. You can reboot later if needed."
      break
      ;;
    *)
      echo "Please answer yes or no."
      ;;
  esac
done

