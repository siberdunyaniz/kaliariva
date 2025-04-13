#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL="https://image-nethunter.kali.org/nethunter-fs/kali-daily"
USERNAME="kali"
LOG_DOSYASI="$HOME/nethunter_kurulum_$(date +%Y%m%d_%H%M%S).log"

KIRMIZI='\033[1;31m'
YESIL='\033[1;32m'
SARI='\033[1;33m'
MAVI='\033[1;34m'
CYAN_ACIK='\033[96m'
SIFIRLA='\033[0m'

renk_gecisi() {
    local text="$1"
    local start_color="$2"
    local end_color="$3"
    local len=${#text}
    local output=""
    for ((i=0; i<len; i++)); do
        local char="${text:$i:1}"
        if [ "$start_color" = "$KIRMIZI" ] && [ "$end_color" = "$SARI" ]; then
            [ $i -lt $((len/2)) ] && output+="${KIRMIZI}${char}" || output+="${SARI}${char}"
        elif [ "$start_color" = "$MAVI" ] && [ "$end_color" = "$YESIL" ]; then
            [ $i -lt $((len/2)) ] && output+="${MAVI}${char}" || output+="${YESIL}${char}"
        else
            output+="${start_color}${char}"
        fi
    done
    echo -e "$output${SIFIRLA}"
}

merkezle() {
    local text="$1"
    local cols=$(tput cols 2>/dev/null || echo 80)
    while IFS= read -r line; do
        local len=${#line}
        local padding=$(( (cols - len) / 2 ))
        [ $padding -lt 0 ] && padding=0
        printf "%${padding}s%s\n" "" "$line"
    done <<< "$text"
}

LOGO=""
declare -a LOGO_LINES_ARRAY
LOGO_LINES_ARRAY=(
" .S_SSSs     .S_sSSs     .S   .S    S.    .S_SSSs    "
".SS~SSSSS   .SS~YS%%b   .SS  .SS    SS.  .SS~SSSSS   "
"S%S   SSSS  S%S   \`S%b  S%S  S%S    S%S  S%S   SSSS  "
"S%S    S%S  S%S    S%S  S%S  S%S    S%S  S%S    S%S  "
"S%S SSSS%S  S%S    d*S  S&S  S&S    S%S  S%S SSSS%S  "
"S&S  SSS%S  S&S   .S*S  S&S  S&S    S&S  S&S  SSS%S  "
"S&S    S&S  S&S_sdSSS   S&S  S&S    S&S  S&S    S&S  "
"S&S    S&S  S&S~YSY%b   S&S  S&S    S&S  S&S    S&S  "
"S*S    S&S  S*S   \`S%b  S*S  S*b    S*S  S*S    S&S  "
"S*S    S*S  S*S    S%S  S*S  S*S.   S*S  S*S    S*S  "
"S*S    S*S  S*S    S&S  S*S   SSSbs_S*S  S*S    S*S  "
"SSS    S*S  S*S    SSS  S*S    YSSP~SSS  SSS    S*S  "
"       SP   SP          SP                      SP   "
"       Y    Y           Y                       Y    "
"ArıvaNetHunter By: @AtahanArslan Channel: @ArivaTools"
)
for line in "${LOGO_LINES_ARRAY[@]}"; do
    LOGO+="$(renk_gecisi "$line" "$KIRMIZI" "$SARI")\n"
done

ekran_hazirla() {
    clear
    merkezle "$LOGO"
    echo
}

renkli_yaz() {
    local mesaj="$1"
    local start_color="$2"
    local end_color="$3"
    local cols=$(tput cols 2>/dev/null || echo 80)
    local len=${#mesaj}
    [ $len -gt $cols ] && mesaj="${mesaj:0:$((cols - 3))}..."
    echo -e "$(renk_gecisi "$mesaj" "$start_color" "$end_color")"
}

log_yaz() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DOSYASI" 2>/dev/null || {
        renkli_yaz "Hata: Log dosyasına yazılamadı." "$KIRMIZI" "$SARI" >&2
        exit 1
    }
}

check_internet() {
    ping -c 1 8.8.8.8 >/dev/null 2>&1 || {
        renkli_yaz "İnternet bağlantısı yok!" "$KIRMIZI" "$SARI"
        log_yaz "İnternet bağlantısı yok."
        exit 1
    }
}

check_disk_space() {
    local required_space=2000000
    local available_space=$(df -k "$HOME" | tail -1 | awk '{print $4}')
    [ "$available_space" -lt "$required_space" ] && {
        renkli_yaz "Yeterli disk alanı yok! En az 2GB gerekli." "$KIRMIZI" "$SARI"
        log_yaz "Yetersiz disk alanı: $available_space KB."
        exit 1
    }
}

get_arch() {
    ekran_hazirla
    renkli_yaz "Cihaz mimarisi kontrol ediliyor..." "$MAVI" "$YESIL"
    local arch=$(getprop ro.product.cpu.abi 2>/dev/null)
    case "$arch" in
        arm64-v8a) SYS_ARCH="arm64" ;;
        armeabi|armeabi-v7a) SYS_ARCH="armhf" ;;
        *) renkli_yaz "Desteklenmeyen mimari!" "$KIRMIZI" "$SARI"; log_yaz "Desteklenmeyen mimari."; exit 1 ;;
    esac
    renkli_yaz "Mimari: $SYS_ARCH" "$YESIL" "$MAVI"
    log_yaz "Mimari: $SYS_ARCH"
}

set_strings() {
    ekran_hazirla
    renkli_yaz "NetHunter sürümünü seçin:" "$MAVI" "$YESIL"
    if [ "$SYS_ARCH" = "arm64" ]; then
        renkli_yaz "[1] NetHunter ARM64 (full)" "$CYAN_ACIK" "$MAVI"
        renkli_yaz "[2] NetHunter ARM64 (minimal)" "$CYAN_ACIK" "$MAVI"
        renkli_yaz "[3] NetHunter ARM64 (nano)" "$CYAN_ACIK" "$MAVI"
    else
        renkli_yaz "[1] NetHunter ARMhf (full)" "$CYAN_ACIK" "$MAVI"
        renkli_yaz "[2] NetHunter ARMhf (minimal)" "$CYAN_ACIK" "$MAVI"
        renkli_yaz "[3] NetHunter ARMhf (nano)" "$CYAN_ACIK" "$MAVI"
    fi
    renkli_yaz "Seçenek (1-3):" "$SARI" "$KIRMIZI"
    read -r wimg || {
        renkli_yaz "Girdi alınamadı!" "$KIRMIZI" "$SARI"
        log_yaz "Görüntü seçimi başarısız."
        exit 1
    }
    case "$wimg" in
        1) wimg="full" ;;
        2) wimg="minimal" ;;
        3) wimg="nano" ;;
        *) renkli_yaz "Geçersiz seçim, 'full' seçildi." "$SARI" "$KIRMIZI"; wimg="full" ;;
    esac
    CHROOT="$HOME/kali-${SYS_ARCH}"
    IMAGE_NAME="kali-nethunter-daily-dev-rootfs-${wimg}-${SYS_ARCH}.tar.xz"
    SHA_NAME="${IMAGE_NAME}.sha512sum"
    log_yaz "Seçilen görüntü: $wimg"
}

ask() {
    local soru="$1"
    local varsayilan="${2:-N}"
    local istem cevap
    [ "$varsayilan" = "Y" ] && istem="E/h" || istem="e/H"
    while true; do
        renkli_yaz "$soru [$istem]" "$CYAN_ACIK" "$MAVI"
        read -r cevap || {
            renkli_yaz "Girdi alınamadı!" "$KIRMIZI" "$SARI"
            log_yaz "Kullanıcı girdisi alınamadı."
            exit 1
        }
        [ -z "$cevap" ] && cevap="$varsayilan"
        case "$cevap" in
            Y*|y*|E*|e*) return 0 ;;
            N*|n*|H*|h*) return 1 ;;
            *) renkli_yaz "Geçersiz cevap! E veya H girin." "$SARI" "$KIRMIZI" ;;
        esac
    done
}

prepare_fs() {
    [ -d "$CHROOT" ] && {
        ask "Mevcut chroot silinsin mi?" "N" && {
            rm -rf "$CHROOT" || {
                renkli_yaz "Chroot silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Chroot silinemedi."
                exit 1
            }
            log_yaz "Chroot silindi."
        } || {
            KEEP_CHROOT=1
            log_yaz "Chroot korundu."
        }
    }
}

check_dependencies() {
    ekran_hazirla
    renkli_yaz "Bağımlılıklar kontrol ediliyor..." "$MAVI" "$YESIL"
    apt-get update -y &>/dev/null || apt-get dist-upgrade -y &>/dev/null || {
        renkli_yaz "Paket güncelleme başarısız!" "$KIRMIZI" "$SARI"
        log_yaz "apt-get başarısız."
        exit 1
    }
    for i in proot tar wget; do
        command -v "$i" >/dev/null 2>&1 || {
            renkli_yaz "$i kuruluyor..." "$MAVI" "$YESIL"
            apt install -y "$i" &>/dev/null || {
                renkli_yaz "$i kurulamadı!" "$KIRMIZI" "$SARI"
                log_yaz "$i kurulamadı."
                exit 1
            }
        }
    done
    log_yaz "Bağımlılıklar hazır."
}

get_url() {
    ROOTFS_URL="${BASE_URL}/${IMAGE_NAME}"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
}

get_rootfs() {
    ekran_hazirla
    [ -f "$IMAGE_NAME" ] && {
        ask "Mevcut görüntü silinsin mi?" "N" && {
            rm -f "$IMAGE_NAME" || {
                renkli_yaz "Dosya silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Dosya silinemedi."
                exit 1
            }
        } || {
            KEEP_IMAGE=1
            renkli_yaz "Mevcut görüntü kullanılacak." "$SARI" "$KIRMIZI"
            log_yaz "Görüntü korundu."
            return
        }
    }
    renkli_yaz "Rootfs indiriliyor: $IMAGE_NAME" "$MAVI" "$YESIL"
    get_url
    check_internet
    wget -O "$IMAGE_NAME" "$ROOTFS_URL" --continue --tries=3 --timeout=30 --progress=bar:force 2>>"$LOG_DOSYASI" || {
        renkli_yaz "İndirme başarısız!" "$KIRMIZI" "$SARI"
        log_yaz "Rootfs indirilemedi."
        exit 1
    }
    [ -s "$IMAGE_NAME" ] || {
        renkli_yaz "İndirilen dosya boş!" "$KIRMIZI" "$SARI"
        log_yaz "İndirilen dosya boş."
        rm -f "$IMAGE_NAME"
        exit 1
    }
    chmod 644 "$IMAGE_NAME" 2>/dev/null
    renkli_yaz "Rootfs indirildi." "$YESIL" "$MAVI"
    log_yaz "Rootfs indirildi: $IMAGE_NAME"
}

get_sha() {
    [ -z "$KEEP_IMAGE" ] || return
    ekran_hazirla
    renkli_yaz "SHA indiriliyor..." "$MAVI" "$YESIL"
    get_url
    [ -f "$SHA_NAME" ] && rm -f "$SHA_NAME" 2>/dev/null
    wget -O "$SHA_NAME" "$SHA_URL" --continue --tries=3 --timeout=30 --progress=bar:force 2>>"$LOG_DOSYASI" || {
        renkli_yaz "SHA indirilemedi, doğrulama atlanıyor." "$SARI" "$KIRMIZI"
        log_yaz "SHA indirilemedi."
        return
    }
    chmod 644 "$SHA_NAME" 2>/dev/null
    renkli_yaz "Rootfs doğrulanıyor..." "$MAVI" "$YESIL"
    sha512sum -c "$SHA_NAME" 2>/dev/null || {
        renkli_yaz "Rootfs bozuk!" "$KIRMIZI" "$SARI"
        log_yaz "Rootfs bozuk."
        rm -f "$IMAGE_NAME" "$SHA_NAME"
        exit 1
    }
    renkli_yaz "Rootfs doğrulandı." "$YESIL" "$MAVI"
    log_yaz "Rootfs doğrulandı."
}

extract_rootfs() {
    [ -z "$KEEP_CHROOT" ] || {
        renkli_yaz "Mevcut chroot kullanılıyor." "$SARI" "$KIRMIZI"
        return
    }
    ekran_hazirla
    renkli_yaz "Rootfs çıkarılıyor..." "$MAVI" "$YESIL"
    [ -f "$IMAGE_NAME" ] || {
        renkli_yaz "Görüntü dosyası eksik!" "$KIRMIZI" "$SARI"
        log_yaz "Görüntü dosyası eksik."
        exit 1
    }
    check_disk_space
    mkdir -p "$CHROOT" || {
        renkli_yaz "Chroot dizini oluşturulamadı!" "$KIRMIZI" "$SARI"
        log_yaz "Chroot dizini oluşturulamadı."
        exit 1
    }
    tar -xf "$IMAGE_NAME" -C "$CHROOT" 2>>"$LOG_DOSYASI" || {
        renkli_yaz "Çıkarma başarısız!" "$KIRMIZI" "$SARI"
        log_yaz "Rootfs çıkarılamadı."
        exit 1
    }
    [ -d "$CHROOT/bin" ] || {
        renkli_yaz "Chroot geçersiz!" "$KIRMIZI" "$SARI"
        log_yaz "Chroot geçersiz."
        rm -rf "$CHROOT"
        exit 1
    }
    chmod -R u+rw "$CHROOT" 2>/dev/null
    renkli_yaz "Rootfs çıkarıldı." "$YESIL" "$MAVI"
    log_yaz "Rootfs çıkarıldı."
}

create_launcher() {
    NH_LAUNCHER="$HOME/bin/nethunter"
    NH_SHORTCUT="$HOME/bin/nh"
    mkdir -p "$HOME/bin"
    cat > "$NH_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "\${HOME}"
unset LD_PRELOAD
proot --link2symlink -0 -w ~ -r "$CHROOT" /bin/bash -l
[ -x "/system/bin/nethunter" ] && /system/bin/nethunter -c "bootkali" || echo "NetHunter CLI bulunamadı."
EOF
    chmod 700 "$NH_LAUNCHER" || {
        renkli_yaz "Başlatıcı oluşturulamadı!" "$KIRMIZI" "$SARI"
        log_yaz "Başlatıcı oluşturulamadı."
        exit 1
    }
    ln -sf "$NH_LAUNCHER" "$NH_SHORTCUT" 2>/dev/null
    log_yaz "Başlatıcı oluşturuldu."
}

cleanup() {
    [ -f "$IMAGE_NAME" ] && {
        ask "İndirilen dosya silinsin mi?" "N" && {
            rm -f "$IMAGE_NAME" "$SHA_NAME" || {
                renkli_yaz "Dosyalar silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Dosyalar silinemedi."
                exit 1
            }
            log_yaz "Dosyalar silindi."
        }
    }
}

fix_resolv_conf() {
    echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "$CHROOT/etc/resolv.conf" 2>/dev/null || {
        renkli_yaz "DNS ayarlanamadı." "$SARI" "$KIRMIZI"
        log_yaz "DNS ayarlanamadı."
    }
    log_yaz "DNS ayarlandı."
}

cd "$HOME" || {
    ekran_hazirla
    renkli_yaz "Ev dizinine erişilemedi!" "$KIRMIZI" "$SARI"
    log_yaz "Ev dizinine erişilemedi."
    exit 1
}
ekran_hazirla
check_dependencies
get_arch
set_strings
prepare_fs
get_rootfs
get_sha
extract_rootfs
create_launcher
fix_resolv_conf
cleanup

ekran_hazirla
renkli_yaz "ArıvaNetHunter başarıyla kuruldu!" "$YESIL" "$MAVI"
renkli_yaz "Başlat: 'nethunter' veya 'nh'" "$CYAN_ACIK" "$MAVI"
renkli_yaz "Log: $LOG_DOSYASI" "$CYAN_ACIK" "$MAVI"
log_yaz "Kurulum tamamlandı."