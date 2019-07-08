#!/bin/bash

zenity --info --title="Boas-vindas" --text="Esse script realiza o envio de Pings com mensagens criptografadas" --width=500 
if [ $? != 0 ] ; then
    exit
  fi 

zenity --question --text "Você deseja realizar acesso remoto para envio do Ping?" --width=500
if [ $? = 0 ] ; then
  remoteIP=$(zenity --forms --title="Acesso Remoto" --text="Digite o IP para acesso:" --add-entry="Ip" --width=500)
  if [ $? = 1 ] ; then
    exit
  fi 
   user=$(zenity --forms --title="Acesso Remoto" --text="Digite o usuario:" --add-entry="Usuario" --width=500)
  if [ $? = 1 ] ; then
    exit
  fi 
   senha=$(zenity --forms --title="Acesso Remoto" --text="Digite a senha:" --add-password="Senha" --width=500)
  if [ $? = 1 ] ; then
    exit
  fi 
elif [ $? = 1 ] ; then
  break
else
  exit    
fi

message=$(zenity --forms --title="Mensagem" --text="Qual mensagem deseja enviar pelo ping?" --add-entry="Mensagem" --width=500)
if [ $? = 1 ] ; then
    exit
fi    

zenity --question --text "A cifra padrão utiliza shift=13 para criptografar a mensagem. \nDeseja alterar esse valor?" --width=500
if [ $? = 0 ] ; then
  shift=$(zenity --forms --title="Shift" --text="Digite qual valor de shift deseja utilizar:" --add-entry="Shift" "" --width=500)
  if [ $? = 1 ] ; then
    shift=13
  fi 
else
  shift=13  
fi

destinationIP=$(zenity --forms --title="IP Destino" --text="Qual IP de destino do ping?" --add-entry="IP" --width=500)
if [ $? = 1 ] ; then
    exit
fi    


if [ $remoteIP ] ; then
    sshpass -p "$senha" ssh -t "$user@$remoteIP" "sudo python3 ~/script/ICMP-Ping.py --Message 'oi tudo bem' --Shift "$shift" --Host "$destinationIP""
    #chmod 777 ~/script/ICMP-Ping.py
    #sudo python3 ICMP-Ping.py --Message "$message" --Shift "$shift" --Host "$destinationIP"
else
    cd ~/script/
    sudo python3 ICMP-Ping.py --Message "$message" --Shift "$shift" --Host "$destinationIP"
fi    
  
echo $message
echo $remoteIP
echo $shift
echo $destinationIP


# dialog \
#    --title "Nao e super usuario/root" \
#    --msgbox "Execute o script como super usuario/root" \
#    7 40

#cls    