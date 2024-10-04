## Descripción del Script

El script `instalar_agente_zabbix.sh` automatiza la instalación y configuración del agente de Zabbix en servidores Ubuntu, RHEL, Rocky y AlmaLinux con o sin cPanel. Acepta parámetros de línea de comandos para mayor flexibilidad y facilidad de uso, permitiendo a los usuarios especificar la dirección IP del servidor Zabbix y acceder a una ayuda integrada.

#### Comando de Instalación en 1 linea:

```bash
curl -s https://raw.githubusercontent.com/Baraghost/agente_zabbix_linux/refs/heads/main/instalar_agente_zabbix.sh -o /tmp/instalar_zabbix.sh && chmod +x /tmp/instalar_zabbix.sh && sudo /tmp/instalar_zabbix.sh --zabbix_server 192.168.1.100 && rm /tmp/instalar_zabbix.sh
```

**Importante:** Asegúrate de reemplazar la ip por la de tu Server de Zabbix.
