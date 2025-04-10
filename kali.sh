#!/data/data/com.termux/files/usr/bin/bash -e

SURUM=2024091801
TEMEL_URL="https://images.kali.org/nethunter"
KULLANICI_ADI=kali
LOG_DOSYASI="$HOME/nethunter_kurulum_$(date +%Y%m%d_%H%M%S).log"
LOGO_LINES=10  # Logonun satır sayısı (wrapper'da kullanılacak)

KIRMIZI='\033[1;31m'
YESIL='\033[1;32m'
SARI='\033[1;33m'
MAVI='\033[1;34m'
ACIK_MAVI='\033[1;96m'
MOR='\033[1;95m'
SIFIRLA='\033[0m'

renkli_yaz() {
    tput cup $((LOGO_LINES + 1)) 0
    echo -e "${2}${1}${3}"
    tput cup $((LOGO_LINES + 2)) 0
}

log_yaz() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DOSYASI"
}

baslangic_menu() {
    renkli_yaz "🌟 Hoş Geldiniz! Lütfen bir seçenek seçin:" "$YESIL" "$SIFIRLA"
    echo
    renkli_yaz "[1] Yazılımı Çalıştır 🚀" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "[2] Yönetici ile İletişim 📧" "$MOR" "$SIFIRLA"
    renkli_yaz "[3] Sosyal Medya Hesaplarımız 🌐" "$MAVI" "$SIFIRLA"
    renkli_yaz "[4] Çıkış 🚪" "$KIRMIZI" "$SIFIRLA"
    read -p "$(renkli_yaz "Seçiminiz (1-4): " "$SARI" "$SIFIRLA")" secim

    case $secim in
        1) sistem_kontrol && kurulum_baslat ;;
        2) yonetici_iletisim ;;
        3) sosyal_medya ;;
        4) renkli_yaz "👋 Çıkış yapılıyor..." "$KIRMIZI" "$SIFIRLA"; log_yaz "Kullanıcı çıkış yaptı."; exit 0 ;;
        *) renkli_yaz "❌ Geçersiz seçim!" "$KIRMIZI" "$SIFIRLA"; sleep 2; baslangic_menu ;;
    esac
}

yonetici_iletisim() {
    renkli_yaz "📧 Yönetici ile İletişim" "$MOR" "$SIFIRLA"
    renkli_yaz "E-posta: siberdunyaniz@gmail.com" "$YESIL" "$SIFIRLA"
    renkli_yaz "Telefon: " "$YESIL" "$SIFIRLA"
    renkli_yaz "Geri dönmek için herhangi bir tuşa basın..." "$SARI" "$SIFIRLA"
    read -n 1
    baslangic_menu
}

sosyal_medya() {
    renkli_yaz "🌐 Sosyal Medya Hesaplarımız" "$MAVI" "$SIFIRLA"
    renkli_yaz "Twitter: @siberdunyanizR" "$YESIL" "$SIFIRLA"
    renkli_yaz "GitHub: github.com/siberdunyaniz" "$YESIL" "$SIFIRLA"
    renkli_yaz "Instagram: @SiberDunyaniz" "$YESIL" "$SIFIRLA"
    renkli_yaz "Geri dönmek için herhangi bir tuşa basın..." "$SARI" "$SIFIRLA"
    read -n 1
    baslangic_menu
}

sistem_kontrol() {
    renkli_yaz "🔍 Sistem gereksinimleri kontrol ediliyor..." "$MAVI" "$SIFIRLA"
    if ! command -v getprop >/dev/null 2>&1; then
        renkli_yaz "❌ getprop komutu bulunamadı. Termux ortamı gerekli." "$KIRMIZI" "$SIFIRLA"
        log_yaz "Hata: getprop komutu eksik."
        exit 1
    fi
    if [ "$(df -h "$HOME" | awk 'NR==2 {print $4}')" \< "5G" ]; then
        renkli_yaz "❌ Yetersiz depolama alanı (minimum 5GB gerekli)." "$KIRMIZI" "$SIFIRLA"
        log_yaz "Hata: Yetersiz depolama alanı."
        exit 1
    fi
    renkli_yaz "✅ Sistem hazır." "$YESIL" "$SIFIRLA"
}

desteklenmeyen_mimari() {
    renkli_yaz "❌ Desteklenmeyen Mimari" "$KIRMIZI" "$SIFIRLA"
    log_yaz "Hata: Desteklenmeyen mimari."
    exit 1
}

soru_sor() {
    while true; do
        if [ "${2:-}" = "E" ]; then
            istem="E/h"
            varsayilan=E
        else
            istem="e/H"
            varsayilan=H
        fi
        printf "${ACIK_MAVI}[?] $1 [$istem] ${SIFIRLA}"
        read -p "" CEVAP
        [ -z "$CEVAP" ] && CEVAP=$varsayilan
        case "$CEVAP" in
            E*|e*) return 0 ;;
            H*|h*) return 1 ;;
        esac
    done
}

mimari_belirle() {
    renkli_yaz "🔍 Cihaz mimarisi belirleniyor..." "$MAVI" "$SIFIRLA"
    case $(getprop ro.product.cpu.abi) in
        arm64-v8a) SISTEM_MIMARISI=arm64 ;;
        armeabi|armeabi-v7a) SISTEM_MIMARISI=armhf ;;
        *) desteklenmeyen_mimari ;;
    esac
    renkli_yaz "✅ Mimari: $SISTEM_MIMARISI" "$YESIL" "$SIFIRLA"
    log_yaz "Mimari belirlendi: $SISTEM_MIMARISI"
}

bilgileri_ayarla() {
    renkli_yaz "🛠️ Kurulum seçenekleri hazırlanıyor..." "$MAVI" "$SIFIRLA"
    if [[ $SISTEM_MIMARISI == "arm64" ]]; then
        renkli_yaz "[1] NetHunter ARM64 (full)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[2] NetHunter ARM64 (minimal)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[3] NetHunter ARM64 (nano)" "$ACIK_MAVI" "$SIFIRLA"
    else
        renkli_yaz "[1] NetHunter ARMhf (full)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[2] NetHunter ARMhf (minimal)" "$ACIK_MAVI" "$SIFIRLA"
        renkli_yaz "[3] NetHunter ARMhf (nano)" "$ACIK_MAVI" "$SIFIRLA"
    fi
    read -p "$(renkli_yaz "Seçiminiz (1-3): " "$SARI" "$SIFIRLA")" secilen_goruntu
    case "$secilen_goruntu" in
        1) goruntu="full" ;;
        2) goruntu="minimal" ;;
        3) goruntu="nano" ;;
        *) renkli_yaz "⚠️ Geçersiz seçim, 'full' seçildi." "$SARI" "$SIFIRLA"; goruntu="full" ;;
    esac
    CHROOT=kali-${SISTEM_MIMARISI}
    GORUNTU_ADI="nethunter-2024.3-kalifs-${goruntu}-${SISTEM_MIMARISI}.tar.xz"
    SHA_ADI="${GORUNTU_ADI}.sha512sum"
    log_yaz "Seçilen görüntü: $goruntu"
}

dosya_sistemini_hazirla() {
    if [ -d "$CHROOT" ]; then
        if soru_sor "Mevcut chroot bulundu. Yedeklemek ister misiniz?" "E"; then
            yedek_ad="chroot_yedek_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$yedek_ad" "$CHROOT" && renkli_yaz "✅ Yedek oluşturuldu: $yedek_ad" "$YESIL" "$SIFIRLA"
            log_yaz "Chroot yedeklendi: $yedek_ad"
        fi
        if soru_sor "Mevcut chroot silinsin mi?" "H"; then
            rm -rf "$CHROOT"
            renkli_yaz "✅ Eski chroot silindi." "$YESIL" "$SIFIRLA"
            log_yaz "Eski chroot silindi."
        else
            CHROOT_SAKLA=1
        fi
    fi
}

temizlik_yap() {
    if [ -f "$GORUNTU_ADI" ] && soru_sor "İndirilen dosyalar silinsin mi?" "H"; then
        rm -f "$GORUNTU_ADI" "$SHA_ADI"
        renkli_yaz "✅ Dosyalar temizlendi." "$YESIL" "$SIFIRLA"
        log_yaz "İndirilen dosyalar silindi."
    fi
}

bagimliliklari_kontrol_et() {
    renkli_yaz "🔧 Bağımlılıklar kontrol ediliyor..." "$MAVI" "$SIFIRLA"
    apt-get update -y &>/dev/null || {
        renkli_yaz "❌ Paket listesi güncellenemedi." "$KIRMIZI" "$SIFIRLA"
        log_yaz "Hata: apt-get update başarısız."
        exit 1
    }
    for paket in proot tar axel wget; do
        if ! command -v "$paket" >/dev/null 2>&1; then
            renkli_yaz "📦 $paket kuruluyor..." "$SARI" "$SIFIRLA"
            apt install -y "$paket" || {
                renkli_yaz "❌ $paket kurulamadı." "$KIRMIZI" "$SIFIRLA"
                log_yaz "Hata: $paket kurulamadı."
                exit 1
            }
        fi
    done
    apt upgrade -y &>/dev/null
    renkli_yaz "✅ Bağımlılıklar hazır." "$YESIL" "$SIFIRLA"
    log_yaz "Bağımlılıklar kontrol edildi ve güncellendi."
}

url_al() {
    KOK_URL="${TEMEL_URL}/${GORUNTU_ADI}"
    SHA_URL="${TEMEL_URL}/${SHA_ADI}"
}

url_kontrol() {
    local url="$1"
    if curl --head --silent --fail "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

kok_dosya_sistemini_indir() {
    if [ -f "$GORUNTU_ADI" ] && ! soru_sor "Mevcut dosya bulundu. Yeniden indirilsin mi?" "H"; then
        GORUNTU_SAKLA=1
        return
    fi
    renkli_yaz "📥 Kök dosya sistemi indiriliyor..." "$MAVI" "$SIFIRLA"
    url_al
    
    if ! url_kontrol "$KOK_URL"; then
        renkli_yaz "❌ URL erişilemez: $KOK_URL" "$KIRMIZI" "$SIFIRLA"
        log_yaz "Hata: URL erişilemez - $KOK_URL"
        exit 1
    fi

    renkli_yaz "🔄 Axel ile indiriliyor..." "$ACIK_MAVI" "$SIFIRLA"
    if axel -n 4 "$KOK_URL" 2>/dev/null; then
        renkli_yaz "✅ İndirme tamamlandı (axel)." "$YESIL" "$SIFIRLA"
    else
        renkli_yaz "⚠️ Axel başarısız, wget ile deneniyor..." "$SARI" "$SIFIRLA"
        if wget "$KOK_URL" -O "$GORUNTU_ADI" 2>/dev/null; then
            renkli_yaz "✅ İndirme tamamlandı (wget)." "$YESIL" "$SIFIRLA"
        else
            renkli_yaz "❌ İndirme başarısız oldu. İnternet bağlantınızı kontrol edin." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Kök dosya sistemi indirilemedi - $KOK_URL"
            exit 1
        fi
    fi
    log_yaz "Kök dosya sistemi indirildi: $GORUNTU_ADI"
}

sha_url_kontrol() {
    curl --head --silent --fail "$SHA_URL" >/dev/null 2>&1
}

sha_dogrula() {
    if [ -z "$GORUNTU_SAKLA" ] && [ -f "$SHA_ADI" ]; then
        renkli_yaz "🔍 Bütünlük kontrol ediliyor..." "$MAVI" "$SIFIRLA"
        sha512sum -c "$SHA_ADI" || {
            renkli_yaz "❌ Dosya bozuk." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Kök dosya sistemi bozuk."
            exit 1
        }
        renkli_yaz "✅ Bütünlük doğrulandı." "$YESIL" "$SIFIRLA"
    fi
}

sha_al() {
    if [ -z "$GORUNTU_SAKLA" ]; then
        renkli_yaz "📥 SHA dosyası alınıyor..." "$MAVI" "$SIFIRLA"
        url_al
        [ -f "$SHA_ADI" ] && rm -f "$SHA_ADI"
        if sha_url_kontrol; then
            axel -n 4 "$SHA_URL" 2>/dev/null || wget "$SHA_URL" -O "$SHA_ADI" 2>/dev/null || {
                renkli_yaz "⚠️ SHA dosyası indirilemedi, doğrulama atlanıyor." "$SARI" "$SIFIRLA"
                log_yaz "Uyarı: SHA dosyası indirilemedi."
                return
            }
            sha_dogrula
            log_yaz "SHA dosyası indirildi ve doğrulandı."
        else
            renkli_yaz "⚠️ SHA dosyası bulunamadı." "$SARI" "$SIFIRLA"
            log_yaz "Uyarı: SHA dosyası mevcut değil."
        fi
    fi
}

kok_dosya_sistemini_cikar() {
    if [ -z "$CHROOT_SAKLA" ]; then
        renkli_yaz "📤 Kök dosya sistemi çıkarılıyor..." "$MAVI" "$SIFIRLA"
        proot --link2symlink tar -xf "$GORUNTU_ADI" 2>/dev/null || {
            renkli_yaz "❌ Çıkarma başarısız." "$KIRMIZI" "$SIFIRLA"
            log_yaz "Hata: Kök dosya sistemi çıkarılamadı."
            exit 1
        }
        renkli_yaz "✅ Çıkarma tamamlandı." "$YESIL" "$SIFIRLA"
        log_yaz "Kök dosya sistemi çıkarıldı."
    fi
}

baslatici_olustur() {
    NH_BASlATICI=${PREFIX}/bin/nethunter
    NH_KISAYOL=${PREFIX}/bin/nh
    cat > "$NH_BASlATICI" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
cd \${HOME}
unset LD_PRELOAD
[ ! -f $CHROOT/root/.version ] && touch $CHROOT/root/.version

kullanici="$KULLANICI_ADI"
ev="/home/\$kullanici"
baslat="sudo -u kali /bin/bash"

if grep -q "kali" ${CHROOT}/etc/passwd; then
    KALI_KULLANICI="1"
else
    KALI_KULLANICI="0"
fi
if [[ \$KALI_KULLANICI == "0" || ("\$#" != "0" && ("\$1" == "-r" || "\$1" == "-R")) ]]; then
    kullanici="root"
    ev="/\$kullanici"
    baslat="/bin/bash --login"
    [ "\$#" != "0" ] && [[ "\$1" == "-r" || "\$1" == "-R" ]] && shift
fi

komut="proot \\
        --link2symlink \\
        -0 \\
        -r $CHROOT \\
        -b /dev \\
        -b /proc \\
        -b /sdcard \\
        -b $CHROOT\$ev:/dev/shm \\
        -w \$ev \\
           /usr/bin/env -i \\
           HOME=\$ev \\
           PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \\
           TERM=\$TERM \\
           LANG=C.UTF-8 \\
           \$baslat"

komut_gir="\$@"
[ "\$#" == "0" ] && exec \$komut || \$komut -c "\$komut_gir"
EOF

    chmod 700 "$NH_BASlATICI"
    [ -L "$NH_KISAYOL" ] && rm -f "$NH_KISAYOL"
    [ ! -f "$NH_KISAYOL" ] && ln -s "$NH_BASlATICI" "$NH_KISAYOL" >/dev/null
    log_yaz "NetHunter başlatıcısı oluşturuldu."
}

kex_kontrol() {
    if [ "$goruntu" = "nano" ] || [ "$goruntu" = "minimal" ]; then
        renkli_yaz "🖥️ KeX paketleri kuruluyor..." "$MAVI" "$SIFIRLA"
        nh sudo apt update && nh sudo apt install -y tightvncserver kali-desktop-xfce || log_yaz "Uyarı: KeX paketleri kurulamadı."
    fi
}

kex_baslatici_olustur() {
    KEX_BASlATICI=${CHROOT}/usr/bin/kex
    cat > "$KEX_BASlATICI" <<- EOF
#!/bin/bash

function kex_baslat() {
    [ ! -f ~/.vnc/passwd ] && kex_sifre
    KULLANICI=\$(whoami)
    [ \$KULLANICI == "root" ] && EKRAN=":2" || EKRAN=":1"
    export MOZ_FAKE_NO_SANDBOX=1 HOME=\${HOME} USER=\${KULLANICI}
    LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libgcc_s.so.1 nohup vncserver \$EKRAN >/dev/null 2>&1 </dev/null
    kex_basliyor=1
}

function kex_durdur() {
    vncserver -kill :1 | sed s/"Xtigervnc"/"NetHunter KeX"/
    vncserver -kill :2 | sed s/"Xtigervnc"/"NetHunter KeX"/
}

function kex_sifre() {
    vncpasswd
}

function kex_durum() {
    oturumlar=\$(vncserver -list | sed s/"TigerVNC"/"NetHunter KeX"/)
    if [[ \$oturumlar == *"590"* ]]; then
        printf "\n\${oturumlar}\n\nKeX istemcisini kullanarak bağlanabilirsiniz.\n"
    elif [ ! -z \$kex_basliyor ]; then
        printf '\nKeX sunucusu başlatılamadı.\n"nethunter kex kill" ile deneyin veya Termux\'u yeniden başlatın.\n'
    fi
}

function kex_oldur() {
    pkill Xtigervnc
}

case \$1 in
    start) kex_baslat ;;
    stop) kex_durdur ;;
    status) kex_durum ;;
    passwd) kex_sifre ;;
    kill) kex_oldur ;;
    *) kex_durdur; kex_baslat; kex_durum ;;
esac
EOF

    chmod 700 "$KEX_BASlATICI"
    log_yaz "KeX başlatıcısı oluşturuldu."
}

bash_profil_duzelt() {
    [ -f "$CHROOT/root/.bash_profile" ] && sed -i '/if/,/fi/d' "$CHROOT/root/.bash_profile"
    log_yaz "Bash profili düzeltildi."
}

resolv_conf_duzelt() {
    echo -e "nameserver 9.9.9.9\nnameserver 149.112.112.112" > "$CHROOT/etc/resolv.conf"
    log_yaz "DNS ayarları yapılandırıldı."
}

sudo_duzelt() {
    chmod +s "$CHROOT/usr/bin/sudo" "$CHROOT/usr/bin/su"
    echo "kali    ALL=(ALL:ALL) ALL" > "$CHROOT/etc/sudoers.d/kali"
    echo "Set disable_coredump false" > "$CHROOT/etc/sudo.conf"
    log_yaz "Sudo ayarları yapılandırıldı."
}

uid_duzelt() {
    KULLANICI_ID=$(id -u)
    GRUP_ID=$(id -g)
    nh -r usermod -u "$KULLANICI_ID" kali 2>/dev/null
    nh -r groupmod -g "$GRUP_ID" kali 2>/dev/null
    log_yaz "Kullanıcı ID düzeltildi."
}

kurulum_baslat() {
    cd "$HOME" || {
        renkli_yaz "❌ Ev dizinine erişilemedi." "$KIRMIZI" "$SIFIRLA"
        log_yaz "Hata: Ev dizinine erişilemedi."
        exit 1
    }
    mimari_belirle
    bilgileri_ayarla
    dosya_sistemini_hazirla
    bagimliliklari_kontrol_et
    kok_dosya_sistemini_indir
    sha_al
    kok_dosya_sistemini_cikar
    baslatici_olustur
    temizlik_yap

    renkli_yaz "🛠️ Yapılandırma başlatılıyor..." "$MAVI" "$SIFIRLA"
    bash_profil_duzelt
    resolv_conf_duzelt
    sudo_duzelt
    kex_kontrol
    kex_baslatici_olustur
    uid_duzelt

    renkli_yaz "🎉 Kurulum Tamamlandı - $(date '+%Y-%m-%d %H:%M:%S')" "$YESIL" "$SIFIRLA"
    renkli_yaz "📌 Kullanım Komutları:" "$YESIL" "$SIFIRLA"
    renkli_yaz "  nethunter            # Komut satırı" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "  nethunter kex passwd # KeX şifresi" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "  nethunter kex &      # Grafik arayüz" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "  nethunter kex stop   # Grafik arayüzü durdur" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "  nethunter -r         # Root modu" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "  nh                   # Kısayol" "$ACIK_MAVI" "$SIFIRLA"
    renkli_yaz "📜 Log dosyası: $LOG_DOSYASI" "$SARI" "$SIFIRLA"
    log_yaz "Kurulum başarıyla tamamlandı."
}

baslangic_menu