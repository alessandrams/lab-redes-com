#!/bin/bash
#Verificacao de super user

if [[ $EUID -ne 0 ]]; then
  dialog	\
	--title "Nao e super usuario/root" \
	--msgbox "Execute o script como super usuario/root" \
	7 40
  [ $? -eq 0 ] && clear >$(tty) && exit 1
fi

# Definindo variaveis

proxima=primeira
while : ; do

  case "$proxima" in
    primeira)
      proxima=escolhavm
      # Iniciando o programa
      dialog --title "Configuração de rede" --msgbox "Bem vindo ao guia de configuração de interfaces de rede." 7 40
      ;;

    escolhavm)
      anterior=primeira
      proxima=escolhaint
      # Tela para escolha da VM para config
      VM=$(dialog --stdout --title "Escolha de VM" --menu "Escolha a VM para ser configurada" 0 0 0 VM-A  'Maquina Virtual A' ROT-A "Roteador A")
      ;;

    escolhaint)
      anterior=escolhavm
      proxima=escolhatipoint
      int_dialog="dialog --stdout --title \"Escolha de interface\" --menu \"Escolha a interface para ser configurada\" 0 0 0"
      int_desc="Interface"
      # Define o array de interfaces de rede disponiveis e apresenta tela para selecionar a desejada
      mapfile -t interface_array < <(basename -a /sys/class/net/*)
      for index in ${!interface_array[@]}; do
        int_dialog="$int_dialog ${interface_array[index]} $int_desc"
      done
      INT=$(eval $int_dialog)
      ;;

    escolhatipoint)
      anterior=escolhaint
      proxima=informeip
      # Define o tipo de interface que sera configurada
      TIPOREDE=$(dialog --stdout --title "Escolha o tipo da rede"  --menu "Escolha o tipo da rede desta interface" \
                 0 0 0\
                 Interna 'Rede interna'\
                 NAT 'NAT')
    ;;

    informeip)
      anterior=escolhatipoint
      # Tela para receber IP e mascara da VM
      if [ "$VM" == "VM-A" ] || [ "$VM" == "ROT-A" -a "$TIPOREDE" == "NAT" ]; then
        proxima=informegw
        CIDR=$(dialog --stdout --inputbox 'Digite o número IP e Mascara (modelo CIDR).\nEx:192.168.0.1/24 ' 0 0 )
      else
        CIDR=$(dialog --stdout --inputbox 'Digite o número IP e Mascara (modelo CIDR).\nEx:192.168.0.1/24 ' 0 0 )
        [ $? -eq 0 ] && break && clear >$(tty)
      fi
      ;;

    informegw)
      anterior=informeip
      GW=$(dialog --stdout --inputbox 'Digite o número IP do Gateway padrao: ' 0 0 )
      [ $? -eq 0 ] && break && clear >$(tty)
      ;;

    *)
      echo "Janela inexistente '$proxima'."
      echo "Fechando o programa..."
      exit
  esac

retorno=$?
[ $retorno -eq 1 ] && proxima=$anterior  #cancelar
[ $retorno -eq 255 ] && clear >$(tty) && exit 1  #esc
done


if [ "$VM" == "VM-A" ];
  then
    # VM da rede interna necessita de IP, GW (IP rede interna ROT-A)
    echo "Iniciando config da $VM..."
    ifconfig $INT $CIDR
    route add default gw $GW
elif [ "$VM" == "ROT-A" ];
  then
    # Verifica o tipo de rede informada. Se for NAT precisa de IP, GW, ip_forward, iptables e servidor dns
    if [ "$TIPOREDE" == "NAT" ];
      then
        echo "Iniciando config da $VM..."
        ifconfig $INT $CIDR
        sudo -s <<EOF
        echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
        route add default gw $GW
        iptables -t nat -A POSTROUTING -o $INT -j SNAT --to $CIDR
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
    # Se for interna, so precisa de IP
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
