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
  echo "  --update    Update the script by fetching and pulling the latest changes from GitHub."
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
  install_path="$user_home/cleanup_script.sh"

  cp "$0" "$install_path" || { echo "Failed to copy the script to $install_path"; exit 1; }
  chmod +x "$install_path" || { echo "Failed to set execute permission"; exit 1; }

  if [[ -f "$user_home/.bash_aliases" ]]; then
    echo "alias cleanup='bash $install_path'" >> "$user_home/.bash_aliases"
  else
    echo "alias cleanup='bash $install_path'" > "$user_home/.bash_aliases"
  fi

  print_message "Script installed successfully!"
  print_message "Alias 'cleanup' has been added to your .bash_aliases."
  print_message "Please run 'source ~/.bash_aliases' or restart your terminal to activate the alias."
  exit 0
}

# Function to update the script from GitHub
update_script() {
  print_message "Checking for script updates from GitHub..."

  # Git repository URL (replace with your repository's URL)
  repo_url="https://github.com/yourusername/yourrepo.git"
  temp_dir=$(mktemp -d)

  # Clone the repository into a temporary directory and check for updates
  git clone "$repo_url" "$temp_dir" || { echo "Failed to clone repository"; exit 1; }
  cd "$temp_dir" || exit 1

  # Fetch latest changes and pull the latest commit
  git fetch --all || { echo "Failed to fetch updates"; exit 1; }
  git pull origin main || { echo "Failed to pull the latest changes"; exit 1; }

  # Replace the current script with the updated one
  cp "$temp_dir/cleanup_script.sh" "$0" || { echo "Failed to update the script"; exit 1; }

  print_message "Script updated successfully!"
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

  clean_files "/tmp" "temporary"
  clean_files "/var/tmp" "temporary"

  print_message "Clearing all systemd journals..."
  journalctl --vacuum-size=50M || { echo "Failed to clean systemd journals"; exit 1; }

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

  for user_dir in /home/*; do
    if [[ -d "$user_dir" ]]; then
      print_message "Cleaning hidden cache files in $user_dir..."
      rm -rf "$user_dir"/.cac

