#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import hashlib
from threading import Thread

# ANSI Renk Kodları
GREEN = "\033[92m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"

# Sabitler
KALI_PATH = "/data/data/com.termux/files/home/kali-fs"
CONFIG_FILE = "kali_config.txt"
LOG_FILE = "kali_core.log"

# Varsayılan Logo (konfigürasyon dosyasından override edilebilir)
DEFAULT_LOGO = """
KaliCore
Elite Penetration Testing Framework
"""

def log_message(message):
    """İşlemleri log dosyasına kaydeder."""
    with open(LOG_FILE, "a") as log:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        log.write(f"[{timestamp}] {message}\n")

def load_config():
    """Konfigürasyon dosyasından logo ve ayarları yükler."""
    logo = DEFAULT_LOGO
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            logo = f.read().strip()
    else:
        with open(CONFIG_FILE, "w") as f:
            f.write(DEFAULT_LOGO)
    return logo

def render_full_logo(logo):
    """Tam ekran logo gösterimi."""
    os.system("clear")
    terminal_height = int(os.popen("tput lines").read().strip())
    logo_lines = logo.strip().split("\n")
    logo_height = len(logo_lines)
    padding = (terminal_height - logo_height) // 2

    for _ in range(padding):
        print()
    for line in logo_lines:
        print(f"{MAGENTA}{line.center(os.get_terminal_size().columns)}{RESET}")
    for _ in range(padding):
        print()

def spinner(message):
    """İşlem sırasında dönen animasyon."""
    def spin():
        while getattr(spinner, "running", True):
            for char in "|/-\\":
                sys.stdout.write(f"\r{GREEN}[{char}] {message}{RESET}")
                sys.stdout.flush()
                time.sleep(0.1)
        sys.stdout.write(f"\r{GREEN}[+] {message} Tamamlandı.{RESET}\n")
        sys.stdout.flush()

    spinner.running = True
    t = Thread(target=spin)
    t.start()
    return t

def verify_kali_integrity(kali_path):
    """Kali dosya sisteminin bütünlüğünü kontrol eder."""
    if os.path.isdir(kali_path):
        checksum_file = f"{kali_path}/root/checksum"
        if os.path.exists(checksum_file):
            with open(checksum_file, "r") as f:
                stored_hash = f.read().strip()
            current_hash = hashlib.sha256(str(os.listdir(kali_path)).encode()).hexdigest()
            return stored_hash == current_hash
    return False

def setup_kali():
    """Kali Linux ortamını kurar ve doğrular."""
    logo = load_config()
    if not os.path.isdir(KALI_PATH) or not verify_kali_integrity(KALI_PATH):
        render_full_logo(logo)
        print(f"{GREEN}[*] Kali Linux ortamı hazırlanıyor...{RESET}")
        log_message("Kali kurulum süreci başlatıldı.")
        
        spin_thread = spinner("Gerekli paketler yükleniyor")
        subprocess.run(["pkg", "update", "-y"], check=True)
        subprocess.run(["pkg", "install", "proot", "wget", "tar", "-y"], check=True)
        spin_thread.running = False
        spin_thread.join()

        os.makedirs(KALI_PATH, exist_ok=True)
        spin_thread = spinner("Kali rootfs indiriliyor")
        os.system("wget -q https://kali.download/kali-images/kali-2023.3/kali-linux-2023.3-rootfs-arm64.tar.xz -O kali.tar.xz")
        spin_thread.running = False
        spin_thread.join()

        spin_thread = spinner("Rootfs ayıklanıyor")
        os.system(f"tar -xJf kali.tar.xz -C {KALI_PATH}")
        os.system("rm kali.tar.xz")
        spin_thread.running = False
        spin_thread.join()

        # Bütünlük kontrolü için hash kaydet
        current_hash = hashlib.sha256(str(os.listdir(KALI_PATH)).encode()).hexdigest()
        with open(f"{KALI_PATH}/root/checksum", "w") as f:
            f.write(current_hash)
        
        log_message("Kali ortamı başarıyla kuruldu.")
        render_full_logo(logo)
        print(f"{GREEN}[+] Kali Linux hazır.{RESET}")
        time.sleep(1)
    else:
        render_full_logo(logo)
        print(f"{GREEN}[+] Kali ortamı doğrulandı ve hazır.{RESET}")
        log_message("Mevcut Kali ortamı doğrulandı.")
        time.sleep(1)

def launch_kali():
    """Kali Linux shell'ini profesyonel bir prompt ile başlatır."""
    logo = load_config()
    render_full_logo(logo)
    print(f"{CYAN}[*] Kali Linux shell başlatılıyor...{RESET}")
    log_message("Kali shell başlatıldı.")
    time.sleep(1)
    os.system(f"proot -0 -w ~ -r {KALI_PATH} /bin/bash -c 'PS1=\"{GREEN}root@kali-linux:{CYAN}/root{GREEN}\$ {RESET}\" /bin/bash'")

def main():
    """Tool'un ana yürütme fonksiyonu."""
    setup_kali()
    launch_kali()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"{YELLOW}\n[*] Çıkış yapıldı.{RESET}")
        log_message("Kullanıcı tarafından çıkış yapıldı.")
        sys.exit(0)
    except subprocess.CalledProcessError as e:
        print(f"{RED}[!] Kurulum hatası: {e}{RESET}")
        log_message(f"Kurulum hatası: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"{RED}[!] Kritik hata: {e}{RESET}")
        log_message(f"Kritik hata: {e}")
        sys.exit(1)