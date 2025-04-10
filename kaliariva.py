#!/usr/bin/env python3
import os
import sys
import subprocess
import time

# ANSI Renk Kodları
GREEN = "\033[92m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
YELLOW = "\033[93m"
RESET = "\033[0m"

# Logo (Sonradan kendi logonuzu ekleyin)
LOGO = "KaliCore - Professional Termux Tool"

def render_interface():
    os.system("clear")
    print(f"{MAGENTA}{LOGO}{RESET}")
    print(f"{CYAN}{'=' * 60}{RESET}")
    print(f"{YELLOW}[ KaliCore v1.0 - Termux Kali Environment ]{RESET}")

def setup_kali():
    kali_path = "/data/data/com.termux/files/home/kali-fs"
    if not os.path.isdir(kali_path):
        render_interface()
        print(f"{GREEN}[*] Kali Linux kurulumu başlatılıyor...{RESET}")
        subprocess.run(["pkg", "update", "-y"], check=True)
        subprocess.run(["pkg", "install", "proot", "wget", "tar", "-y"], check=True)
        os.makedirs(kali_path, exist_ok=True)
        os.system("wget -q https://kali.download/kali-images/kali-2023.3/kali-linux-2023.3-rootfs-arm64.tar.xz -O kali.tar.xz")
        print(f"{GREEN}[*] Rootfs ayıklanıyor...{RESET}")
        os.system(f"tar -xJf kali.tar.xz -C {kali_path}")
        os.system("rm kali.tar.xz")
        print(f"{GREEN}[+] Kali Linux hazır.{RESET}")
        time.sleep(1)
    else:
        render_interface()
        print(f"{GREEN}[+] Kali ortamı tespit edildi.{RESET}")
        time.sleep(1)

def start_kali():
    kali_path = "/data/data/com.termux/files/home/kali-fs"
    render_interface()
    print(f"{CYAN}[*] Kali shell başlatılıyor...{RESET}")
    os.system(f"proot -0 -w ~ -r {kali_path} /bin/bash")

def run():
    setup_kali()
    start_kali()

if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        print(f"{YELLOW}\n[*] Çıkış yapıldı.{RESET}")
        sys.exit(0)
    except subprocess.CalledProcessError as e:
        print(f"{MAGENTA}[!] Kurulum başarısız: {e}{RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"{MAGENTA}[!] Hata: {e}{RESET}")
        sys.exit(1)