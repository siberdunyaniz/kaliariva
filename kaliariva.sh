#!/data/data/com.termux/files/usr/bin/bash -e

# Script bilgileri
VERSION=2024091801
BASE_URL="https://image-nethunter.kali.org/nethunter-fs/kali-daily"
USERNAME="kali"
LOG_DOSYASI="$HOME/nethunter_kurulum_$(date +%Y%m%d_%H%M%S).log"
LOGO_LINES=9

# Renk kodları
KIRMIZI='\033[1;31m'
YESIL='\033[1;32m'
SARI='\033[1;33m'
MAVI='\033[1;34m'
MOR='\033[1;35m'
CYAN='\033[1;36m'
BEYAZ='\033[1;37m'
SIFIRLA='\033[0m'
KIRMIZI_ACIK='\033[91m'
YESIL_ACIK='\033[92m'
SARI_ACIK='\033[93m'
MAVI_ACIK='\033[94m'
MOR_ACIK='\033[95m'
CYAN_ACIK='\033[96m'

# Renk geçiş efekti fonksiyonu
renk_gecisi() {
    local text="$1"
    local start_color="$2"
    local end_color="$3"
    local len=${#text}
    local i=0
    local output=""
    for ((i=0; i<len; i++)); do
        local char="${text:$i:1}"
        if [ "$start_color" = "$KIRMIZI" ] && [ "$end_color" = "$SARI" ]; then
            if [ $i -lt $((len/2)) ]; then
                output+="${KIRMIZI}${char}"
            else
                output+="${SARI}${char}"
            fi
        elif [ "$start_color" = "$MAVI" ] && [ "$end_color" = "$YESIL" ]; then
            if [ $i -lt $((len/2)) ]; then
                output+="${MAVI}${char}"
            else
                output+="${YESIL}${char}"
            fi
        else
            output+="${start_color}${char}"
        fi
    done
    echo -e "$output${SIFIRLA}"
}

# Merkezleme fonksiyonu
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

# Logo (sizin attığınız haliyle)
LOGO=""
declare -a LOGO_LINES_ARRAY
LOGO_LINES_ARRAY=( "
 .S_SSSs     .S_sSSs     .S   .S    S.    .S_SSSs    
.SS~SSSSS   .SS~YS%%b   .SS  .SS    SS.  .SS~SSSSS   
S%S   SSSS  S%S   `S%b  S%S  S%S    S%S  S%S   SSSS  
S%S    S%S  S%S    S%S  S%S  S%S    S%S  S%S    S%S  
S%S SSSS%S  S%S    d*S  S&S  S&S    S%S  S%S SSSS%S  
S&S  SSS%S  S&S   .S*S  S&S  S&S    S&S  S&S  SSS%S  
S&S    S&S  S&S_sdSSS   S&S  S&S    S&S  S&S    S&S  
S&S    S&S  S&S~YSY%b   S&S  S&S    S&S  S&S    S&S  
S*S    S&S  S*S   `S%b  S*S  S*b    S*S  S*S    S&S  
S*S    S*S  S*S    S%S  S*S  S*S.   S*S  S*S    S*S  
S*S    S*S  S*S    S&S  S*S   SSSbs_S*S  S*S    S*S  
SSS    S*S  S*S    SSS  S*S    YSSP~SSS  SSS    S*S  
       SP   SP          SP                      SP   
       Y    Y           Y                       Y    
ArıvaNetHunter By: @AtahanArslan Channel: @ArivaTools                                                     
")
for line in "${LOGO_LINES_ARRAY[@]}"; do
    LOGO+="$(renk_gecisi "$line" "$KIRMIZI" "$SARI")\n"
done

# Ekran hazırlığı (banner)
ekran_hazirla() {
    clear
    merkezle "$LOGO"
    echo
}

# Renkli yazdırma
renkli_yaz() {
    local mesaj="$1"
    local start_color="$2"
    local end_color="$3"
    local cols=$(tput cols 2>/dev/null || echo 80)
    local len=${#mesaj}
    if [ $len -gt $cols ]; then
        mesaj="${mesaj:0:$((cols - 3))}..."
    fi
    echo -e "$(renk_gecisi "$mesaj" "$start_color" "$end_color")"
}

# Log yazma
log_yaz() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DOSYASI" 2>/dev/null || {
        renkli_yaz "Hata: Log dosyasına yazılamadı: $LOG_DOSYASI" "$KIRMIZI" "$SARI" >&2
        exit 1
    }
}

# İnternet kontrolü
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        renkli_yaz "❌ İnternet bağlantısı yok!" "$KIRMIZI" "$SARI"
        log_yaz "Hata: İnternet bağlantısı yok."
        exit 1
    fi
}

# Disk alanı kontrolü
check_disk_space() {
    local required_space=2000000  # 2GB in KB
    local available_space=$(df -k "$HOME" | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt "$required_space" ]; then
        renkli_yaz "❌ Yeterli disk alanı yok! En az 2GB gerekli." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Yeterli disk alanı yok ($available_space KB mevcut)."
        exit 1
    fi
}

# Mimari kontrolü
get_arch() {
    ekran_hazirla
    renkli_yaz "📡 Cihaz mimarisi kontrol ediliyor..." "$MAVI" "$YESIL"
    local arch=$(getprop ro.product.cpu.abi 2>/dev/null)
    case "$arch" in
        arm64-v8a) SYS_ARCH="arm64" ;;
        armeabi|armeabi-v7a) SYS_ARCH="armhf" ;;
        *) renkli_yaz "❌ Desteklenmeyen mimari!" "$KIRMIZI" "$SARI"; log_yaz "Hata: Desteklenmeyen mimari."; exit 1 ;;
    esac
    renkli_yaz "✅ Mimari: $SYS_ARCH" "$YESIL" "$MAVI"
    log_yaz "Mimari belirlendi: $SYS_ARCH"
}

# Görüntü seçimi
set_strings() {
    ekran_hazirla
    renkli_yaz "📋 NetHunter sürümünü seçin:" "$MAVI" "$YESIL"
    if [ "$SYS_ARCH" = "arm64" ]; then
        renkli_yaz "[1] NetHunter ARM64 (full)" "$CYAN_ACIK" "$MAVI_ACIK"
        renkli_yaz "[2] NetHunter ARM64 (minimal)" "$CYAN_ACIK" "$MAVI_ACIK"
        renkli_yaz "[3] NetHunter ARM64 (nano)" "$CYAN_ACIK" "$MAVI_ACIK"
    else
        renkli_yaz "[1] NetHunter ARMhf (full)" "$CYAN_ACIK" "$MAVI_ACIK"
        renkli_yaz "[2] NetHunter ARMhf (minimal)" "$CYAN_ACIK" "$MAVI_ACIK"
        renkli_yaz "[3] NetHunter ARMhf (nano)" "$CYAN_ACIK" "$MAVI_ACIK"
    fi
    echo -e "$(renk_gecisi "Kurmak istediğiniz görüntüyü seçin (1-3):" "$SARI" "$KIRMIZI")"
    read -r wimg || {
        renkli_yaz "❌ Girdi alınamadı!" "$KIRMIZI" "$SARI"
        log_yaz "Hata: Görüntü seçimi alınamadı."
        exit 1
    }
    case "$wimg" in
        1) wimg="full" ;;
        2) wimg="minimal" ;;
        3) wimg="nano" ;;
        *) renkli_yaz "⚠️ Geçersiz seçim, 'full' seçildi." "$SARI" "$KIRMIZI"; wimg="full" ;;
    esac
    CHROOT="$HOME/kali-${SYS_ARCH}"
    IMAGE_NAME="kali-nethunter-daily-dev-rootfs-${wimg}-${SYS_ARCH}.tar.xz"
    SHA_NAME="${IMAGE_NAME}.sha512sum"
    log_yaz "Seçilen görüntü: $wimg"
}

# Kullanıcı onayı
ask() {
    local soru="$1"
    local varsayilan="${2:-N}"
    local istem cevap
    if [ "$varsayilan" = "Y" ]; then
        istem="E/h"
        varsayilan="Y"
    else
        istem="e/H"
        varsayilan="N"
    fi
    while true; do
        echo -e "$(renk_gecisi "[?] $soru [$istem]" "$CYAN_ACIK" "$MAVI_ACIK")"
        read -r cevap || {
            renkli_yaz "❌ Girdi alınamadı!" "$KIRMIZI" "$SARI"
            log_yaz "Hata: Kullanıcı girdisi alınamadı."
            exit 1
        }
        [ -z "$cevap" ] && cevap="$varsayilan"
        case "$cevap" in
            Y*|y*|E*|e*) return 0 ;;
            N*|n*|H*|h*) return 1 ;;
            *) renkli_yaz "⚠️ Geçersiz cevap! Lütfen E veya H girin." "$SARI" "$KIRMIZI" ;;
        esac
    done
}

# Chroot hazırlığı
prepare_fs() {
    unset KEEP_CHROOT
    if [ -d "$CHROOT" ]; then
        if ask "Mevcut chroot bulundu. Silip yenisini oluşturmak ister misiniz?" "N"; then
            rm -rf "$CHROOT" 2>/dev/null || {
                renkli_yaz "❌ Eski chroot silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Hata: Eski chroot silinemedi."
                exit 1
            }
            log_yaz "Eski chroot silindi."
        else
            KEEP_CHROOT=1
            log_yaz "Mevcut chroot korundu."
        fi
    fi
}

# Bağımlılık kontrolü
check_dependencies() {
    ekran_hazirla
    renkli_yaz "📦 Bağımlılıklar kontrol ediliyor..." "$MAVI" "$YESIL"
    if ! apt-get update -y &>/dev/null; then
        apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y &>/dev/null || {
            renkli_yaz "❌ Paket listesi güncellenemedi!" "$KIRMIZI" "$SARI"
            log_yaz "Hata: apt-get update başarısız."
            exit 1
        }
    fi
    for i in proot tar wget; do
        if ! command -v "$i" >/dev/null 2>&1; then
            renkli_yaz "📥 $i kuruluyor..." "$MAVI" "$YESIL"
            apt install -y "$i" &>/dev/null || {
                renkli_yaz "❌ $i kurulamadı!" "$KIRMIZI" "$SARI"
                log_yaz "Hata: $i kurulamadı."
                exit 1
            }
        fi
    done
    log_yaz "Bağımlılıklar kontrol edildi ve kuruldu."
}

# URL belirleme
get_url() {
    ROOTFS_URL="${BASE_URL}/${IMAGE_NAME}"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
}

# Rootfs indirme (hata yapmasın)
get_rootfs() {
    ekran_hazirla
    unset KEEP_IMAGE
    if [ -f "$IMAGE_NAME" ]; then
        if ask "Mevcut görüntü dosyası bulundu. Silip yenisini indirmek ister misiniz?" "N"; then
            rm -f "$IMAGE_NAME" 2>/dev/null || {
                renkli_yaz "❌ Mevcut dosya silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Hata: Mevcut dosya silinemedi."
                exit 1
            }
        else
            KEEP_IMAGE=1
            renkli_yaz "ℹ️ Mevcut rootfs kullanılacak." "$SARI" "$KIRMIZI"
            log_yaz "Mevcut rootfs korundu."
            return
        fi
    fi
    renkli_yaz "📥 Rootfs indiriliyor: $IMAGE_NAME" "$MAVI" "$YESIL"
    get_url
    check_internet
    wget -O "$IMAGE_NAME" "$ROOTFS_URL" --continue --tries=3 --timeout=30 --progress=bar:force 2>>"$LOG_DOSYASI" || {
        renkli_yaz "❌ İndirme başarısız! İnternet bağlantınızı kontrol edin." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Rootfs indirilemedi - $ROOTFS_URL"
        exit 1
    }
    if [ ! -s "$IMAGE_NAME" ]; then
        renkli_yaz "❌ İndirilen dosya boş! Tekrar deneyin." "$KIRMIZI" "$SARI"
        log_yaz "Hata: İndirilen dosya boş."
        rm -f "$IMAGE_NAME"
        exit 1
    fi
    chmod 644 "$IMAGE_NAME" 2>/dev/null || renkli_yaz "⚠️ Dosya izinleri ayarlanamadı, devam ediliyor." "$SARI" "$KIRMIZI"
    renkli_yaz "✅ Rootfs başarıyla indirildi." "$YESIL" "$MAVI"
    log_yaz "Rootfs indirildi: $IMAGE_NAME"
}

# SHA indirme ve doğrulama
get_sha() {
    if [ -z "$KEEP_IMAGE" ]; then
        ekran_hazirla
        renkli_yaz "🔍 SHA dosyası indiriliyor..." "$MAVI" "$YESIL"
        get_url
        if [ -f "$SHA_NAME" ]; then
            rm -f "$SHA_NAME" 2>/dev/null
        fi
        wget -O "$SHA_NAME" "$SHA_URL" --continue --tries=3 --timeout=30 --progress=bar:force 2>>"$LOG_DOSYASI" || {
            renkli_yaz "⚠️ SHA dosyası indirilemedi, doğrulama atlanıyor." "$SARI" "$KIRMIZI"
            log_yaz "Uyarı: SHA dosyası indirilemedi."
            return
        }
        chmod 644 "$SHA_NAME" 2>/dev/null || renkli_yaz "⚠️ SHA izinleri ayarlanamadı, devam ediliyor." "$SARI" "$KIRMIZI"
        renkli_yaz "🔍 Rootfs doğrulanıyor..." "$MAVI" "$YESIL"
        if ! sha512sum -c "$SHA_NAME" 2>/dev/null; then
            renkli_yaz "❌ Rootfs bozuk! Dosya silindi, tekrar deneyin." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs bozuk."
            rm -f "$IMAGE_NAME" "$SHA_NAME"
            exit 1
        fi
        renkli_yaz "✅ Rootfs doğrulandı." "$YESIL" "$MAVI"
        log_yaz "Rootfs doğrulandı."
    fi
}

# Rootfs çıkarma (izin gerektirmesin)
extract_rootfs() {
    if [ -z "$KEEP_CHROOT" ]; then
        ekran_hazirla
        renkli_yaz "📦 Rootfs çıkarılıyor..." "$MAVI" "$YESIL"
        if [ ! -f "$IMAGE_NAME" ]; then
            renkli_yaz "❌ $IMAGE_NAME bulunamadı!" "$KIRMIZI" "$SARI"
            log_yaz "Hata: $IMAGE_NAME bulunamadı."
            exit 1
        fi
        check_disk_space
        mkdir -p "$CHROOT" 2>/dev/null || {
            renkli_yaz "❌ $CHROOT dizini oluşturulamadı!" "$KIRMIZI" "$SARI"
            log_yaz "Hata: $CHROOT dizini oluşturulamadı."
            exit 1
        }
        tar -xf "$IMAGE_NAME" -C "$CHROOT" 2>>"$LOG_DOSYASI" || {
            renkli_yaz "❌ Çıkarma başarısız! Dosya bozuk olabilir." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs çıkarılamadı."
            exit 1
        }
        if [ ! -d "$CHROOT/bin" ]; then
            renkli_yaz "❌ Çıkarma başarısız, chroot geçersiz!" "$KIRMIZI" "$SARI"
            log_yaz "Hata: Chroot dizini geçersiz."
            rm -rf "$CHROOT"
            exit 1
        fi
        chmod -R u+rw "$CHROOT" 2>/dev/null || renkli_yaz "⚠️ Chroot izinleri ayarlanamadı, devam ediliyor." "$SARI" "$KIRMIZI"
        renkli_yaz "✅ Rootfs başarıyla çıkarıldı." "$YESIL" "$MAVI"
        log_yaz "Rootfs çıkarıldı."
    else
        renkli_yaz "ℹ️ Mevcut chroot kullanılıyor." "$SARI" "$KIRMIZI"
    fi
}

# Başlatıcı oluşturma (rootsuz)
create_launcher() {
    NH_LAUNCHER="$HOME/bin/nethunter"
    NH_SHORTCUT="$HOME/bin/nh"
    mkdir -p "$HOME/bin" 2>/dev/null
    cat > "$NH_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "\${HOME}"
unset LD_PRELOAD
proot --link2symlink -0 -w ~ -r "$CHROOT" /bin/bash -l
EOF
    chmod 700 "$NH_LAUNCHER" 2>/dev/null || {
        renkli_yaz "❌ Başlatıcı oluşturulamadı!" "$KIRMIZI" "$SARI"
        log_yaz "Hata: Başlatıcı oluşturulamadı."
        exit 1
    }
    ln -sf "$NH_LAUNCHER" "$NH_SHORTCUT" 2>/dev/null || renkli_yaz "⚠️ Kısayol oluşturulamadı, devam ediliyor." "$SARI" "$KIRMIZI"
    log_yaz "Başlatıcı oluşturuldu."
}

# Temizlik
cleanup() {
    if [ -f "$IMAGE_NAME" ]; then
        if ask "İndirilen rootfs dosyası silinsin mi?" "N"; then
            rm -f "$IMAGE_NAME" "$SHA_NAME" 2>/dev/null || {
                renkli_yaz "❌ Dosyalar silinemedi!" "$KIRMIZI" "$SARI"
                log_yaz "Hata: İndirilen dosyalar silinemedi."
                exit 1
            }
            log_yaz "İndirilen dosyalar silindi."
        fi
    fi
}

# DNS düzeltme (rootsuz)
fix_resolv_conf() {
    echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "$CHROOT/etc/resolv.conf" 2>/dev/null || {
        renkli_yaz "⚠️ DNS ayarlanamadı, devam ediliyor." "$SARI" "$KIRMIZI"
        log_yaz "Uyarı: DNS ayarlanamadı."
    }
    log_yaz "DNS ayarlandı."
}

# Ana işlem
cd "$HOME" 2>/dev/null || {
    ekran_hazirla
    renkli_yaz "❌ Ev dizinine erişilemedi!" "$KIRMIZI" "$SARI"
    log_yaz "Hata: Ev dizinine erişilemedi."
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
renkli_yaz "🎉 ArıvaNetHunter rootsuz olarak başarıyla kuruldu!" "$YESIL" "$MAVI"
renkli_yaz "ℹ️ Başlatmak için: 'nethunter' veya 'nh'" "$CYAN_ACIK" "$MAVI_ACIK"
renkli_yaz "📜 Log dosyası: $LOG_DOSYASI" "$CYAN_ACIK" "$MAVI_ACIK"
log_yaz "Kurulum tamamlandı."