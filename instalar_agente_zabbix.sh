#!/bin/bash

# Definir la ruta del archivo de log
LOGFILE="/var/log/instalar_zabbix.log"

# Crear el archivo de log si no existe y establecer permisos adecuados
if [ ! -f "$LOGFILE" ]; then
    sudo touch "$LOGFILE"
    sudo chmod 644 "$LOGFILE"
fi

# Redirigir stdout y stderr al archivo de log y a la consola
exec > >(tee -a "$LOGFILE") 2>&1

echo "=============================="
echo "Iniciando la instalación del agente de Zabbix..."
echo "Fecha y hora: $(date)"
echo "=============================="

# Función para mostrar la ayuda
mostrar_ayuda() {
    echo "Uso: $0 --zabbix_server <IP_DEL_SERVIDOR_ZABBIX>"
    echo ""
    echo "Opciones:"
    echo "  -h, --help                Mostrar esta ayuda y salir."
    echo "  --zabbix_server <IP>      Especificar la dirección IP del servidor Zabbix."
    echo ""
    echo "Ejemplos:"
    echo "  $0 --zabbix_server 192.168.1.100"
    echo "  $0 -h"
    exit 0
}

# Función para validar la dirección IP
validar_ip() {
    local ip=$1
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ $ip =~ $regex ]]; then
        # Verificar que cada octeto esté entre 0 y 255
        IFS='.' read -r -a octetos <<< "$ip"
        for octeto in "${octetos[@]}"; do
            if (( octeto < 0 || octeto > 255 )); then
                echo "Error: Dirección IP inválida."
                exit 1
            fi
        done
    else
        echo "Error: Formato de dirección IP no válido."
        exit 1
    fi
}

# Parsing de argumentos
if [[ $# -eq 0 ]]; then
    echo "Error: No se proporcionaron argumentos."
    mostrar_ayuda
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -h|--help)
            mostrar_ayuda
            ;;
        --zabbix_server)
            ZABBIX_SERVER_IP="$2"
            shift # Salta el argumento actual
            shift # Salta el valor del argumento
            ;;
        *)
            echo "Opción desconocida: $1"
            mostrar_ayuda
            ;;
    esac
done

# Verificar que la IP del servidor Zabbix haya sido proporcionada
if [[ -z "$ZABBIX_SERVER_IP" ]]; then
    echo "Error: La dirección IP del servidor Zabbix no ha sido especificada."
    mostrar_ayuda
fi

# Validar la dirección IP proporcionada
validar_ip "$ZABBIX_SERVER_IP"

echo "Dirección IP del servidor Zabbix proporcionada: $ZABBIX_SERVER_IP"

# (Opcional) Detectar el nombre del host del sistema
# HOSTNAME=$(hostname)
# echo "Nombre del host detectado: $HOSTNAME"

# Actualizar la lista de paquetes e instalar el agente de Zabbix
echo "Actualizando la lista de paquetes..."
sudo apt update

echo "Instalando el agente de Zabbix..."
sudo apt install zabbix-agent -y

# Configurar el agente de Zabbix
echo "Configurando el agente de Zabbix..."
sudo sed -i "s/^Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf

# (Opcional) Configurar el nombre del host en Zabbix
# echo "Configurando el nombre del host en Zabbix..."
# sudo sed -i "s/^# Hostname=/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf

# Iniciar y habilitar el servicio del agente de Zabbix
echo "Iniciando el servicio del agente de Zabbix..."
sudo systemctl start zabbix-agent
echo "Habilitando el servicio del agente de Zabbix para que inicie automáticamente al arrancar el sistema..."
sudo systemctl enable zabbix-agent

# Configurar el firewall para permitir el tráfico del agente de Zabbix
echo "Configurando el firewall para permitir el tráfico del agente de Zabbix..."
if command -v csf &>/dev/null; then
    # Si ConfigServer Firewall (lfd) está instalado
    sudo csf -a "$ZABBIX_SERVER_IP"
    echo "El agente de Zabbix ha sido instalado, configurado y se ha añadido una regla al firewall lfd."
elif command -v ufw &>/dev/null; then
    # Si UFW está instalado
    sudo ufw allow from "$ZABBIX_SERVER_IP" to any port 10050
    echo "El agente de Zabbix ha sido instalado, configurado y se ha añadido una regla al firewall UFW."
elif command -v firewalld &>/dev/null; then
    # Si firewalld está instalado
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="'$ZABBIX_SERVER_IP'" port protocol="tcp" port="10050" accept'
    sudo firewall-cmd --reload
    echo "El agente de Zabbix ha sido instalado, configurado y se ha añadido una regla al firewall firewalld."
else
    echo "Detección de firewall fallida. No se encontró un firewall compatible."
fi

# Reiniciar el servicio del agente de Zabbix para aplicar los cambios
echo "Reiniciando el servicio del agente de Zabbix para aplicar los cambios..."
sudo systemctl restart zabbix-agent

echo "=============================="
echo "Proceso completado exitosamente."
echo "Fecha y hora: $(date)"
echo "=============================="
