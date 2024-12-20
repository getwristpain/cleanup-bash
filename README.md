# Cleanup Script

A Bash script to clean up temporary files, application cache, unused packages, and system logs. The script is designed for Linux systems and includes an optional installation mode to create a shortcut alias for easy use.

---

## Features
- Deletes temporary files and cache for all users.
- Cleans package cache for Debian/Ubuntu (APT) and RHEL/CentOS (YUM/DNF) systems.
- Removes orphaned packages.
- Clears system and journal logs.
- Optionally cleans Docker system if Docker is installed.
- Provides an installation option to create an alias `clean` for easier execution.

---

## Requirements
- Linux operating system
- Root or sudo privileges
- Optional: `deborphan` for removing orphaned packages (Debian-based systems)

---

## Usage

### Running the Script
1. Clone or download the script to your system.
2. Make the script executable:
   ```bash
   chmod +x cleanup.sh
   ```
3. Run the script with sudo:
   ```bash
   sudo ./cleanup.sh
   ```

### Installation (Optional)
You can install the script to set up an alias `clean` for quick execution:

1. Run the script with the `--install` flag:
   ```bash
   sudo ./cleanup.sh --install
   ```
2. After installation, you can simply use the `clean` command to run the cleanup script:
   ```bash
   clean
   ```

---

## Script Behavior
- **Temporary Files**: Cleans `/tmp` and `/var/tmp`.
- **User Cache**: Deletes user-specific cache from `~/.cache` and `~/.local/share/Trash`.
- **Package Cache**:
  - APT: `apt-get clean` and `apt-get autoremove`.
  - YUM/DNF: `yum clean all`/`dnf clean all` and `autoremove`.
- **Journal Logs**: Clears systemd journal logs older than 7 days.
- **System Logs**: Deletes log files in `/var/log`.
- **Orphaned Packages**: Removes packages no longer required by the system using `deborphan`.
- **Docker**: Performs `docker system prune` and `docker volume prune` to free up Docker space (if Docker is installed).

---

## Notes
- Ensure that you review the script before execution to understand its behavior and adjust as necessary for your system.
- For safety, create backups of important data before running cleanup operations.

---

## License
This script is open-source and available under the MIT License.

