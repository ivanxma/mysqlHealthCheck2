#!/bin/bash
# Comprehensive MySQL Host Diagnostics Script (Full Version - Enhanced OS Detection)
# Usage: ./mysql_host_diagnostics.sh [host] [port] [user] [password] [database] [sql_file]
# Supports macOS & Linux (Ubuntu, RHEL, Red Hat, CentOS, Rocky, AlmaLinux, etc.) | GB/GMT

# Configuration defaults
DEFAULT_HOST="localhost"
DEFAULT_PORT="3306"
DEFAULT_USER="root"
DEFAULT_DB="mysql"
DEFAULT_SQL_FILE="mysql_diagnostics_complete.sql"
OUTPUT_FILE="${OUTPUT_FILE:-mysql_host_diagnostics.txt}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Detect OS
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macOS"
    OS_FAMILY="macOS"
else
    OS="Linux"
    # Detailed Linux distribution detection
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION_ID="${VERSION_ID:-unknown}"
        OS_PRETTY_NAME="${PRETTY_NAME:-unknown}"
        case "$OS_ID" in
            ubuntu|debian)
                OS_FAMILY="Debian"
                ;;
            rhel|centos|rocky|almalinux|fedora|ol)
                OS_FAMILY="RedHat"
                ;;
            *)
                OS_FAMILY="OtherLinux"
                ;;
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
SQL_FILE="${6:-$DEFAULT_SQL_FILE}"

# If password is empty, prompt securely
if [[ -z "$MYSQL_PASSWORD" ]]; then
    read -s -p "Enter MySQL password for '$MYSQL_USER'@'$MYSQL_HOST:$MYSQL_PORT' (DB: $MYSQL_DB): " MYSQL_PASSWORD
    echo
fi

# Function: Test MySQL connection and database access
test_mysql_connection() {
    echo "Testing MySQL connection and database access..."
    local test_query="SELECT 1 AS connection_test;"
    local result=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
                         --database="$MYSQL_DB" -Nse "$test_query" 2>/dev/null)
    if [[ "$result" == "1" ]]; then
        echo "Connection and database access: SUCCESS"
        return 0
    else
        echo "Connection and database access: FAILED"
        echo "  - Verify host, port, user, password, and database '$MYSQL_DB' exists."
        echo "  - Ensure user has SELECT privilege on '$MYSQL_DB'."
        return 1
    fi
}

# Function: Validate SQL file and prepare with USE
prepare_sql_file() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo "ERROR: SQL file '$SQL_FILE' not found in current directory."
        return 1
    fi

    if [[ ! -r "$SQL_FILE" ]]; then
        echo "ERROR: SQL file '$SQL_FILE' is not readable."
        return 1
    fi

    # Ensure USE statement is at the top
    if ! head -10 "$SQL_FILE" | grep -qi "^USE[[:space:]]*[\`\"']*$MYSQL_DB[\`\"'];"; then
        echo "Injecting 'USE \`$MYSQL_DB\`; at top of SQL file..."
        {
            echo "USE \`$MYSQL_DB\`;";
            cat "$SQL_FILE"
        } > "${SQL_FILE}.tmp" && mv "${SQL_FILE}.tmp" "$SQL_FILE"
    fi
    return 0
}

# Function to execute MySQL SQL script
execute_mysql_diagnostics() {
    echo "Executing MySQL diagnostics from '$SQL_FILE' using database '$MYSQL_DB'..."

    # Validate SQL file
    if ! prepare_sql_file; then
        echo "SQL file preparation failed. Aborting." | tee -a "$OUTPUT_FILE"
        return 1
    fi

    # Test connection
    if ! test_mysql_connection; then
        echo "MySQL connection test failed. Aborting." | tee -a "$OUTPUT_FILE"
        return 1
    fi

    # Execute with error capture
    local temp_out="${OUTPUT_FILE}.mysql"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
          --database="$MYSQL_DB" --skip-column-names --batch < "$SQL_FILE" > "$temp_out" 2>&1

    if [[ $? -eq 0 ]]; then
        cat "$temp_out" >> "$OUTPUT_FILE"
        echo "MySQL diagnostics completed successfully." | tee -a "$OUTPUT_FILE"
    else
        echo "MySQL diagnostics had warnings/errors (non-fatal):" | tee -a "$OUTPUT_FILE"
        grep -i "SKIPPED\|Warning\|Error" "$temp_out" | tail -20 >> "$OUTPUT_FILE" || true
    fi
    rm -f "$temp_out"
}

# Function to collect OS version (enhanced for RedHat/Ubuntu variants)
collect_os_info() {
    echo "--- Operating System Information ---" >> "$OUTPUT_FILE"
    if [[ "$OS" == "macOS" ]]; then
        echo "OS: macOS $(sw_vers -productName) $(sw_vers -productVersion)" >> "$OUTPUT_FILE"
        echo "Build: $(sw_vers -buildVersion)" >> "$OUTPUT_FILE"
        echo "Kernel: $(uname -r)" >> "$OUTPUT_FILE"
    else
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "Distribution ID: $ID" >> "$OUTPUT_FILE"
            echo "Version ID: $VERSION_ID" >> "$OUTPUT_FILE"
            echo "Pretty Name: $PRETTY_NAME" >> "$OUTPUT_FILE"
            echo "Family: $OS_FAMILY" >> "$OUTPUT_FILE"
            echo "Kernel: $(uname -r)" >> "$OUTPUT_FILE"
        else
            echo "OS detection failed (no /etc/os-release)." >> "$OUTPUT_FILE"
            echo "Kernel: $(uname -r)" >> "$OUTPUT_FILE"
        fi
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to collect detailed CPU information
collect_cpu_info() {
    echo "--- CPU Information (Detailed List) ---" >> "$OUTPUT_FILE"
    if [[ "$OS" == "macOS" ]]; then
        sysctl -n machdep.cpu.brand_string >> "$OUTPUT_FILE"
        echo "Cores: $(sysctl -n hw.physicalcpu)" >> "$OUTPUT_FILE"
        echo "Threads: $(sysctl -n hw.logicalcpu)" >> "$OUTPUT_FILE"
        echo "Frequency: $(sysctl -n hw.cpufrequency / 1000000 | awk '{print $1 " MHz"}')" >> "$OUTPUT_FILE"
    else
        if command -v lscpu >/dev/null 2>&1; then
            lscpu >> "$OUTPUT_FILE"
        else
            echo "CPU cores: $(nproc)" >> "$OUTPUT_FILE"
            cat /proc/cpuinfo | grep -E 'processor|model name|cpu MHz|cache size|flags' >> "$OUTPUT_FILE"
        fi
    fi
    if [[ "$OS" == "macOS" ]]; then
        echo "Load Average: $(sysctl -n vm.loadavg | sed 's/[{}]//g')" >> "$OUTPUT_FILE"
    else
        echo "Load Average (1/5/15 min): $(uptime | awk -F'load average:' '{print $2}')" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to collect memory usage
collect_memory_info() {
    echo "--- Memory Usage ---" >> "$OUTPUT_FILE"
    if [[ "$OS" == "macOS" ]]; then
        vm_stat | head -10 >> "$OUTPUT_FILE"
        echo "Total RAM: $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')" >> "$OUTPUT_FILE"
    else
        if command -v free >/dev/null 2>&1; then
            free -h >> "$OUTPUT_FILE"
        else
            echo "Memory detection failed." >> "$OUTPUT_FILE"
        fi
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to collect storage usage
collect_storage_info() {
    echo "--- Storage Allocation and Usage ---" >> "$OUTPUT_FILE"
    if [[ "$OS" == "macOS" ]]; then
        df -h | grep -E '^Filesystem|/Volumes' >> "$OUTPUT_FILE"
    else
        df -hT | grep -E '^Filesystem|/' >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to collect MySQL/MariaDB process list
collect_mysql_processes() {
    echo "--- MySQL/MariaDB Process Information ---" >> "$OUTPUT_FILE"
    local mysql_pids=$(pgrep -f 'mysqld|mariadbd|mysql' 2>/dev/null || echo "")
    if [[ -n "$mysql_pids" ]]; then
        if [[ "$OS" == "macOS" ]]; then
            ps -p $(echo $mysql_pids | tr ' ' ',') -o pid,ppid,user,pcpu,pmem,etime,command | sort -k4 -nr >> "$OUTPUT_FILE"
        else
            ps -p $(echo "$mysql_pids" | tr ' ' ',') -o pid,ppid,user,%cpu,%mem,etime,cmd --sort=-%cpu >> "$OUTPUT_FILE"
        fi
    else
        echo "No MySQL/MariaDB processes detected." >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to collect MySQL host and port from server
collect_mysql_host_port() {
    echo "--- MySQL Server Host and Port (Runtime) ---" >> "$OUTPUT_FILE"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
          --database="$MYSQL_DB" -Nse "SELECT @@hostname AS Host, @@port AS Port;" 2>/dev/null >> "$OUTPUT_FILE" || \
        echo "Host: Unable to retrieve | Port: Unable to retrieve (check credentials)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Main execution
main() {
    # Initialize output file
    > "$OUTPUT_FILE"
    echo "MySQL Host Diagnostics Report ($OS)" >> "$OUTPUT_FILE"
    echo "Generated: $TIMESTAMP" >> "$OUTPUT_FILE"
    echo "Host: $(hostname)" >> "$OUTPUT_FILE"
    echo "Country: GB" >> "$OUTPUT_FILE"
    echo "Time Zone: GMT" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Log connection details
    echo "Connection Target: $MYSQL_HOST:$MYSQL_PORT" >> "$OUTPUT_FILE"
    echo "User: $MYSQL_USER" >> "$OUTPUT_FILE"
    echo "Default Database: $MYSQL_DB" >> "$OUTPUT_FILE"
    echo "SQL File: $SQL_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Collect host statistics
    collect_os_info
    collect_cpu_info
    collect_memory_info
    collect_storage_info
    collect_mysql_processes
    collect_mysql_host_port

    # Execute diagnostics
    execute_mysql_diagnostics

    echo "Diagnostics complete. Output saved to $OUTPUT_FILE"
}

# Show help
if [[ "$1" == "-h" || "$1" == "-help" || "$1" == "--help" ]]; then
    echo "Usage: $0 [host] [port] [user] [password] [database] [sql_file]"
    echo "  host     - MySQL host (default: $DEFAULT_HOST)"
    echo "  port     - MySQL port (default: $DEFAULT_PORT)"
    echo "  user     - MySQL user (default: $DEFAULT_USER)"
    echo "  password - MySQL password (prompt if empty)"
    echo "  database - Default database (default: $DEFAULT_DB)"
    echo "  sql_file - Path to SQL diagnostic script (default: $DEFAULT_SQL_FILE)"
    exit 0
fi

main
