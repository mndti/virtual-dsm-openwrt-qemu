#!/bin/sh
# virtual-dsm installer script by @mndti(thiagoinfo)
set -e

# trap ctrl+c and error
trap abort_exit ERR
trap ctrl_c SIGINT

ctrl_c(){
   log " (You pressed ctrl+c)" "(Voce pressionou ctrl+c)" && abort_exit
}

function abort_exit() {
    display_error_and_exit "Aborted" "Interrompido"
}

SCRIPT_LANG=en
PAT_DL="https://global.synologydownload.com/download/DSM/"
PAT_VERSION="release/7.0.1/42218/DSM_VirtualDSM_42218.pat"
PAT_OLD="release/6.2.4/25556/DSM_VirtualDSM_25556.pat"
PAT_NAME="vdsm_temp.pat"
VDSM_NAME="virtual-dsm"
VDSM_DIR="/mnt/$VDSM_NAME"
VDSM_TMP_DIR="$VDSM_DIR/tmp"
VDSM_DISK_PREF="syno"
VDSM_DISK_EXT=".img"
VDSM_BOOT_FILE="${VDSM_DISK_PREF}boot"
VDSM_SYSTEM_FILE="${VDSM_DISK_PREF}system"
VDSM_SYSTEM_SIZE=12G #minimum is 12gb
VDSM_DISK_SIZE=6G
VDSM_DISK1_FILE="${VDSM_DISK_PREF}disk1"
VDSM_DISK2_FILE="${VDSM_DISK_PREF}disk2"
VDSM_DISK3_FILE="${VDSM_DISK_PREF}disk3"
VDSM_DISK4_FILE="${VDSM_DISK_PREF}disk4"
VDSM_BRIDGE="br-lan"
VDSM_CPU=2
VDSM_RAM=2048
VDSM_CFG_TMP="vdsm_temp.cfg"
VDSM_CFG="config.cfg"
VDSM_INIT_TMP="vdsm_temp.sh"
VDSM_PORT_SOCKET="12346"
VDSM_H_API_PORT="2211"
VDSM_H_MAC="00:00:00:00:00:00"
VDSM_H_MODEL="Virtualhost"
VDSM_H_HOSTSN="0000000000000"
VDSM_H_GUESTSN="0000000000000"
RED_INS="\e[0;31m[!]\e[0m"

# Function to display log messages
log() {
    text=$1
    [[ "$SCRIPT_LANG" == "pt" ]] && text=$2
    [[ -z "$2" ]] && text=$1
    echo -e "$text"
}

# Function to display error and exit
function display_error_and_exit() {
    log "Error: $1 / Exiting." "Erro: $2 / Encerrando." && delete_error	
    exit 1
}

update_vars(){
    VDSM_NAME=$vdsm_name
    VDSM_DIR="/mnt/$VDSM_NAME"
    VDSM_TMP_DIR="$VDSM_DIR/tmp"
}

down_pat(){
    wget "$PAT_DL$PAT_VERSION" -O "$VDSM_TMP_DIR/$PAT_NAME" --no-check-certificate
}

down_cfg(){
    wget "https://raw.githubusercontent.com/mndti/virtual-dsm-openwrt-qemu/main/vdsm_temp.cfg" -O "$VDSM_TMP_DIR/$VDSM_CFG_TMP" --no-check-certificate
}

down_init_d(){
    wget "https://raw.githubusercontent.com/mndti/virtual-dsm-openwrt-qemu/main/vdsm_temp.sh" -O "$VDSM_TMP_DIR/$VDSM_INIT_TMP" --no-check-certificate
}

down_host_bin(){
    log "Download host.bin to $VDSM_DIR..." "Baixando host.bin para $VDSM_DIR..."
    wget "https://github.com/mndti/virtual-dsm-openwrt-qemu/raw/main/host.bin" -O "$VDSM_DIR/host.bin" --no-check-certificate
    chmod +x $VDSM_DIR/host.bin
}

boot_system_img(){
    log "$RED_INS Enter the path to virtual dsm" "$RED_INS Insira o caminho para o virtual dsm"
    read -p "default/padrao [$VDSM_DIR]: " vdsm_dir
    [[ ! -z "$vdsm_dir" ]] && VDSM_DIR=$vdsm_dir && VDSM_TMP_DIR=$vdsm_dir/tmp

    log "Creating folders..." "Criando pastas..."
    mkdir -p "$VDSM_TMP_DIR"
    
    ### wget .pat from synology site
    log "Downloading $PAT_VERSION, please wait..." "Baixando $PAT_VERSION, aguarde..." && down_pat
    	
    [ ! -s "$VDSM_TMP_DIR/$PAT_NAME" ] && display_error_and_exit "The PAT file not found" "O arquivo PAT nao foi encontrado"

    log "Preparing $VDSM_BOOT_FILE$VDSM_DISK_EXT file..." "Preparando o arquivo $VDSM_BOOT_FILE$VDSM_DISK_EXT..."
    tar xpf "$VDSM_TMP_DIR/$PAT_NAME" -C "$VDSM_TMP_DIR/."
    VDSM_BOOT=$(find "$VDSM_TMP_DIR" -name "*.bin.zip")
    [ ! -s "$VDSM_BOOT" ] && display_error_and_exit "The PAT file contains no boot image." "O arquivo PAT nao contem a imagem de boot"

    install_pkg "unzip" "opkg install unzip..."

    VDSM_BOOT=$(echo "$VDSM_BOOT" | head -c -5)
    log "Extract $VDSM_BOOT_FILE..." "Extraindo $VDSM_BOOT_FILE..."
    unzip -q -o "$VDSM_BOOT".zip -d "$VDSM_TMP_DIR"
    log "Move $VDSM_BOOT_FILE to permanent directory..." "Movendo $VDSM_BOOT_FILE para a pasta permanente..."
    VDSM_BOOT=$(find "$VDSM_TMP_DIR" -name "*.bin")
    #qemu-img convert -f raw -O qcow2 $VDSM_BOOT $VDSM_DIR/$VDSM_BOOT_FILE$VDSM_DISK_EXT
    mv $VDSM_BOOT $VDSM_DIR/$VDSM_BOOT_FILE$VDSM_DISK_EXT
    
    log "Download $VDSM_CFG_TMP..." "Baixando $VDSM_CFG_TMP..." && down_cfg
    [ ! -s "$VDSM_TMP_DIR/$VDSM_CFG_TMP" ] && display_error_and_exit "The $VDSM_CFG_TMP file not found" "O arquivo $VDSM_CFG_TMP nao foi encontrado"
    log "Save port $VDSM_PORT_SOCKET to cfg..." "Salvando porta $VDSM_PORT_SOCKET para cfg..."
    sed -i "s/port = .*/port = \"$VDSM_PORT_SOCKET\"/" $VDSM_TMP_DIR/$VDSM_CFG_TMP
    log "Save $VDSM_BOOT_FILE$VDSM_DISK_EXT to cfg..." "Salvando $VDSM_BOOT_FILE$VDSM_DISK_EXT para cfg..."
    disk_cfg "$VDSM_BOOT_FILE" "$VDSM_DIR" "0xa"

    ### create system disk
    install_pkg "qemu-img" "opkg install qemu-img..."
    log "Create $VDSM_SYSTEM_FILE$VDSM_DISK_EXT with size of ${VDSM_SYSTEM_SIZE}B..." "Criando $VDSM_SYSTEM_FILE$VDSM_DISK_EXT com o tamanho de ${VDSM_SYSTEM_SIZE}B..."
    qemu-img create -f raw $VDSM_DIR/$VDSM_SYSTEM_FILE$VDSM_DISK_EXT $VDSM_SYSTEM_SIZE
    [ ! -s "$VDSM_DIR/$VDSM_SYSTEM_FILE$VDSM_DISK_EXT" ] && display_error_and_exit "The $VDSM_SYSTEM_FILE$VDSM_DISK_EXT file not found" "O arquivo $VDSM_SYSTEM_FILE$VDSM_DISK_EXT nao foi encontrado"
    log "Save $VDSM_SYSTEM_FILE$VDSM_DISK_EXT to cfg..." "Salvando $VDSM_SYSTEM_FILE$VDSM_DISK_EXT para cfg..."
    disk_cfg "$VDSM_SYSTEM_FILE" "$VDSM_DIR" "0xb"
}

disk_cfg(){
    disk_name=$1
    disk_file=$2
    disk_addr=$3
    DISK_CFG="[device \"hw-$disk_name\"]
  driver = \"virtio-scsi-pci\"
  addr = \"$disk_addr\"
[drive \"$disk_name\"]
  file = \"$disk_file/$disk_name$VDSM_DISK_EXT\"
  format = \"raw\"
  if = \"none\"
  cache = \"none\"
[device \"$disk_name\"]
  driver = \"scsi-hd\"
  bus = \"hw-$disk_name.0\"
  drive = \"$disk_name\""

    echo "$DISK_CFG" >> $VDSM_TMP_DIR/$VDSM_CFG_TMP
}

net_cfg(){
    dev_net=$1
    net_dev=$2
    net_mac=$3
    bridge=$4
    NET_CFG="[device \"$dev_net\"]
  driver = \"virtio-net-pci\"
  netdev = \"$net_dev\"
  mac = \"$net_mac\"
[netdev \"$net_dev\"]
  type = \"bridge\"
  br = \"$bridge\""

    echo "$NET_CFG" >> $VDSM_TMP_DIR/$VDSM_CFG_TMP
}

create_net(){
    net_dev=$1
    dev_net=$2
    lan_name=$3
    net_mac=00:60:2f$(hexdump -n3 -e '/1 ":%02x"' /dev/random)
    log "$RED_INS Enter name of the bridge interface $net_dev" "$RED_INS Insira o nome da ponte para a interface $net_dev"
    read -p "default/padrao [$VDSM_BRIDGE]: " vdsm_bridge
    [[ -z "$vdsm_bridge" ]] && vdsm_bridge=$VDSM_BRIDGE
    bridge_check=$(ip addr | grep $vdsm_bridge)
    [[ -z "$bridge_check" ]] && display_error_and_exit "Bridge $vdsm_bridge not found" "Ponte $vdsm_bridge nao encontrada"
    log "Save $net_dev to cfg..." "Salvando $net_dev para cfg..."
    net_cfg "$net_dev" "$dev_net" "$net_mac" "$vdsm_bridge"
}

create_nets(){
    ### net0 - required
    create_net "net0" "br0" "lan1"
    ### net1 - optional
    log "$RED_INS Do you want add another lan?" "$RED_INS Voce quer adicionar outra lan?"
    read -p "default/padrao [n] (y/n): " choice_net1
    if [[ "$choice_net1" == "y" || "$choice_net1" == "Y" ]]; then
        create_net "net1" "br1"
    fi
}

create_disk(){

    disk_name=$1
    disk_addr=$2
    disk_file=$disk_name$VDSM_DISK_EXT

    log "$RED_INS Enter the path to $disk_name" "$RED_INS Insira o caminho para o $disk_name"
    read -p "default/padrao [$VDSM_DIR]: " vdsm_disk_path
    [[ -z "$vdsm_disk_path" ]] && vdsm_disk_path=$VDSM_DIR

    log "$RED_INS Enter $disk_name size" "$RED_INS Insira o tamanho do $disk_name"
    read -p "default/padrao [$VDSM_DISK_SIZE]: " vdsm_disk_size
    [[ -z "$vdsm_disk_size" ]] && vdsm_disk_size=$VDSM_DISK_SIZE

    log "Create $disk_name with $vdsm_disk_size..." "Criando $disk_name com $vdsm_disk_size..."
    mkdir -p "$vdsm_disk_path"
    drive_file=$vdsm_disk_path/$disk_file
    qemu-img create -f raw $drive_file $vdsm_disk_size
    [ ! -s "$drive_file" ] && display_error_and_exit "The $disk_file file not found" "O arquivo $disk_file nao foi encontrado"

    log "Save $disk_file to cfg..." "Salvando $disk_file para cfg..."
    disk_cfg "$disk_name" "$vdsm_disk_path" "$disk_addr"
}

create_disks(){
    ### disk1 - required
    create_disk "$VDSM_DISK1_FILE" "0xc"
    ### disk2 - optional
    log "$RED_INS Do you want add $VDSM_DISK2_FILE?" "$RED_INS Voce quer adicionar $VDSM_DISK2_FILE?"
    read -p "default/padrao [n] (y/n): " choice_disk2
    if [[ "$choice_disk2" == "y" || "$choice_disk2" == "Y" ]]; then
        create_disk "$VDSM_DISK2_FILE" "0xd"
        ### disk3 - optional
        log "$RED_INS Do you want add $VDSM_DISK3_FILE?" "$RED_INS Voce quer adicionar $VDSM_DISK3_FILE?"
        read -p "default/padrao [n] (y/n): " choice_disk3
        if [[ "$choice_disk3" == "y" || "$choice_disk3" == "Y" ]]; then
            create_disk "$VDSM_DISK3_FILE" "0xe"
            ### disk4 - optional
            log "$RED_INS Do you want add $VDSM_DISK4_FILE?" "$RED_INS Voce quer adicionar $VDSM_DISK4_FILE?"
            read -p "default/padrao [n] (y/n): " choice_disk4
            if [[ "$choice_disk4" == "y" || "$choice_disk4" == "Y" ]]; then
                create_disk "$VDSM_DISK4_FILE" "0xf"
            fi
        fi
    fi
}

cpu_ram_cfg(){
    cores=$1
    memory=$2
    CFG="[memory]
  size = \"$memory\"
[smp-opts]
  cores = \"$cores\""

    log "Save cores/memory to cfg..." "Salvando nucleos/memoria to cfg..."
    echo "$CFG" >> $VDSM_TMP_DIR/$VDSM_CFG_TMP
}

create_configs(){

    log "$RED_INS Enter the number of processor cores, only numbers (example: 1/2/4)" "$RED_INS Insira a quantidade de núcleos do processador, somente numeros (exemplo: 1/2/4)"
    read -p "default/padrao [$VDSM_CPU]: " vdsm_cpu
    [[ -z "$vdsm_cpu" ]] && vdsm_cpu=$VDSM_CPU

    log "$RED_INS Enter the amount of ram memory, only numbers (example: 1048/2048/4096)" "$RED_INS Insira a quantidade de memoria RAM, somente numeros (exemplo: 1048/2048/4096)"
    read -p "default/padrao [$VDSM_RAM]: " vdsm_ram
    [[ -z "$vdsm_ram" ]] && vdsm_ram=$VDSM_RAM
    cpu_ram_cfg "$vdsm_cpu" "$vdsm_ram"

    ## remove ^M endline file cfg
    sed -i "s/\r//g" $VDSM_TMP_DIR/$VDSM_CFG_TMP
    log "Copy $VDSM_INIT_TMP to $VDSM_DIR..." "Copiando $VDSM_INIT_TMP para $VDSM_DIR..."
    cp $VDSM_TMP_DIR/$VDSM_CFG_TMP $VDSM_DIR/$VDSM_CFG

    log "Download $VDSM_INIT_TMP..." "Baixando $VDSM_INIT_TMP..."
    down_init_d
    [ ! -s "$VDSM_TMP_DIR/$VDSM_INIT_TMP" ] && display_error_and_exit "The $VDSM_INIT_TMP file not found" "O arquivo $VDSM_INIT_TMP nao foi encontrado"

    init_d_update "$vdsm_cpu"
    log "Copy $VDSM_INIT_TMP script to init.d folder..." "Copiando o script $VDSM_INIT_TMP para a pasta init.d..."
    cp $VDSM_TMP_DIR/$VDSM_INIT_TMP /etc/init.d/$VDSM_NAME
    chmod +x /etc/init.d/$VDSM_NAME
}

init_d_mac_serial(){
    log "$RED_INS Do you want to define the mac/model/serial?" "$RED_INS Voce quer definir o mac/modelo/serial?"
    read -p "default/padrao [n] (y/n): " choice_mac_serial
    if [[ "$choice_mac_serial" == "y" || "$choice_mac_serial" == "Y" ]]; then
        log "$RED_INS Enter the MAC host" "$RED_INS Insira o MAC do host"
        read -p "default/padrao [$VDSM_H_MAC]: " vdsm_h_mac
        [[ ! -z "$vdsm_h_mac" ]] && VDSM_H_MAC=$vdsm_h_mac
        log "$RED_INS Enter the model host" "$RED_INS Insira o modelo do host"
        read -p "default/padrao [$VDSM_H_MODEL]: " vdsm_h_model
        [[ ! -z "$vdsm_h_model" ]] && VDSM_H_MODEL=$vdsm_h_model
        log "$RED_INS Enter the serial host" "$RED_INS Insira o serial do host"
        read -p "default/padrao [$VDSM_H_HOSTSN]: " vdsm_h_hostsn
        [[ ! -z "$vdsm_h_hostsn" ]] && VDSM_H_HOSTSN=$vdsm_h_hostsn
        log "$RED_INS Enter the serial guest" "$RED_INS Insira o serial do convidado"
        read -p "default/padrao [$VDSM_H_GUESTSN]: " vdsm_h_guestsn
        [[ ! -z "$vdsm_h_guestsn" ]] && VDSM_H_GUESTSN=$vdsm_h_guestsn
    fi
}

init_d_update(){

    VDSM_CPU=$1
    VDSM_DIR_E=$(echo "${VDSM_DIR//\//\\/}")

    init_h_mac=s/VDSM_H_MAC=.*/VDSM_H_MAC=\"$VDSM_H_MAC\"/
    init_h_model=s/VDSM_H_MODEL=.*/VDSM_H_MODEL=\"$VDSM_H_MODEL\"/
    init_h_hostsn=s/VDSM_H_HOSTSN=.*/VDSM_H_HOSTSN=\"$VDSM_H_HOSTSN\"/
    init_h_guestsn=s/VDSM_H_GUESTSN=.*/VDSM_H_GUESTSN=\"$VDSM_H_GUESTSN\"/
    init_name=s/VDSM_NAME=.*/VDSM_NAME=\"$VDSM_NAME\"/
    init_dir=s/VDSM_DIR=.*/VDSM_DIR=\"$VDSM_DIR_E\"/
    init_cpu=s/VDSM_H_CPU=.*/VDSM_H_CPU=$VDSM_CPU/
    init_api_port=s/VDSM_H_API_PORT=.*/VDSM_H_API_PORT=$VDSM_H_API_PORT/
    init_socket_port=s/VDSM_PORT_SOCKET=.*/VDSM_PORT_SOCKET=$VDSM_PORT_SOCKET/
    VDSM_H_CPU_ARCH=$(cat /proc/cpuinfo | grep 'model name' | cut -f 2 -d ":" | awk '{$1=$1}1' | sed 's# @.*##g' | sed s/"(R)"//g | sed 's/[^[:alnum:] ]\+/ /g' | sed 's/  */ /g' | head -1)
    init_cpu_model=s/VDSM_H_CPU_ARCH=.*/VDSM_H_CPU_ARCH=\"$VDSM_H_CPU_ARCH,,\"/

    log "Update $VDSM_INIT_TMP script..." "Atualizando $VDSM_INIT_TMP script..."
    
    sed -i \
      -e "$init_h_mac" \
      -e "$init_h_model" \
      -e "$init_h_hostsn" \
      -e "$init_h_guestsn" \
      -e "$init_name" \
      -e "$init_dir" \
      -e "$init_cpu" \
      -e "$init_api_port" \
      -e "$init_socket_port" \
      -e "$init_cpu_model" \
      $VDSM_TMP_DIR/$VDSM_INIT_TMP

}

install_pkg(){
    log "$2"
    opkg install $1
}

install_required_pkg(){

    install_pkg "curl" "opkg install curl ..."  
    install_pkg "kmod-tun qemu-bridge-helper qemu-x86_64-softmmu" "opkg install kmod-tun qemu-bridge-helper qemu-x86_64-softmmu ..."

    is_cpu=$(cat /proc/cpuinfo | grep vendor_id | sed -e "s/^.*: //" | head -1)
    ### intel
    if [ "$is_cpu" == "GenuineIntel" ]; then install_pkg "kmod-kvm-intel intel-microcode iucode-tool" "opkg install kmod-kvm-intel intel-microcode iucode-tool ..."; fi
    ### amd
    if [ "$is_cpu" == "AuthenticAMD" ]; then install_pkg "kmod-kvm-amd amd64-microcode" "opkg install kmod-kvm-amd amd64-microcode ..."; fi

}



delete_temp(){
    log "Delete temp folder and files..." "Excluindo pasta e arquivos temporarios..."
    rm -r $VDSM_TMP_DIR/* && rmdir $VDSM_TMP_DIR
}

delete_error(){
    if [ -s "$VDSM_DIR" ]; then
	log "Delete temp folder and files..." "Excluindo pasta e arquivos temporarios..."
	if [[ -s "/etc/init.d/$VDSM_NAME" ]]; then
	    /etc/init.d/$VDSM_NAME stop
	    rm /etc/init.d/$VDSM_NAME
	fi
    	rm -r $VDSM_DIR/* && rmdir $VDSM_DIR
    fi
}

finish(){
    log "/etc/init.d/$VDSM_NAME enable"
    /etc/init.d/$VDSM_NAME enable
    log "/etc/init.d/$VDSM_NAME start"
    log "Start Virtual DSM...please wait..." "Iniciando Virtual DSM...aguarde..."
    /etc/init.d/$VDSM_NAME start
    while true; do ping -c1 virtualdsm &>/dev/null && break; done
    ip_VDSM=$(ping -c1 virtualdsm | sed -nE 's/^PING[^(]+\(([^)]+)\).*/\1/p')
    if [ $vdsm_version == 6 ]; then
	log "You selected version 6, remember to download PAT and install manually!" "Você selecionou a versão 6, lembre-se de baixar o PAT e instalar manualmente!"
	log "PAT: https://global.synologydownload.com/download/DSM/release/6.2.4/25556/DSM_VirtualDSM_25556.pat"
    fi
    log "Access the link below to complete the installation of Virtual DSM..." "Acesse o link abaixo para concluir a instalacao do Virtual DSM"
    log "$RED_INS http://$ip_VDSM:5000"
}

log "$RED_INS Enter script language / Insira o idioma do script"
read -p "default/padrao [en] (en/pt): " script_lang
[[ "$script_lang" == "pt" ]] && SCRIPT_LANG=$script_lang

log "$RED_INS Do you want to continue?" "$RED_INS Voce quer continuar?"
read -p "default/padrao [n] (y/n): " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    ## version
    log "$RED_INS Enter the version to virtual dsm (7/6)" "$RED_INS Insira a versao para o virtual dsm (7/6)"
    read -p "default/padrao [7]: " vdsm_version
    [[ "$vdsm_version" == 6 ]] && PAT_VERSION=$PAT_OLD
    # name
    log "$RED_INS Enter the name to virtual dsm (a-z0-9_-)" "$RED_INS Insira o nome para o virtual dsm (a-z0-9_-)"
    read -p "default/padrao [$VDSM_NAME]: " vdsm_name
    [[ "$vdsm_name" =~ [^a-z0-9_-] ]] && display_error_and_exit "The name $vdsm_name is not allowed $vdsm_name file not found" "O nome $vdsm_name nao e permitido"
    [[ ! -z "$vdsm_name" ]] && update_vars
    # mac/host/serial
    init_d_mac_serial
    #### boot
    boot_system_img
    #### disks
    create_disks
    ### network
    create_nets
    ### configs update
    create_configs
    ### install required packages
    install_required_pkg
    ### download host.bin
    down_host_bin
    ### delete temp
    delete_temp
    ### finish
    finish
else
    log "\e[0;31m[exit]\e[0m Script aborted. No changes were made." "\e[0;31m[encerrado]\e[0m Script abortado. Nenhuma alteracao foi feita."
fi
