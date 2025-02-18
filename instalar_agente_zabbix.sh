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
            shift
            shift
            ;;
        *)
            echo "Opción desconocida: $1"
            mostrar_ayuda
            ;;
    esac
done

if [[ -z "$ZABBIX_SERVER_IP" ]]; then
    echo "Error: La dirección IP del servidor Zabbix no ha sido especificada."
    mostrar_ayuda
fi

validar_ip "$ZABBIX_SERVER_IP"

echo "Dirección IP del servidor Zabbix proporcionada: $ZABBIX_SERVER_IP"

# Detectar el sistema operativo
if [[ -f /etc/debian_version ]]; then
    OS="Debian"
elif [[ -f /etc/redhat-release ]]; then
    OS="RedHat"
else
    echo "Sistema operativo no compatible."
    exit 1
fi

# Instalar el agente de Zabbix según la distribución
if [[ "$OS" == "Debian" ]]; then
    echo "Actualizando la lista de paquetes..."
    sudo apt update
    echo "Instalando el agente de Zabbix..."
    sudo apt install -y zabbix-agent
elif [[ "$OS" == "RedHat" ]]; then
    echo "Instalando el repositorio de Zabbix..."
    sudo dnf install -y https://repo.zabbix.com/zabbix/6.0/rhel/$(rpm -E %rhel)/x86_64/zabbix-release-6.0-1.el$(rpm -E %rhel).noarch.rpm
    sudo dnf clean all
    echo "Instalando el agente de Zabbix..."
    sudo dnf install -y zabbix-agent
fi

# Configurar el agente de Zabbix
echo "Configurando el agente de Zabbix..."
sudo sed -i "s/^Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agentd.conf

# Iniciar y habilitar el servicio del agente de Zabbix
echo "Iniciando el servicio del agente de Zabbix..."
sudo systemctl start zabbix-agent
echo "Habilitando el servicio del agente de Zabbix para que inicie automáticamente al arrancar el sistema..."
sudo systemctl enable zabbix-agent

# Configurar el firewall
echo "Configurando el firewall para permitir el tráfico del agente de Zabbix..."
if command -v firewall-cmd &>/dev/null; then
    sudo firewall-cmd --permanent --add-port=10050/tcp
    sudo firewall-cmd --reload
    echo "Reglas de firewall aplicadas con firewalld."
elif command -v ufw &>/dev/null; then
    sudo ufw allow 10050/tcp
    echo "Reglas de firewall aplicadas con UFW."\else
    echo "No se detectó un firewall compatible."
fi

# Reiniciar el servicio del agente de Zabbix
echo "Reiniciando el servicio del agente de Zabbix para aplicar los cambios..."
sudo systemctl restart zabbix-agent

echo "=============================="
echo "Proceso completado exitosamente."
echo "Fecha y hora: $(date)"
echo "=============================="

echo "Proceso completado exitosamente."
echo "Fecha y hora: $(date)"
echo "=============================="
