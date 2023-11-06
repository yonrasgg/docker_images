#!/bin/bash

# Variables de entorno para la configuración de WireGuard
WG_ADDRESS=${WG_ADDRESS:-10.0.0.1/24}
WG_LISTEN_PORT=${WG_LISTEN_PORT:-51820}
WG_PEERS=${WG_PEERS:-''} # Debes definir las claves públicas, claves compartidas y rangos de IPs permitidas para los peers

# Genera las claves pública y privada
umask 077
wg genkey > /etc/wireguard/privatekey
wg pubkey < /etc/wireguard/privatekey > /etc/wireguard/publickey

# Genera el archivo de configuración wg0.conf
cat <<EOL > /etc/wireguard/wg0.conf
[Interface]
Address = $WG_ADDRESS
ListenPort = $WG_LISTEN_PORT
PrivateKey = $(cat /etc/wireguard/privatekey)

EOL

# Genera configuraciones para peers
peer_counter=1
for peer_config in $WG_PEERS; do
  pubkey_var="WG_PEER${peer_counter}_PUBLIC_KEY"
  psk_var="WG_PEER${peer_counter}_PSK"
  allowed_ips_var="WG_PEER${peer_counter}_ALLOWED_IPS"

  eval pubkey=\$$pubkey_var
  eval psk=\$$psk_var
  eval allowed_ips=\$$allowed_ips_var

  cat <<EOL >> /etc/wireguard/wg0.conf
[Peer]
PublicKey = $pubkey
PresharedKey = $psk
AllowedIPs = $allowed_ips
EOL

  ((peer_counter++))
done

# Inicia el contenedor
exec "$@"

