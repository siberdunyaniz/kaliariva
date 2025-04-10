#!/usr/bin/env python3
import os
import sys
import subprocess
import threading
import time
from termcolor import colored

NEON_GREEN = 'green'
NEON_CYAN = 'cyan'
NEON_MAGENTA = 'magenta'

logo = None
def get_user_logo():
    global logo
    if not logo:
        logo_lines = []
        while True:
            line = input(colored("> ", NEON_GREEN))
            if line.lower() == "done":
                break
            logo_lines.append(line)
        logo = "\n".join(logo_lines)

def display_interface():
    os.system("clear")
    print(colored(logo, NEON_MAGENTA))
    print(colored("-" * 50, NEON_CYAN))
    print(colored("[ NeonKali Terminal ]", NEON_GREEN))
    print(colored("Komutlar: install, scan, tools, shell, exit", NEON_CYAN))

def setup_kali():
    if not os.path.exists("/data/data/com.termux/files/home/kali-fs"):
        subprocess.run(["wget", "-q", "http://http.kali.org/kali/dists/kali-rolling/main/binary-arm64/Packages.gz"], check=True)
        subprocess.run(["pkg", "install", "proot", "wget", "git", "-y"], check=True)
        os.system("mkdir -p ~/kali-fs ~/kali-binds")
        os.system("wget -q https://kali.download/kali-images/kali-2023.3/kali-linux-2023.3-rootfs-arm64.tar.xz -O kali.tar.xz")
        os.system("tar -xJf kali.tar.xz -C ~/kali-fs")
        os.system("rm kali.tar.xz")

def start_kali_shell():
    display_interface()
    os.system("proot -0 -w ~ -r ~/kali-fs /bin/bash")

def network_scan():
    target = input(colored("[?] Hedef IP: ", NEON_CYAN))
    start_port = int(input(colored("[?] Başlangıç portu: ", NEON_CYAN)))
    end_port = int(input(colored("[?] Bitiş portu: ", NEON_CYAN)))
    open_ports = []

    def scan_port(port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        if sock.connect_ex((target, port)) == 0:
            open_ports.append(port)
        sock.close()

    threads = []
    for port in range(start_port, end_port + 1):
        t = threading.Thread(target=scan_port, args=(port,))
        threads.append(t)
        t.start()
        if len(threads) >= 100:
            for t in threads:
                t.join()
            threads = []

    for t in threads:
        t.join()

    display_interface()
    print(colored(f"[+] Açık Portlar: {sorted(open_ports)}", NEON_GREEN))

def install_tools():
    tools = {
        "nmap": "pkg install nmap",
        "metasploit": "pkg install metasploit-framework",
        "sqlmap": "pkg install sqlmap",
        "aircrack": "pkg install aircrack-ng"
    }
    display_interface()
    print(colored("Kullanılabilir araçlar: nmap, metasploit, sqlmap, aircrack", NEON_CYAN))
    tool = input(colored("[?] Kurmak istediğiniz araç: ", NEON_GREEN)).lower()
    if tool in tools:
        os.system(tools[tool])

def main():
    get_user_logo()
    setup_kali()
    
    while True:
        display_interface()
        cmd = input(colored("neonkali> ", NEON_GREEN)).lower()
        
        if cmd == "install":
            install_tools()
        elif cmd == "scan":
            network_scan()
        elif cmd == "tools":
            os.system("pkg list-installed")
        elif cmd == "shell":
            start_kali_shell()
        elif cmd == "exit":
            sys.exit()
        else:
            os.system(cmd)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit()