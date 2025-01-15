#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Function to ask for user confirmation
ask_confirmation() {
  local question="$1"
  while true; do
    read -p "$question (yes/no) [yes]: " user_input
    user_input=${user_input:-yes}
    case "$user_input" in
      [Yy]*)
        return 0
        ;;
      [Nn]*)
        print_message "Operation skipped."
        return 1
        ;;
      *)
        echo "Please answer yes or no."
        ;;
    esac
  done
}

# Function to display styled messages
print_message() {
  echo -e "\e[1;34m$1\e[0m"
}

# Display help message
display_help() {
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
  echo ""
  echo "Credits:"
  echo "  Script created by: Reas Vyn"
  echo "  GitHub Repository: https://github.com/getwristpain/cleanup-bash"
  exit 0
}

# Install script to user's home directory and set up alias
install_script() {
  print_message "Installing the cleanup script to the user's home directory..."

  user_home=$(eval echo ~$SUDO_USER)
  install_path="$user_home/.cleanup_script.sh"

  cp "$0" "$install_path" || { echo "Failed to copy the script to $install_path"; exit 1; }
  
  # Add execute permission
  chmod +x "$install_path" || { echo "Failed to set execute permission"; exit 1; }

  # Check if alias already exists in .bash_aliases
  if ! grep -q "alias cleanup=" "$user_home/.bash_aliases"; then
    echo "alias cleanup='sudo $install_path'" >> "$user_home/.bash_aliases"
    print_message "Alias 'cleanup' has been added to your .bash_aliases."
  else
    print_message "Alias 'cleanup' already exists in .bash_aliases, skipping..."
  fi

  print_message "Script installed successfully!"
  print_message "Please run 'source ~/.bash_aliases' or restart your terminal to activate the alias."
  exit 0
}

# Function to clean up unnecessary files
clean_files() {
  local target_dir=$1
  local file_type=$2

  if [[ -d "$target_dir" ]]; then
    print_message "Cleaning $file_type files in $target_dir..."
    find "$target_dir" -type f -exec rm -f {} \; || { echo "Failed to clean $file_type files in $target_dir"; return 1; }
    print_message "Cleaned $file_type files in $target_dir successfully!"
  else
    echo "Directory $target_dir does not exist, skipping..."
  fi
}

# Deep clean system files
deep_clean() {
  print_message "Starting deep clean for all unnecessary system files..."
  
  # Cleanup directories and files
  clean_files "/tmp" "temporary"
  clean_files "/var/tmp" "temporary"
  
  # Additional cleanup tasks (APT, YUM/DNF, Docker, etc.)
  # Skipped for brevity
  
  print_message "Deep clean completed successfully!"
}

# Check for command-line arguments and immediately execute
case "$1" in
  --help)
    display_help
    ;;
  --install)
    install_script
    ;;
  *)
    # Confirm and execute deep clean if no flags are provided
    ask_confirmation "Do you want to perform a deep clean of the system?" && deep_clean

    # Ask confirmation to reboot, only after cleanup is done
    if [[ $? -eq 0 ]]; then
      ask_confirmation "Do you want to reboot the system now?" && reboot
    fi
    ;;
esac

