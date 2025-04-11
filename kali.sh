#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL="https://image-nethunter.kali.org/nethunter-fs/kali-daily"
USERNAME="kali"
LOG_DOSYASI="$HOME/nethunter_kurulum_$(date +%Y%m%d_%H%M%S).log"
LOGO_LINES=9  # Yeni logonun satır sayısı

KIRMIZI='\033[1;31m'
YESIL='\033[1;32m'
SARI='\033[1;33m'
MAVI='\033[1;34m'
ACIK_MAVI='\033[1;96m'
MOR='\033[1;95m'
SIFIRLA='\033[0m'

# Yeni profesyonel logo (ASCII, kodlama sorunu yok)
LOGO=$(cat <<- EOF
+-----------------------------------------+
|                                         |
|   NetHunter Kurulum Araci v$VERSION    |
|   By: @AtahanArslan | @ArivaTools       |
|                                         |
+-----------------------------------------+
|  [db]  [88Yb]  [88]  [YbdP]  [db]      |
|  [dPYb] [88dP] [88]  [dP]   [dPYb]     |
+-----------------------------------------+
EOF
)

# Ekranı temizle ve logo için sabit alan ayır
ekran_hazirla() {
    clear
    tput cup 0 0
    while IFS= read -r line; do
        printf "%*s\n" $(( ( $(tput cols) + ${#line} ) / 2 )) "$line"
    done <<< "$(echo -e "${KIRMIZI}${LOGO}${SARI}")"
}

renkli_yaz() {
    local mesaj="$1"
    local renk="$2"
    local sifirla="$3"
    tput cup $((LOGO_LINES + 1)) 0
    echo -e "${renk}${mesaj}${sifirla}"
    tput cup $((LOGO_LINES + 2)) 0
}

log_yaz() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DOSYASI"
}

# İlk ekran hazırlığı
ekran_hazirla

function unsupported_arch() {
    ekran_hazirla
    renkli_yaz "❌ Desteklenmeyen Mimari" "$KIRMIZI" "$SIFIRLA"
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
        printf "${ACIK_MAVI}[?] $soru [$istem] ${SIFIRLA}"
        read -r cevap
        [ -z "$cevap" ] && cevap="$varsayilan"
        case "$cevap" in
            Y*|y*|E*|e*) return 0 ;;
            N*|n*|H*|h*) return 1 ;;
            *) renkli_yaz "⚠️ Geçersiz cevap! Lütfen E veya H girin." "$SARI" "$SIFIRLA" ;;
        esac
    done
}

function get_arch() {
    ekran_hazirla
    renkli_yaz "🔍 Cihaz mimarisi belirleniyor..." "$MAVI" "$SIFIRLA"
    case $(getprop ro.product.cpu.abi 2>/dev/null) in
        arm64-v8a) SYS_ARCH="arm64" ;;
        armeabi|armeabi-v7a) SYS_ARCH="armhf" ;;
        *) unsupported_arch ;;
    esac
    renkli_yaz "✅ Mimari: $SYS_ARCH" "$YESIL" "$SIFIRLA"
    log_yaz "Mimari belirlendi: $SYS_ARCH"
}

function set_strings() {
    ekran_hazirla
    renkli_yaz "🛠️ Kurulum seçenekleri hazırlanıyor..." "$MAVI" "$SIFIRLA"
    if [ "$SYS_ARCH" = "arm64" ]; then
        renkli_yaz "[1] NetHunter ARM64 (full)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[2] NetHunter ARM64 (minimal)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[3] NetHunter ARM64 (nano)" "$ACIK_MAVI" "$SIFIRLA"
    else
        renkli_yaz "[1] NetHunter ARMhf (full)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[2] NetHunter ARMhf (minimal)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[3] NetHunter ARMhf (nano)" "$ACIK_MAVI" "$SIFIRLA"
    fi
    read -p "$(renkli_yaz "Kurmak istediğiniz görüntüyü seçin (1-3): " "$SARI" "$SIFIRLA")" wimg
    case "$wimg" in
        1) wimg="full" ;;
        2) wimg="minimal" ;;
        3) wimg="nano" ;;
        *) ekran_hazirla; renkli_yaz "⚠️ Geçersiz seçim, 'full' seçildi." "$SARI" "$SIFIRLA"; wimg="full" ;;
    esac
    CHROOT="kali-${SYS_ARCH}"
    IMAGE_NAME="kali-nethunter-daily-dev-rootfs-${wimg}-${SYS_ARCH}.tar.xz"
    SHA_NAME="${IMAGE_NAME}.sha512sum"
    log_yaz "Seçilen görüntü: $wimg"
}

function prepare_fs() {
    unset KEEP_CHROOT
    if [ -d "$CHROOT" ]; then
        if ask "Mevcut chroot bulundu. Silip yenisini oluşturmak ister misiniz?" "N"; then
            rm -rf "$CHROOT" 2>/dev/null
            renkli_yaz "✅ Eski chroot silindi." "$YESIL" "$SIFIRLA"
            log_yaz "Eski chroot silindi."
        else
            KEEP_CHROOT=1
            renkli_yaz "⚠️ Mevcut chroot kullanılacak." "$SARI" "$SIFIRLA"
            log_yaz "Mevcut chroot korundu."
        fi
    fi
}

function cleanup() {
    if [ -f "$IMAGE_NAME" ]; then
        if ask "İndirilen rootfs dosyası silinsin mi?" "N"; then
            rm -f "$IMAGE_NAME" "$SHA_NAME" 2>/dev/null
            renkli_yaz "✅ Dosyalar temizlendi." "$YESIL" "$SIFIRLA"
            log_yaz "İndirilen dosyalar silindi."
        fi
    fi
}

function check_dependencies() {
    ekran_hazirla
    renkli_yaz "🔧 Bağımlılıklar kontrol ediliyor..." "$MAVI" "$SIFIRLA"
    if ! apt-get update -y &>/dev/null; then
        apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y &>/dev/null || {
            renkli_yaz "❌ Hata: Paket listesi güncellenemedi." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: apt-get update başarısız."
            exit 1
        }
    fi
    for i in proot tar axel wget; do
        if command -v "$i" >/dev/null 2>&1; then
            renkli_yaz "✅ $i mevcut." "$YESIL" "$SIFIRLA"
        else
            renkli_yaz "📦 $i kuruluyor..." "$SARI" "$SIFIRLA"
            apt install -y "$i" &>/dev/null || {
                renkli_yaz "❌ Hata: $i kurulamadı." "$KIRMIZI" "$SIFIRLA"
                log_yaz "Hata: $i kurulamadı."
                exit 1
            }
        fi
    done
    apt upgrade -y &>/dev/null
    renkli_yaz "✅ Bağımlılıklar hazır." "$YESIL" "$SIFIRLA"
    log_yaz "Bağımlılıklar kontrol edildi ve güncellendi."
}

function get_url() {
    ROOTFS_URL="${BASE_URL}/${IMAGE_NAME}"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
}

function get_rootfs() {
    unset KEEP_IMAGE
    if [ -f "$IMAGE_NAME" ]; then
        if ask "Mevcut görüntü dosyası bulundu. Silip yenisini indirmek ister misiniz?" "N"; then
            rm -f "$IMAGE_NAME" 2>/dev/null
        else
            KEEP_IMAGE=1
            renkli_yaz "⚠️ Mevcut rootfs arşivi kullanılacak." "$SARI" "$SIFIRLA"
            log_yaz "Mevcut rootfs korundu."
            return
        fi
    fi
    ekran_hazirla
    renkli_yaz "📥 Kök dosya sistemi indiriliyor..." "$MAVI" "$SIFIRLA"
    get_url
    renkli_yaz "🔄 Axel ile indiriliyor..." "$ACIK_MAVI" "$SIFIRLA"
    if axel -n 4 "$ROOTFS_URL" 2>/dev/null; then
        renkli_yaz "✅ İndirme tamamlandı (axel)." "$YESIL" "$SIFIRLA"
    else
        renkli_yaz "⚠️ Axel başarısız, wget ile deneniyor..." "$SARI" "$SIFIRLA"
        if wget --continue "$ROOTFS_URL" -O "$IMAGE_NAME" 2>/dev/null; then
            renkli_yaz "✅ İndirme tamamlandı (wget)." "$YESIL" "$SIFIRLA"
        else
            renkli_yaz "❌ Hata: İndirme başarısız. İnternet bağlantınızı kontrol edin." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Rootfs indirilemedi - $ROOTFS_URL"
            exit 1
        fi
    fi
    log_yaz "Kök dosya sistemi indirildi: $IMAGE_NAME"
}

function check_sha_url() {
    curl --head --silent --fail "$SHA_URL" >/dev/null 2>&1
}

function verify_sha() {
    if [ -z "$KEEP_IMAGE" ] && [ -f "$SHA_NAME" ]; then
        ekran_hazirla
        renkli_yaz "🔍 Bütünlük kontrol ediliyor..." "$MAVI" "$SIFIRLA"
        if ! sha512sum -c "$SHA_NAME" 2>/dev/null; then
            renkli_yaz "❌ Hata: Rootfs bozuk. Lütfen tekrar deneyin." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Rootfs bozuk."
            exit 1
        fi
        renkli_yaz "✅ Bütünlük doğrulandı." "$YESIL" "$SIFIRLA"
    fi
}

function get_sha() {
    if [ -z "$KEEP_IMAGE" ]; then
        ekran_hazirla
        renkli_yaz "📥 SHA dosyası alınıyor..." "$MAVI" "$SIFIRLA"
        get_url
        [ -f "$SHA_NAME" ] && rm -f "$SHA_NAME" 2>/dev/null
        if check_sha_url; then
            renkli_yaz "🔄 SHA indiriliyor..." "$ACIK_MAVI" "$SIFIRLA"
            if axel -n 4 "$SHA_URL" 2>/dev/null || wget --continue "$SHA_URL" -O "$SHA_NAME" 2>/dev/null; then
                verify_sha
                log_yaz "SHA dosyası indirildi ve doğrulandı."
            else
                renkli_yaz "⚠️ SHA dosyası indirilemedi, doğrulama atlanıyor." "$SARI" "$SIFIRLA"
                log_yaz "Uyarı: SHA dosyası indirilemedi."
            fi
        else
            renkli_yaz "⚠️ SHA dosyası bulunamadı, doğrulama atlanıyor." "$SARI" "$SIFIRLA"
            log_yaz "Uyarı: SHA dosyası mevcut değil."
        fi
    fi
}

function extract_rootfs() {
    if [ -z "$KEEP_CHROOT" ]; then
        ekran_hazirla
        renkli_yaz "📤 Kök dosya sistemi çıkarılıyor..." "$MAVI" "$SIFIRLA"
        if ! proot --link2symlink tar -xf "$IMAGE_NAME" 2>/dev/null; then
            renkli_yaz "❌ Hata: Çıkarma başarısız." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Rootfs çıkarılamadı."
            exit 1
        fi
        renkli_yaz "✅ Çıkarma tamamlandı." "$YESIL" "$SIFIRLA"
        log_yaz "Kök dosya sistemi çıkarıldı."
    else
        renkli_yaz "⚠️ Mevcut rootfs dizini kullanılıyor." "$SARI" "$SIFIRLA"
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

    chmod 700 "$NH_LAUNCHER" 2>/dev/null
    [ -L "$NH_SHORTCUT" ] && rm -f "$NH_SHORTCUT" 2>/dev/null
    [ ! -f "$NH_SHORTCUT" ] && ln -s "$NH_LAUNCHER" "$NH_SHORTCUT" >/dev/null 2>&1
    log_yaz "NetHunter başlatıcısı oluşturuldu."
}

function check_kex() {
    if [ "$wimg" = "nano" ] || [ "$wimg" = "minimal" ]; then
        ekran_hazirla
        renkli_yaz "🖥️ KeX paketleri kuruluyor..." "$MAVI" "$SIFIRLA"
        if ! nh sudo apt update || ! nh sudo apt install -y tightvncserver kali-desktop-xfce &>/dev/null; then
            renkli_yaz "⚠️ KeX paketleri kurulamadı, devam ediliyor..." "$SARI" "$SIFIRLA"
            log_yaz "Uyarı: KeX paketleri kurulamadı."
        else
            renkli_yaz "✅ KeX paketleri kuruldu." "$YESIL" "$SIFIRLA"
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
        printf "\n\${sessions}\n\nKeX istemcisini kullanarak bağlanabilirsiniz.\n"
    elif [ -n "\$starting_kex" ]; then
        printf '\nKeX sunucusu başlatılamadı.\n"nethunter kex kill" ile deneyin veya Termux\'u yeniden başlatın.\n'
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

    chmod 700 "$KEX_LAUNCHER" 2>/dev/null
    log_yaz "KeX başlatıcısı oluşturuldu."
}

function fix_profile_bash() {
    [ -f "$CHROOT/root/.bash_profile" ] && sed -i '/if/,/fi/d' "$CHROOT/root/.bash_profile" 2>/dev/null
    log_yaz "Bash profili düzeltildi."
}

function fix_resolv_conf() {
    echo -e "nameserver 9.9.9.9\nnameserver 149.112.112.112" > "$CHROOT/etc/resolv.conf" 2>/dev/null
    log_yaz "DNS ayarları yapılandırıldı."
}

function fix_sudo() {
    chmod +s "$CHROOT/usr/bin/sudo" "$CHROOT/usr/bin/su" 2>/dev/null
    echo "kali    ALL=(ALL:ALL) ALL" > "$CHROOT/etc/sudoers.d/kali" 2>/dev/null
    echo "Set disable_coredump false" > "$CHROOT/etc/sudo.conf" 2>/dev/null
    log_yaz "Sudo ayarları yapılandırıldı."
}

function fix_uid() {
    USRID=$(id -u)
    GRPID=$(id -g)
    nh -r usermod -u "$USRID" kali 2>/dev/null
    nh -r groupmod -g "$GRPID" kali 2>/dev/null
    log_yaz "Kullanıcı ID düzeltildi."
}

# Ana kurulum akışı
cd "$HOME" || {
    ekran_hazirla
    renkli_yaz "❌ Hata: Ev dizinine erişilemedi." "$KIRMIZI" "$SIFIRLA"
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
renkli_yaz "🛠️ NetHunter Termux için yapılandırılıyor..." "$MAVI" "$SIFIRLA"
fix_profile_bash
fix_resolv_conf
fix_sudo
check_kex
create_kex_launcher
fix_uid

ekran_hazirla
renkli_yaz "🎉 Kali NetHunter Termux için başarıyla kuruldu!" "$YESIL" "$SIFIRLA"
renkli_yaz "📌 Kullanım Komutları:" "$YESIL" "$SIFIRLA"
renkli_yaz "  nethunter             # NetHunter CLI başlat" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "  nethunter kex passwd  # KeX şifresi ayarla" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "  nethunter kex &       # NetHunter GUI başlat" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "  nethunter kex stop    # NetHunter GUI durdur" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "  nethunter -r          # Root olarak çalıştır" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "  nh                    # nethunter kısayolu" "$ACIK_MAVI" "$SIFIRLA"
renkli_yaz "📜 Log dosyası: $LOG_DOSYASI" "$SARI" "$SIFIRLA"
log_yaz "Kurulum başarıyla tamamlandı."