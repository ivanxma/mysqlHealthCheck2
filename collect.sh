#!/bin/bash
# Comprehensive MySQL Host Diagnostics Script (Split Logs: host.log + mysql.log)
# Usage: ./mysql_host_diagnostics.sh [host] [port] [user] [password] [database] [sql_dir]
# Outputs: host_diagnostics.log + mysql_diagnostics.log

# Configuration defaults
DEFAULT_HOST="localhost"
DEFAULT_PORT="3306"
DEFAULT_USER="root"
DEFAULT_DB="mysql"
DEFAULT_SQL_DIR="./mysql_diagnostics"
HOST_LOG="${HOST_LOG:-host_diagnostics.log}"
MYSQL_LOG="${MYSQL_LOG:-mysql_diagnostics.log}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Detect OS
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macOS"
    OS_FAMILY="macOS"
else
    OS="Linux"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION_ID="${VERSION_ID:-unknown}"
        OS_PRETTY_NAME="${PRETTY_NAME:-unknown}"
        case "$OS_ID" in
            ubuntu|debian) OS_FAMILY="Debian" ;;
            rhel|centos|rocky|almalinux|fedora|ol) OS_FAMILY="RedHat" ;;
            *) OS_FAMILY="OtherLinux" ;;
        esac
    else
        OS_ID="unknown"
        OS_VERSION_ID="unknown"
        OS_PRETTY_NAME="Unknown Linux"
        OS_FAMILY="Unknown"
    fi
fi

# Parse arguments
MYSQL_HOST="${1:-$DEFAULT_HOST}"
MYSQL_PORT="${2:-$DEFAULT_PORT}"
MYSQL_USER="${3:-$DEFAULT_USER}"
MYSQL_PASSWORD="${4:-}"
MYSQL_DB="${5:-$DEFAULT_DB}"
SQL_DIR="${6:-$DEFAULT_SQL_DIR}"

# Prompt for password if not provided
if [[ -z "$MYSQL_PASSWORD" ]]; then
    read -s -p "Enter MySQL password for '$MYSQL_USER'@'$MYSQL_HOST:$MYSQL_PORT' (DB: $MYSQL_DB): " MYSQL_PASSWORD
    echo
fi

# Test connection
test_mysql_connection() {
    local result=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
                         --database="$MYSQL_DB" -Nse "SELECT 1" 2>/dev/null)
    [[ "$result" == "1" ]]
}

# Execute SQL files into MYSQL_LOG
execute_mysql_diagnostics() {
    local sql_dir="${1:-$DEFAULT_SQL_DIR}"
    echo "Executing diagnostics from: $sql_dir" | tee -a "$HOST_LOG"

    [[ -d "$sql_dir" ]] || { echo "ERROR: Directory '$sql_dir' not found." | tee -a "$HOST_LOG"; return 1; }

    if ! test_mysql_connection; then
        echo "MySQL connection failed. Aborting." | tee -a "$HOST_LOG"
        return 1
    fi

    # Initialize MySQL log
    > "$MYSQL_LOG"
    echo "MySQL Diagnostics Report" >> "$MYSQL_LOG"
    echo "Generated: $TIMESTAMP" >> "$MYSQL_LOG"
    echo "Server: $MYSQL_HOST:$MYSQL_PORT" >> "$MYSQL_LOG"
    echo "User: $MYSQL_USER" >> "$MYSQL_LOG"
    echo "Database: $MYSQL_DB" >> "$MYSQL_LOG"
    echo "SQL Directory: $sql_dir" >> "$MYSQL_LOG"
    echo "----------------------------------------" >> "$MYSQL_LOG"

    # Run helpers.sql FIRST
    local helper_file="$sql_dir/helpers.sql"
    if [[ -f "$helper_file" ]]; then
        echo "Running helpers.sql (required)..." | tee -a "$HOST_LOG"
        mysql -t -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
              --database="$MYSQL_DB" --skip-column-names --batch < "$helper_file" >> "$MYSQL_LOG" 2>&1 || \
            echo "Warning: helpers.sql had issues." >> "$HOST_LOG"
    else
        echo "ERROR: helpers.sql not found in $sql_dir" | tee -a "$HOST_LOG"
        return 1
    fi

    # Run all other SQL files
    for sql_file in "$sql_dir"/[0-9][0-9]_*.sql; do
        [[ -f "$sql_file" ]] || continue
        echo "Running $(basename "$sql_file")..." | tee -a "$HOST_LOG"
        mysql -t -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
              --database="$MYSQL_DB" --skip-column-names --batch < "$sql_file" >> "$MYSQL_LOG" 2>&1 || \
            echo "Warning: $(basename "$sql_file") had issues." >> "$HOST_LOG"
    done

    echo "MySQL diagnostics completed. Output: $MYSQL_LOG" | tee -a "$HOST_LOG"
}

# Collect OS info
collect_os_info() {
    echo "--- Operating System Information ---" >> "$HOST_LOG"
    if [[ "$OS" == "macOS" ]]; then
        echo "OS: macOS $(sw_vers -productName) $(sw_vers -productVersion)" >> "$HOST_LOG"
        echo "Build: $(sw_vers -buildVersion)" >> "$HOST_LOG"
        echo "Kernel: $(uname -r)" >> "$HOST_LOG"
    else
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "Distribution ID: $ID" >> "$HOST_LOG"
            echo "Version ID: $VERSION_ID" >> "$HOST_LOG"
            echo "Pretty Name: $PRETTY_NAME" >> "$HOST_LOG"
            echo "Family: $OS_FAMILY" >> "$HOST_LOG"
            echo "Kernel: $(uname -r)" >> "$HOST_LOG"
        else
            echo "OS detection failed." >> "$HOST_LOG"
            echo "Kernel: $(uname -r)" >> "$HOST_LOG"
        fi
    fi
    echo "" >> "$HOST_LOG"
}

# Collect CPU
collect_cpu_info() {
    echo "--- CPU Information (Detailed List) ---" >> "$HOST_LOG"
    if [[ "$OS" == "macOS" ]]; then
        sysctl -n machdep.cpu.brand_string >> "$HOST_LOG"
        echo "Cores: $(sysctl -n hw.physicalcpu)" >> "$HOST_LOG"
        echo "Threads: $(sysctl -n hw.logicalcpu)" >> "$HOST_LOG"
    else
        command -v lscpu >/dev/null && lscpu >> "$HOST_LOG" || \
            { echo "CPU cores: $(nproc)"; cat /proc/cpuinfo | grep -E 'processor|model name|cpu MHz|cache size|flags'; } >> "$HOST_LOG"
    fi
    if [[ "$OS" == "macOS" ]]; then
        echo "Load Average: $(sysctl -n vm.loadavg | sed 's/[{}]//g')" >> "$HOST_LOG"
    else
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')" >> "$HOST_LOG"
    fi
    echo "" >> "$HOST_LOG"
}

# Collect memory
collect_memory_info() {
    echo "--- Memory Usage ---" >> "$HOST_LOG"
    if [[ "$OS" == "macOS" ]]; then
        vm_stat | head -10 >> "$HOST_LOG"
        echo "Total RAM: $(sysctl -n hw.memsize | awk '{printf \"%.2f GB\", $1/1024/1024/1024}')" >> "$HOST_LOG"
    else
        command -v free >/dev/null && free -h >> "$HOST_LOG" || echo "Memory detection failed." >> "$HOST_LOG"
    fi
    echo "" >> "$HOST_LOG"
}

# Collect storage
collect_storage_info() {
    echo "--- Storage Allocation and Usage ---" >> "$HOST_LOG"
    if [[ "$OS" == "macOS" ]]; then
        df -h | grep -E '^Filesystem|/Volumes' >> "$HOST_LOG"
    else
        df -hT | grep -E '^Filesystem|/' >> "$HOST_LOG"
    fi
    echo "" >> "$HOST_LOG"
}

# Collect MySQL processes
collect_mysql_processes() {
    echo "--- MySQL/MariaDB Process Information ---" >> "$HOST_LOG"
    local pids=$(pgrep -f 'mysqld|mariadbd|mysql' 2>/dev/null || echo "")
    if [[ -n "$pids" ]]; then
        local pid_list=$(echo "$pids" | tr '\n' ',' | sed 's/,$//')
        if [[ "$OS" == "macOS" ]]; then
            ps -p "$pid_list" -o pid,ppid,user,pcpu,pmem,etime,command | sort -k4 -nr >> "$HOST_LOG"
        else
            ps -p "$pid_list" -o pid,ppid,user,%cpu,%mem,etime,cmd --sort=-%cpu >> "$HOST_LOG"
        fi
    else
        echo "No MySQL/MariaDB processes detected." >> "$HOST_LOG"
    fi
    echo "" >> "$HOST_LOG"
}

# Collect MySQL host/port
collect_mysql_host_port() {
    echo "--- MySQL Server Host and Port (Runtime) ---" >> "$HOST_LOG"
    mysql -t -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
          --database="$MYSQL_DB" -Nse "SELECT @@hostname, @@port;" 2>/dev/null >> "$HOST_LOG" || \
        echo "Unable to retrieve" >> "$HOST_LOG"
    echo "" >> "$HOST_LOG"
}

# Main
main() {
    # Initialize logs
    > "$HOST_LOG"
    > "$MYSQL_LOG"

    echo "MySQL Host Diagnostics Report ($OS)" >> "$HOST_LOG"
    echo "Generated: $TIMESTAMP" >> "$HOST_LOG"
    echo "Host: $(hostname)" >> "$HOST_LOG"
    echo "Country: GB" >> "$HOST_LOG"
    echo "Time Zone: GMT" >> "$HOST_LOG"
    echo "" >> "$HOST_LOG"

    echo "Connection Target: $MYSQL_HOST:$MYSQL_PORT" >> "$HOST_LOG"
    echo "User: $MYSQL_USER" >> "$HOST_LOG"
    echo "Default Database: $MYSQL_DB" >> "$HOST_LOG"
    echo "SQL Directory: $SQL_DIR" >> "$HOST_LOG"
    echo "Host Log: $HOST_LOG" >> "$HOST_LOG"
    echo "MySQL Log: $MYSQL_LOG" >> "$HOST_LOG"
    echo "" >> "$HOST_LOG"

    collect_os_info
    collect_cpu_info
    collect_memory_info
    collect_storage_info
    collect_mysql_processes
    collect_mysql_host_port

    execute_mysql_diagnostics "$SQL_DIR"

    echo "Diagnostics complete."
    echo "  Host Log: $HOST_LOG"
    echo "  MySQL Log: $MYSQL_LOG"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [host] [port] [user] [password] [database] [sql_dir]"
    echo "  host     - MySQL host (default: $DEFAULT_HOST)"
    echo "  port     - MySQL port (default: $DEFAULT_PORT)"
    echo "  user     - MySQL user (default: $DEFAULT_USER)"
    echo "  password - MySQL password (prompt if empty)"
    echo "  database - Default database (default: $DEFAULT_DB)"
    echo "  sql_dir  - Directory with SQL files (default: $DEFAULT_SQL_DIR)"
    echo ""
    echo "Outputs:"
    echo "  $HOST_LOG  - Host-level diagnostics (OS, CPU, memory, processes)"
    echo "  $MYSQL_LOG - MySQL diagnostics (queries, replication, etc.)"
    exit 0
fi

main
