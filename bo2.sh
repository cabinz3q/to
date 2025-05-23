#!/system/bin/sh

BACKUP_DIR="/sdcard/Android/toram"

# Create directories if they don't exist
su -c "mkdir -p $BACKUP_DIR"

# Create log file
LOG_FILE="/data/local/tmp/toram/bypass_log.txt"
PID_FILE="/data/local/tmp/toram/bypass_toram_pid.log"
su -c "touch $LOG_FILE"

log_message() {
    local message="$1"
    su -c "echo \"[$(date +%Y-%m-%d\ %H:%M:%S)] $message\" >> $LOG_FILE"
}

log_message "Bypass script started"

# Check for existing PID and kill if exists
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(su -c "cat $PID_FILE")
    if [ -n "$OLD_PID" ]; then
        log_message "Found existing PID: $OLD_PID, attempting to kill"
        su -c "kill -9 $OLD_PID" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "Successfully killed previous process with PID: $OLD_PID"
        else
            log_message "Failed to kill previous process with PID: $OLD_PID"
        fi
    fi
    su -c "rm -f $PID_FILE"
fi

# Save current PID
echo $$ | su -c "tee $PID_FILE"
log_message "Saved current PID: $$"

# Find Toram Online app path
APP_PATH=$(su -c "find /data/app -type d -name \"com.asobimo.toramonline-*\" | head -1")

log_message "Found app path: $APP_PATH"
su -c rm -f $BACKUP_DIR/libil2cpp.so
# Copy the library file (use cp instead of mv to preserve original)
su -c "mv $APP_PATH/lib/arm64/libil2cpp.so $BACKUP_DIR/"   
# Copy base.apk
su -c "cp $APP_PATH/base.apk /data/local/tmp/toram/"


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
        
        # Set permissions and reinstall
        su -c "chmod 755 /data/local/tmp/toram/base.apk"
        su -c "pm install -r /data/local/tmp/toram/base.apk"
        
        # Clean up temp files
        su -c "rm -f /data/local/tmp/toram/base.apk"
        su -c "rm -f $PID_FILE"
        
        log_message "Bypass deactivated at $(date)"
        exit 0
    fi
    
    # Sleep for 5 seconds before checking again
    sleep 5
done
