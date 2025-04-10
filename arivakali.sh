#!/bin/bash

GREEN="\e[92m"
CYAN="\e[96m"
MAGENTA="\e[95m"
YELLOW="\e[93m"
RED="\e[91m"
RESET="\e[0m"

KALI_PATH="$HOME/kali-fs"
LOG_FILE="$HOME/kali_core.log"
ROOTFS_URL="https://kali.download/kali-images/kali-2023.3/kali-linux-2023.3-rootfs-arm64.tar.xz"
ROOTFS_CHECKSUM="e8b1f2c3d4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3"  # Örnek checksum, gerçek değeri kontrol edin

LOGO="KaliCore\nElite Penetration Testing Framework"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

render_full_logo() {
    clear
    local logo="$LOGO"
    local lines=$(echo -e "$logo" | wc -l)
    local term_height=$(tput lines)
    local term_width=$(tput cols)
    local padding=$(( (term_height - lines) / 2 ))

    for ((i=0; i<padding; i++)); do echo; done
    while IFS= read -r line; do
        local line_len=${#line}
        local offset=$(( (term_width - line_len) / 2 ))
        printf "${MAGENTA}%${offset}s%s${RESET}\n" "" "$line"
    done <<< "$logo"
    for ((i=0; i<padding; i++)); do echo; done
}

spinner() {
    local pid=$!
    local delay=0.05
    local spinstr='⠁⠂⠄⠆⠈⠐⠠⠤⠦⠇'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r${GREEN}[%s] %s${RESET}" "$spinstr" "$1"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r${GREEN}[✓] %s${RESET}\n" "$1"
}

verify_checksum() {
    local file="$1"
    local expected="$2"
    local actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo -e "${RED}[!] Checksum uyuşmazlığı: $file${RESET}"
        log_message "Checksum hatası: $actual != $expected"
        exit 1
    fi
    log_message "Checksum doğrulandı: $actual"
}

setup_kali() {
    if [ ! -d "$KALI_PATH" ]; then
        render_full_logo
        echo -e "${GREEN}[*] Kali Linux ortamı hazırlanıyor...${RESET}"
        log_message "Kali kurulum süreci başlatıldı"

        pkg update -y &>/dev/null && pkg install proot wget tar -y &>/dev/null & spinner "Bağımlılıklar yükleniyor"
        mkdir -p "$KALI_PATH"

        render_full_logo
        wget -q "$ROOTFS_URL" -O kali.tar.xz &>/dev/null & spinner "Kali rootfs indiriliyor"
        verify_checksum "kali.tar.xz" "$ROOTFS_CHECKSUM"

        render_full_logo
        tar -xJf kali.tar.xz -C "$KALI_PATH" &>/dev/null & spinner "Rootfs ayıklanıyor"
        rm kali.tar.xz

        # Kali yapılandırması
        echo "nameserver 8.8.8.8" > "$KALI_PATH/etc/resolv.conf"
        echo "kali-linux" > "$KALI_PATH/etc/hostname"
        chmod 644 "$KALI_PATH/etc/resolv.conf"

        log_message "Kali ortamı başarıyla kuruldu"
        render_full_logo
        echo -e "${GREEN}[+] Kali Linux hazır.${RESET}"
    else
        render_full_logo
        echo -e "${GREEN}[+] Kali ortamı zaten mevcut.${RESET}"
        log_message "Mevcut Kali ortamı doğrulandı"
    fi
}

launch_kali() {
    render_full_logo
    echo -e "${CYAN}[*] Kali Linux başlatılıyor...${RESET}"
    log_message "Kali shell başlatıldı"
    proot -0 -w ~ -r "$KALI_PATH" /bin/bash --init-file <(echo "PS1='${GREEN}root@kali-linux:${CYAN}/root${GREEN}\$ ${RESET}'")
}

main() {
    [ -f "$LOG_FILE" ] || touch "$LOG_FILE"
    setup_kali
    launch_kali
}

trap 'echo -e "${YELLOW}\n[*] Çıkış yapıldı.${RESET}"; log_message "Kullanıcı tarafından çıkış yapıldı"; exit 0' INT
main || {
    echo -e "${RED}[!] Hata oluştu.${RESET}"
    log_message "Hata: Kurulum veya çalıştırma başarısız"
    exit 1
}