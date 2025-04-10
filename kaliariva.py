import os
import sys
import subprocess

GREEN = "\033[92m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
RESET = "\033[0m"

logo = None

def configure_logo():
    """Kullanıcıdan özel logo tanımı alır."""
    global logo
    if logo is None:
        lines = []
        print(f"{CYAN}Logo girin (bitirmek için 'done'): {RESET}")
        while True:
            line = input(f"{GREEN}>> {RESET}")
            if line.strip().lower() == "done":
                break
            lines.append(line)
        logo = "\n".join(lines)

def display_header():
    """Terminal arayüzünü çizer."""
    os.system("clear")
    print(f"{MAGENTA}{logo}{RESET}")
    print(f"{CYAN}{'=' * 60}{RESET}")

def deploy_kali():
    """Kali Linux ortamını kurar ve başlatır."""
    kali_root = "/data/data/com.termux/files/home/kali-fs"
    if not os.path.isdir(kali_root):
        subprocess.run(["pkg", "install", "proot", "wget", "-y"], check=True)
        os.makedirs(kali_root, exist_ok=True)
        os.system("wget -q https://kali.download/kali-images/kali-2023.3/kali-linux-2023.3-rootfs-arm64.tar.xz -O kali.tar.xz")
        os.system(f"tar -xJf kali.tar.xz -C {kali_root}")
        os.system("rm kali.tar.xz")
    os.system(f"proot -0 -w ~ -r {kali_root} /bin/bash")

def launch():
    """Ana çalıştırma fonksiyonu."""
    configure_logo()
    display_header()
    deploy_kali()

if __name__ == "__main__":
    try:
        launch()
    except KeyboardInterrupt:
        print(f"{GREEN}\n[*] Çıkış yapıldı.{RESET}")
        sys.exit(0)
    except Exception as e:
        print(f"{MAGENTA}[!] Hata: {e}{RESET}")
        sys.exit(1)