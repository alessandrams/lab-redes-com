#!/bin/bash
#Verificacao de super user
if [[ $EUID -ne 0 ]]; then
  dialog	\
	--title "Nao e super usuario/root" \
	--msgbox "Execute o script como super usuario/root" \
	7 40
  exit 1
fi

# Definindo variaveis
int_dialog="dialog --stdout --title \"Escolha de interface\" --menu \"Escolha a interface para ser configurada\" 0 0 0"
int_desc="Interface"

# Iniciando o programa
dialog --title "Configuração de rede" --msgbox "Bem vindo ao guia de configuração de interfaces de rede." 7 40

# Tela para escolha da VM para config
VM=$(dialog --stdout --title "Escolha de VM" --menu "Escolha a VM para ser configurada" 0 0 0 VM-A  'Maquina Virtual A' ROT-A "Roteador A")

# Define o array de interfaces de rede disponiveis e apresenta tela para selecionar a desejada
mapfile -t interface_array < <(basename -a /sys/class/net/*)
for index in ${!interface_array[@]}; do
  int_dialog="$int_dialog ${interface_array[index]} $int_desc"
done
INT=$(eval $int_dialog)

# Tela para receber IP e mascara da VM
CIDR=$(dialog --stdout --inputbox 'Digite o número IP e Mascara (modelo CIDR).\nEx:192.168.0.1/24 ' 0 0 )


if [ "$VM" == "VM-A" ];
  then
    clear >$(tty)
    echo "Iniciando config da $VM..."
    ifconfig $INT $CIDR
    GW=$(dialog --stdout --inputbox 'Digite o número IP do Gatway padrao: ' 0 0 )
    route add default gw $GW
elif [ "$VM" == "ROT-A" ];
  then
    #Tipo de rede. Se for interna, so precisa de IP. Se for NAT, precisa de GW e fazer Ip_forward
    #E NAT no iptables
    TIPOREDE=$(dialog --stdout --title "Escolha o tipo da rede"  --menu "Escolha o tipo da rede desta interface" \
               0 0 0\
               Interna 'Rede interna'\
               NAT 'NAT')
    if [ "$TIPOREDE" == "NAT" ];
      then
        #GW=$(dialog --stdout --inputbox 'Digite o número IP do Gatway padrao: ' 0 0 )
        clear >$(tty)
        echo "Iniciando config da $VM..."
        ifconfig $INT $CIDR
        sudo -s <<EOF
        echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
        route add default gw $GW
        iptables -t nat -A POSTROUTING -o $INT -j SNAT --to $CIDR
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
    elif [ "$TIPOREDE" == "Interna" ];
      then
        #Redundante pois pode ser necessario ficar deste jeito no proximo lab
        echo "Iniciando config da $VM..."
        ifconfig $INT $CIDR
    fi
fi

echo "\n------------- Configuracoes Finais -----------------\n"
ifconfig -a
route -n
