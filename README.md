# Virtual DSM - OpenWrt - qemu-system-x86_64

After many tests, I managed to run virtual dsm in openwrt > qemu.<br>
I would like to leave instructions here in case anyone is interested.

## Install / Instalar
<pre>
  <code>sh <(wget -qO- https://raw.githubusercontent.com/mndti/virtual-dsm-openwrt-qemu/main/vdsm_install.sh)</code>
</pre>

### Requirements / Requisitos
**hardware**
- CPU: x86_64 with KVM
- FREE DISK SPACE: 18GB (boot[110MB], system[12GB], disk1[6GB])
- RAM: 1GB

**opkg**
- curl unzip
- qemu-img kmod-tun qemu-bridge-helper qemu-x86_64-softmmu
- kmod-kvm-intel intel-microcode iucode-tool (intel)
- kmod-kvm-amd amd64-microcode (amd)

### Virtual DSM - OpenWrt - docker
Link: https://github.com/vdsm/virtual-dsm

#### THANKS
All work was based on the Virtual DSM in a Docker container project by user kroese.<br>
Link: https://github.com/vdsm/virtual-dsm

**Disclaimer**
- Commercial use is not permitted and strictly forbidden!!!
- DSM and all Parts are under Copyright / Ownership or Registered Trademark by Synology Inc.
