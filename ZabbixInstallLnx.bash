#!/bin/bash

#Variabili
#Trovo la main release del Sistema Opeartivo
os_version=$(rpm -qa \*-release | grep -Ei "oracle|redhat|centos" | cut -d"-" -f3 | cut -c1-1)
ip_server=192.168.1.46

#Installazione automatica di Zabbix Agent per Centos 7
#Creo file di log
LogFile=/var/log/script_zabbix.log

if [ [$os_version==5] -o [$os_version==6] -o [$os_version==7] -o [$os_version==8] ]
then
	#Installo il pacchetto
	yum install https://repo.zabbix.com/zabbix/5.0/rhel/$os_version/x86_64/zabbix-agent-5.0.6-1.el$os_version.x86_64.rpm -y 2>> $LogFile
	
	#Genero il file .psk
	openssl rand -hex 32 | sudo tee /etc/zabbix/zabbix_agentd.psk &>> $LogFile

	#Modifico il file di configurazione Zabbix:
	#Puntamenti al Server Zabbix:
	sed -i -e 's/Server=127.0.0.1/Server='$ip_server'/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	sed -i -e 's/ServerActive=127.0.0.1/ServerActive='$ip_server'/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	sed -i -e 's/Hostname=Zabbix server/# Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	sed -i -e 's/# HostnameItem=system.hostname/HostnameItem=system.hostname/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	sed -i -e 's/# HostMetadataItem=/HostMetadataItem=system.uname/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	sed -i -e 's/# Timeout=3/Timeout=10/g' /etc/zabbix/zabbix_agentd.conf 2>> $LogFile
	
	#Abilito e riavvio il servizio Zabbix Agent
	systemctl enable zabbix-agent 2>> $LogFile
	systemctl restart zabbix-agent 2>> $LogFile

	#Attesa 5 secondi per attestazione agent su Server
	sleep 5

	#Aggiungo i parametri TLS:
        echo "" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile
        echo "#TLS Parametri" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile
        echo "TLSConnect=psk" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile
        echo "TLSAccept=psk" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile
        echo "TLSPSKIdentity=PSK-$HOSTNAME" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile
        echo "TLSPSKFile=/etc/zabbix/zabbix_agentd.psk" >>/etc/zabbix/zabbix_agentd.conf 2>> $LogFile

	#Riavvio servizio per aggiunta parametri TLS
	systemctl restart zabbix-agent 2>> $LogFile

	#Mostro lo stato del servizio:
        echo "" 2>> $LogFile
        echo "######STATO SERVIZIO ZABBIX######" 2>> $LogFile
        echo "" 2>> $LogFile
        systemctl status zabbix-agent -l 2>> $LogFile

 	#Mostro il file .PSK e l'identity spiegando dove inserirli:i
        echo "" 2>> $LogFile
        echo "######ISTRUZIONI POST INSTALLAZIONE######" 2>> $LogFile
        echo "" 2>> $LogFile
        echo "- Inserisci i seguenti parametri nella GUI del server zabbix:" 2>> $LogFile
        echo "- Loggati su 'https://$ip_server/zabbix' con il tuo utente" 2>> $LogFile
        echo "- Nei tab a sinistra scegli Configuration -> Hosts" 2>> $LogFile
        echo "- In Name inserisci: '$HOSTNAME' e clicca su Apply" 2>> $LogFile
        echo "- Seleziona l'host visualizzato cliccandolo" 2>> $LogFile
        echo "- Dal tab 'Host' alla voce 'Groups' rimuovere: 'Discovered hosts'" 2>> $LogFile
        echo "- Spostati nel tab Encryption" 2>> $LogFile
        echo "- In 'Connections to host' seleziona: 'PSK'" 2>> $LogFile
        echo "- In 'Connections from host' seleziona SOLO: 'PSK'" 2>> $LogFile
        echo "- In 'PSK identity' inserisci: PSK-$HOSTNAME" 2>> $LogFile
        echo "- In 'PSK' inserisci la stringa sottostante: " 2>> $LogFile
	echo "" 2>> $LogFile
  	cat /etc/zabbix/zabbix_agentd.psk 2>> $LogFile
  	echo "" 2>> $LogFile
        echo "- Cliccare in basso a sinistra su 'Update'" 2>> $LogFile

        #Disinstallazione:
        echo "" 2>> $LogFile
        echo "######ISTRUZIONI DISINSTALLAZIONE######" 2>> $LogFile
        echo "" 2>> $LogFile
        echo "- Per disinstallare Zabbix eseguire: 'yum remove -y zabbix* ; rm -rf /etc/zabbix/'" 2>> $LogFile
        echo "" 2>> $LogFile
        echo "" 2>> $LogFile
else
	echo "######SISTEMA OPERATIVO NON SUPPORTATO DA QUESTA INSTALLAZIONE ######"
fi

