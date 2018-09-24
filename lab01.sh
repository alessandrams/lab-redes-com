#!/bin/bash

# Definindo variaveis
int_dialog="dialog --stdout --title \"Escolha de interface\" --menu \"Escolha a interface para ser configurada\" 0 0 0"
int_desc="Interface"

# Iniciando o programa
dialog --title "Configuração de rede" --msgbox "Bem vindo ao guia de configuração de interfaces de rede" 0 0

# Tela para escolha da VM para config
VM=$(dialog --stdout --title "Escolha de VM" --menu "Escolha a VM para ser configurada" 0 0 0 VM-A  'Maquina Virtual A' ROT-A "Roteador A")

# Define o array de interfaces de rede disponiveis e apresenta tela para selecionar a desejada
mapfile -t interface_array < <(basename -a /sys/class/net/*)
for index in ${!interface_array[@]}; do
  int_dialog="$int_dialog ${interface_array[index]} $int_desc"
done
INT=$(eval $int_dialog)

# Tela para receber IP e mascara da VM
CIDR=$(dialog --stdout --inputbox 'Digite o número IP e Mascara (modelo CIDR): ' 0 0 )


if [ "$VM" == "VM-A" ];
  then
    clear >$(tty)
    echo "Iniciando config da $VM..."
    sudo ifconfig $INT $CIDR
elif [ "$VM" == "ROT-A" ];
  then
    GW=$(dialog --stdout --inputbox 'Digite o número IP do Gatway padrao: ' 0 0 )
    clear >$(tty)
    echo "Iniciando config da $VM..."
    ifconfig $INT $CIDR
    echo 1 > /proc/sys/net/ipv4/ip_forward
    route add default gw $GW
    iptables -t nat -A POSTROUTING -o $INT -j SNAT --to $GW
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
fi

ifconfig -a
route -n
