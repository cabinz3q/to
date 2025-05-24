#!/system/bin/sh

BASE_DIR="/sdcard/Documents/toram"
BACKUP_DIR="$BASE_DIR"
LOG_DIR="$BASE_DIR"
TMP_DIR="/data/local/tmp"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directories if they don't exist
su -c "mkdir -p $BACKUP_DIR $LOG_DIR $TMP_DIR" || {
    echo "Failed to create directories"
    exit 1
}

# Create log file
LOG_FILE="$LOG_DIR/bypass_log.txt"
PID_FILE="$TMP_DIR/bypass_toram_pid.log"
su -c "touch $LOG_FILE" || exit 1

log_message() {
    local message="$1"
    su -c "echo \"[$(date +%Y-%m-%d %H:%M:%S)] $message\" >> $LOG_FILE"
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $message"
}

# Check for existing PID and kill if exists
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(su -c "cat $PID_FILE")
    if [ -n "$OLD_PID" ]; then
        log_message "Found existing PID: $OLD_PID, attempting to kill"
        if su -c "kill -9 $OLD_PID" 2>/dev/null; then
            log_message "Successfully killed previous process with PID: $OLD_PID"
        else
            log_message "Failed to kill previous process with PID: $OLD_PID"
        fi
    fi
    su -c "rm -f $PID_FILE"
fi

# Save current PID
echo $$ | su -c "tee $PID_FILE"

# Find Toram Online app path (unchanged as it's system path)
APP_PATH=$(su -c "find /data/app -type d -name \"com.asobimo.toramonline-*\" | head -1")

# Backup existing library if it exists
su -c "mv $APP_PATH/lib/arm64/libil2cpp.so $BACKUP_DIR/libil2cpp.so"

# Copy base.apk
su -c "cp -f $APP_PATH/base.apk $TMP_DIR/base.apk"

# Function to check if app is running
is_app_running() {
    APP_RUNNING=$(su -c "dumpsys activity processes | grep com.asobimo.toramonline" 2>/dev/null)
    [ -n "$APP_RUNNING" ]
}

# Main monitoring loop
while true; do
    if ! is_app_running; then
        
        # Reinstall original apk if it exists
    
        su -c "chmod 755 $TMP_DIR/base.apk"
        su -c "pm install -r $TMP_DIR/base.apk"
        su -c "rm -f $TMP_DIR/base.apk"
        
        # Clean up PID file
        su -c "rm $BASE_DIR"
        
        log_message "Bypass deactivated at $(date)"
        exit 0
    fi
    
    # Sleep for 5 seconds before checking again
    sleep 5
done
