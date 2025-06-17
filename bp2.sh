#!/system/bin/sh

BASE_DIR="/sdcard/Documents"
TMP_DIR="/data/local/tmp/toram"
PID_FILE="$TMP_DIR/bypass_toram_pid.log"

# Buat direktori jika belum ada
su -c "mkdir -p $TMP_DIR"

# Cek dan bunuh proses lama jika ada
if su -c "[ -f '$PID_FILE' ]"; then
    OLD_PID=$(su -c "cat '$PID_FILE'")
    if [ -n "$OLD_PID" ]; then
        su -c "kill -9 $OLD_PID" 2>/dev/null
    fi
    su -c "rm -f '$PID_FILE'"
fi

# Simpan PID sekarang
echo $$ | su -c "tee '$PID_FILE' >/dev/null"

# Cari path aplikasi Toram
APP_PATH=$(su -c "find /data/app -type d -name 'com.asobimo.toramonline-*' | head -n 1")

# Pastikan path valid
if [ -z "$APP_PATH" ]; then
    echo "❌ Gagal menemukan path aplikasi Toram"
    exit 1
fi

# Backup libil2cpp.so jika ada
LIB_PATH="$APP_PATH/lib/arm64/libil2cpp.so"
if su -c "[ -f '$LIB_PATH' ]"; then
    su -c "cp -f '$LIB_PATH' '$TMP_DIR/libil2cpp.so'"
    su -c "chmod 755 '$TMP_DIR/libil2cpp.so'"
fi

# Fungsi pengecekan apakah aplikasi sedang berjalan
is_app_running() {
    su -c "dumpsys activity processes | grep -q com.asobimo.toramonline"
}

# Loop pemantauan
while true; do
    if ! is_app_running; then
        # Restore libil2cpp.so jika tersedia
        if su -c "[ -f '$TMP_DIR/libil2cpp.so' ]"; then
            su -c "cp -f '$TMP_DIR/libil2cpp.so' '$LIB_PATH'"
            su -c "chmod 755 '$LIB_PATH'"
        fi

        # Hapus direktori TMP secara aman
        su -c "rm -rf '$TMP_DIR'"

        exit 0
    fi

    # Delay 5 detik
    sleep 5
done
