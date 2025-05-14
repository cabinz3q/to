#!/system/bin/sh

# Create log file
LOG_FILE="/data/local/tmp/bypass_log.txt"
su -c "touch $LOG_FILE"
su -c "chmod 666 $LOG_FILE"

log_message() {
    local message="$1"
    su -c "echo \"[$(date +%Y-%m-%d\ %H:%M:%S)] $message\" >> $LOG_FILE"
}

log_message "Bypass script started"

# Find Toram Online app path
APP_PATH=$(su -c "find /data/app -type d -name \"com.asobimo.toramonline-*\"")
BACKUP_DIR="/data/local/tmp/toram"

log_message "Found app path: $APP_PATH"

isrun=0

# Check if this is the first run
if [ $isrun == 0 ]; then
    log_message "First run detected, creating backup directory"
    su -c "mkdir -p $BACKUP_DIR"
    
    # Copy the library file
    su -c "mv $APP_PATH/lib/arm64/libil2cpp.so $BACKUP_DIR/"
    if [ $? -eq 0 ]; then
        log_message "Successfully copied libil2cpp.so to backup directory"
    else
        log_message "Failed to copy libil2cpp.so"
        su -c "rm -rf $BACKUP_DIR"
        exit 1
    fi
    isrun=1
else
    log_message "Backup directory already exists"
fi

# Function to check if app is running
is_app_running() {
    APP_RUNNING=$(su -c "dumpsys activity processes | grep com.asobimo.toramonline")
    if [ -z "$APP_RUNNING" ]; then
        return 1  # Not running
    else
        return 0  # Running
    fi
}

# Main monitoring loop
log_message "Starting monitoring loop"
while true; do
    if ! is_app_running; then
        log_message "Application is not running, cleaning up and exiting"
        su -c "mv $BACKUP_DIR/libil2cpp.so $APP_PATH/lib/arm64/libil2cpp.so"
        su -c "rm -rf $BACKUP_DIR"
        su -c "echo \"Bypass deactivated at $(date)\" >> $LOG_FILE"
        exit 0
    fi
    
    # Sleep for 5 seconds before checking again
    sleep 5
done
