#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL="https://image-nethunter.kali.org/nethunter-fs/kali-daily"
USERNAME="kali"
LOG_DOSYASI="$HOME/nethunter_kurulum_$(date +%Y%m%d_%H%M%S).log"
LOGO_LINES=9

# Renk kodları
KIRMIZI='\033[1;31m'      # Red
YESIL='\033[1;32m'        # Green
SARI='\033[1;33m'         # Yellow
MAVI='\033[1;34m'         # Blue
MOR='\033[1;35m'          # Magenta
CYAN='\033[1;36m'         # Cyan
BEYAZ='\033[1;37m'        # White
SIFIRLA='\033[0m'         # Reset
KIRMIZI_ACIK='\033[91m'   # Bright Red
YESIL_ACIK='\033[92m'     # Bright Green
SARI_ACIK='\033[93m'      # Bright Yellow
MAVI_ACIK='\033[94m'      # Bright Blue
MOR_ACIK='\033[95m'       # Bright Magenta
CYAN_ACIK='\033[96m'      # Bright Cyan

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

# Logo (her satırda renk geçişi ile)
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
    if [ $len -gt $cols ]; then
        mesaj="${mesaj:0:$((cols - 3))}..."
    fi
    echo -e "$(renk_gecisi "$mesaj" "$start_color" "$end_color")"
}

log_yaz() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DOSYASI" 2>/dev/null || {
        echo -e "$(renk_gecisi "Hata: Log dosyasına yazılamadı: $LOG_DOSYASI" "$KIRMIZI" "$SARI")" >&2
        exit 1
    }
}

ekran_hazirla

function unsupported_arch() {
    ekran_hazirla
    renkli_yaz "❌ Desteklenmeyen Mimari" "$KIRMIZI" "$SARI"
    log_yaz "Hata: Desteklenmeyen mimari."
    exit 1
}

function ask() {
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
            renkli_yaz "❌ Hata: Kullanıcı girdisi alınamadı." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Kullanıcı girdisi alınamadı."
            exit 1
        }
        [ -z "$cevap" ] && cevap="$varsayilan"
        case "$cevap" in
            Y*|y*|E*|e*) return 0 ;;
            N*|n*|H*|h*) return 1 ;;
            *) renkli_yaz "⚠️ Gecersiz cevap! Lutfen E veya H girin." "$SARI" "$KIRMIZI" ;;
        esac
    done
}

function get_arch() {
    ekran_hazirla
    local arch=$(getprop ro.product.cpu.abi 2>/dev/null)
    case "$arch" in
        arm64-v8a) SYS_ARCH="arm64" ;;
        armeabi|armeabi-v7a) SYS_ARCH="armhf" ;;
        *) unsupported_arch ;;
    esac
    [ -z "$SYS_ARCH" ] && {
        ekran_hazirla
        renkli_yaz "❌ Hata: Mimari belirlenemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Mimari belirlenemedi."
        exit 1
    }
    log_yaz "Mimari belirlendi: $SYS_ARCH"
}

function set_strings() {
    ekran_hazirla
    if [ "$SYS_ARCH" = "arm64" ]; then
        echo -e "$(renk_gecisi "[1] NetHunter ARM64 (full)" "$MAVI" "$YESIL")"
        echo -e "$(renk_gecisi "[2] NetHunter ARM64 (minimal)" "$MAVI" "$YESIL")"
        echo -e "$(renk_gecisi "[3] NetHunter ARM64 (nano)" "$MAVI" "$YESIL")"
    else
        echo -e "$(renk_gecisi "[1] NetHunter ARMhf (full)" "$MAVI" "$YESIL")"
        echo -e "$(renk_gecisi "[2] NetHunter ARMhf (minimal)" "$MAVI" "$YESIL")"
        echo -e "$(renk_gecisi "[3] NetHunter ARMhf (nano)" "$MAVI" "$YESIL")"
    fi
    echo -e "$(renk_gecisi "Kurmak istediginiz goruntuyu secin (1-3):" "$SARI" "$KIRMIZI")"
    read -r wimg || {
        renkli_yaz "❌ Hata: Görüntü seçimi alınamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Görüntü seçimi alınamadı."
        exit 1
    }
    case "$wimg" in
        1) wimg="full" ;;
        2) wimg="minimal" ;;
        3) wimg="nano" ;;
        *) ekran_hazirla; renkli_yaz "⚠️ Gecersiz secim, 'full' secildi." "$SARI" "$KIRMIZI"; wimg="full" ;;
    esac
    CHROOT="kali-${SYS_ARCH}"
    IMAGE_NAME="kali-nethunter-daily-dev-rootfs-${wimg}-${SYS_ARCH}.tar.xz"
    SHA_NAME="${IMAGE_NAME}.sha512sum"
    log_yaz "Seçilen görüntü: $wimg"
}

function prepare_fs() {
    unset KEEP_CHROOT
    if [ -d "$CHROOT" ]; then
        if ask "Mevcut chroot bulundu. Silip yenisini olusturmak ister misiniz?" "N"; then
            rm -rf "$CHROOT" 2>/dev/null || {
                renkli_yaz "❌ Hata: Eski chroot silinemedi." "$KIRMIZI" "$SARI"
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

function cleanup() {
    if [ -f "$IMAGE_NAME" ]; then
        if ask "Indirilen rootfs dosyasi silinsin mi?" "N"; then
            rm -f "$IMAGE_NAME" "$SHA_NAME" 2>/dev/null || {
                renkli_yaz "❌ Hata: İndirilen dosyalar silinemedi." "$KIRMIZI" "$SARI"
                log_yaz "Hata: İndirilen dosyalar silinemedi."
                exit 1
            }
            log_yaz "İndirilen dosyalar silindi."
        fi
    fi
}

function check_dependencies() {
    ekran_hazirla
    if ! apt-get update -y &>/dev/null; then
        apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y &>/dev/null || {
            renkli_yaz "❌ Hata: Paket listesi guncellenemedi." "$KIRMIZI" "$SARI"
            log_yaz "Hata: apt-get update başarısız."
            exit 1
        }
    fi
    for i in proot tar axel wget; do
        if ! command -v "$i" >/dev/null 2>&1; then
            apt install -y "$i" &>/dev/null || {
                renkli_yaz "❌ Hata: $i kurulamadi." "$KIRMIZI" "$SARI"
                log_yaz "Hata: $i kurulamadı."
                exit 1
            }
        fi
    done
    apt upgrade -y &>/dev/null || {
        renkli_yaz "❌ Hata: Sistem güncellenemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: apt upgrade başarısız."
        exit 1
    }
    log_yaz "Bağımlılıklar kontrol edildi ve güncellendi."
}

function get_url() {
    ROOTFS_URL="${BASE_URL}/${IMAGE_NAME}"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
}

function get_rootfs() {
    unset KEEP_IMAGE
    if [ -f "$IMAGE_NAME" ]; then
        if ask "Mevcut goruntu dosyasi bulundu. Silip yenisini indirmek ister misiniz?" "N"; then
            rm -f "$IMAGE_NAME" 2>/dev/null || {
                renkli_yaz "❌ Hata: Mevcut görüntü dosyası silinemedi." "$KIRMIZI" "$SARI"
                log_yaz "Hata: Mevcut görüntü dosyası silinemedi."
                exit 1
            }
        else
            KEEP_IMAGE=1
            log_yaz "Mevcut rootfs korundu."
            return
        fi
    fi
    ekran_hazirla
    get_url
    if ! axel -n 4 "$ROOTFS_URL" 2>/dev/null; then
        if ! wget --continue "$ROOTFS_URL" -O "$IMAGE_NAME" 2>/dev/null; then
            renkli_yaz "❌ Hata: Indirme basarisiz. Internet baglantinizi kontrol edin." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs indirilemedi - $ROOTFS_URL"
            exit 1
        fi
    fi
    [ ! -f "$IMAGE_NAME" ] && {
        renkli_yaz "❌ Hata: Rootfs dosyası indirilemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Rootfs dosyası indirilemedi."
        exit 1
    }
    log_yaz "Kök dosya sistemi indirildi: $IMAGE_NAME"
}

function check_sha_url() {
    curl --head --silent --fail "$SHA_URL" >/dev/null 2>&1
}

function verify_sha() {
    if [ -z "$KEEP_IMAGE" ] && [ -f "$SHA_NAME" ]; then
        ekran_hazirla
        if ! sha512sum -c "$SHA_NAME" 2>/dev/null; then
            renkli_yaz "❌ Hata: Rootfs bozuk. Lutfen tekrar deneyin." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs bozuk."
            exit 1
        fi
    fi
}

function get_sha() {
    if [ -z "$KEEP_IMAGE" ]; then
        ekran_hazirla
        get_url
        if [ -f "$SHA_NAME" ]; then
            rm -f "$SHA_NAME" 2>/dev/null || {
                renkli_yaz "❌ Hata: Eski SHA dosyası silinemedi." "$KIRMIZI" "$SARI"
                log_yaz "Hata: Eski SHA dosyası silinemedi."
                exit 1
            }
        fi
        if check_sha_url; then
            if ! axel -n 4 "$SHA_URL" 2>/dev/null && ! wget --continue "$SHA_URL" -O "$SHA_NAME" 2>/dev/null; then
                log_yaz "Uyarı: SHA dosyası indirilemedi."
            else
                verify_sha
                log_yaz "SHA dosyası indirildi ve doğrulandı."
            fi
        else
            log_yaz "Uyarı: SHA dosyası mevcut değil."
        fi
    fi
}

function extract_rootfs() {
    if [ -z "$KEEP_CHROOT" ]; then
        ekran_hazirla
        if ! proot --link2symlink tar -xf "$IMAGE_NAME" 2>/dev/null; then
            renkli_yaz "❌ Hata: Cikarma basarisiz." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs çıkarılamadı."
            exit 1
        fi
        [ ! -d "$CHROOT" ] && {
            renkli_yaz "❌ Hata: Rootfs çıkarılamadı, chroot dizini oluşturulmadı." "$KIRMIZI" "$SARI"
            log_yaz "Hata: Rootfs çıkarılamadı, chroot dizini oluşturulmadı."
            exit 1
        }
        log_yaz "Kök dosya sistemi çıkarıldı."
    fi
}

function create_launcher() {
    NH_LAUNCHER=${PREFIX:-/data/data/com.termux/files/usr}/bin/nethunter
    NH_SHORTCUT=${PREFIX:-/data/data/com.termux/files/usr}/bin/nh
    cat > "$NH_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
cd "\${HOME}"
unset LD_PRELOAD
[ ! -f "$CHROOT/root/.version" ] && touch "$CHROOT/root/.version"

user="$USERNAME"
home="/home/\$user"
start="sudo -u kali /bin/bash"

if grep -q "kali" "${CHROOT}/etc/passwd" 2>/dev/null; then
    KALIUSR="1"
else
    KALIUSR="0"
fi
if [ "\$KALIUSR" = "0" ] || [ "\$#" -ne 0 ] && { [ "\$1" = "-r" ] || [ "\$1" = "-R" ]; }; then
    user="root"
    home="/\$user"
    start="/bin/bash --login"
    [ "\$#" -ne 0 ] && { [ "\$1" = "-r" ] || [ "\$1" = "-R" ]; } && shift
fi

cmdline="proot \\
        --link2symlink \\
        -0 \\
        -r '$CHROOT' \\
        -b /dev \\
        -b /proc \\
        -b /sdcard \\
        -b '$CHROOT'\$home:/dev/shm \\
        -w \$home \\
           /usr/bin/env -i \\
           HOME=\$home \\
           PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \\
           TERM=\$TERM \\
           LANG=C.UTF-8 \\
           \$start"

cmd="\$@"
[ "\$#" -eq 0 ] && exec \$cmdline || \$cmdline -c "\$cmd"
EOF

    chmod 700 "$NH_LAUNCHER" 2>/dev/null || {
        renkli_yaz "❌ Hata: NetHunter başlatıcısı oluşturulamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: NetHunter başlatıcısı oluşturulamadı."
        exit 1
    }
    [ -L "$NH_SHORTCUT" ] && rm -f "$NH_SHORTCUT" 2>/dev/null
    [ ! -f "$NH_SHORTCUT" ] && ln -s "$NH_LAUNCHER" "$NH_SHORTCUT" >/dev/null 2>&1 || {
        renkli_yaz "❌ Hata: NetHunter kısayolu oluşturulamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: NetHunter kısayolu oluşturulamadı."
        exit 1
    }
    log_yaz "NetHunter başlatıcısı oluşturuldu."
}

function check_kex() {
    if [ "$wimg" = "nano" ] || [ "$wimg" = "minimal" ]; then
        ekran_hazirla
        if ! nh sudo apt update &>/dev/null || ! nh sudo apt install -y tightvncserver kali-desktop-xfce &>/dev/null; then
            log_yaz "Uyarı: KeX paketleri kurulamadı."
        fi
    fi
}

function create_kex_launcher() {
    KEX_LAUNCHER="$CHROOT/usr/bin/kex"
    cat > "$KEX_LAUNCHER" <<- EOF
#!/bin/bash

start_kex() {
    [ ! -f ~/.vnc/passwd ] && passwd_kex
    USR=\$(whoami)
    [ "\$USR" = "root" ] && SCREEN=":2" || SCREEN=":1"
    export MOZ_FAKE_NO_SANDBOX=1 HOME="\${HOME}" USER="\${USR}"
    LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libgcc_s.so.1 nohup vncserver "\$SCREEN" >/dev/null 2>&1 </dev/null
    starting_kex=1
    return 0
}

stop_kex() {
    vncserver -kill :1 2>/dev/null | sed s/"Xtigervnc"/"NetHunter KeX"/
    vncserver -kill :2 2>/dev/null | sed s/"Xtigervnc"/"NetHunter KeX"/
    return \$?
}

passwd_kex() {
    vncpasswd
    return \$?
}

status_kex() {
    sessions=\$(vncserver -list 2>/dev/null | sed s/"TigerVNC"/"NetHunter KeX"/)
    if [[ \$sessions == *"590"* ]]; then
        printf "\n\${sessions}\n\nKeX istemcisini kullanarak baglanabilirsiniz.\n"
    elif [ -n "\$starting_kex" ]; then
        printf '\nKeX sunucusu baslatilamadi.\n"nethunter kex kill" ile deneyin veya Termux\'u yeniden baslatin.\n'
    fi
    return 0
}

kill_kex() {
    pkill Xtigervnc 2>/dev/null
    return \$?
}

case \$1 in
    start) start_kex ;;
    stop) stop_kex ;;
    status) status_kex ;;
    passwd) passwd_kex ;;
    kill) kill_kex ;;
    *) stop_kex; start_kex; status_kex ;;
esac
EOF

    chmod 700 "$KEX_LAUNCHER" 2>/dev/null || {
        renkli_yaz "❌ Hata: KeX başlatıcısı oluşturulamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: KeX başlatıcısı oluşturulamadı."
        exit 1
    }
    log_yaz "KeX başlatıcısı oluşturuldu."
}

function fix_profile_bash() {
    [ -f "$CHROOT/root/.bash_profile" ] && sed -i '/if/,/fi/d' "$CHROOT/root/.bash_profile" 2>/dev/null || {
        renkli_yaz "❌ Hata: Bash profili düzeltilemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Bash profili düzeltilemedi."
        exit 1
    }
    log_yaz "Bash profili düzeltildi."
}

function fix_resolv_conf() {
    echo -e "nameserver 9.9.9.9\nnameserver 149.112.112.112" > "$CHROOT/etc/resolv.conf" 2>/dev/null || {
        renkli_yaz "❌ Hata: DNS ayarları yapılandırılamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: DNS ayarları yapılandırılamadı."
        exit 1
    }
    log_yaz "DNS ayarları yapılandırıldı."
}

function fix_sudo() {
    chmod +s "$CHROOT/usr/bin/sudo" "$CHROOT/usr/bin/su" 2>/dev/null || {
        renkli_yaz "❌ Hata: Sudo izinleri ayarlanamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Sudo izinleri ayarlanamadı."
        exit 1
    }
    echo "kali    ALL=(ALL:ALL) ALL" > "$CHROOT/etc/sudoers.d/kali" 2>/dev/null || {
        renkli_yaz "❌ Hata: Sudoers dosyası oluşturulamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Sudoers dosyası oluşturulamadı."
        exit 1
    }
    echo "Set disable_coredump false" > "$CHROOT/etc/sudo.conf" 2>/dev/null || {
        renkli_yaz "❌ Hata: Sudo yapılandırması ayarlanamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Sudo yapılandırması ayarlanamadı."
        exit 1
    }
    log_yaz "Sudo ayarları yapılandırıldı."
}

function fix_uid() {
    USRID=$(id -u 2>/dev/null) || {
        renkli_yaz "❌ Hata: Kullanıcı ID alınamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Kullanıcı ID alınamadı."
        exit 1
    }
    GRPID=$(id -g 2>/dev/null) || {
        renkli_yaz "❌ Hata: Grup ID alınamadı." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Grup ID alınamadı."
        exit 1
    }
    nh -r usermod -u "$USRID" kali 2>/dev/null || {
        renkli_yaz "❌ Hata: Kullanıcı ID düzeltilemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Kullanıcı ID düzeltilemedi."
        exit 1
    }
    nh -r groupmod -g "$GRPID" kali 2>/dev/null || {
        renkli_yaz "❌ Hata: Grup ID düzeltilemedi." "$KIRMIZI" "$SARI"
        log_yaz "Hata: Grup ID düzeltilemedi."
        exit 1
    }
    log_yaz "Kullanıcı ID düzeltildi."
}

cd "$HOME" 2>/dev/null || {
    ekran_hazirla
    renkli_yaz "❌ Hata: Ev dizinine erisilemedi." "$KIRMIZI" "$SARI"
    log_yaz "Hata: Ev dizinine erişilemedi."
    exit 1
}
ekran_hazirla
get_arch
set_strings
prepare_fs
check_dependencies
get_rootfs
get_sha
extract_rootfs
create_launcher
cleanup

ekran_hazirla
fix_profile_bash
fix_resolv_conf
fix_sudo
check_kex
create_kex_launcher
fix_uid

ekran_hazirla
log_yaz "Kurulum başarıyla tamamlandı."