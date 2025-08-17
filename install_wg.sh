#!/bin/bash
set -e

# === Установка ===
sudo apt update && sudo apt install -y wireguard qrencode

# === Генерация ключей ===
mkdir -p ~/wg_keys
cd ~/wg_keys
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

SERVER_PRIV=$(cat server_private.key)
SERVER_PUB=$(cat server_public.key)
CLIENT_PRIV=$(cat client_private.key)
CLIENT_PUB=$(cat client_public.key)

# === Внешний IP Codespaces ===
SERVER_IP=$(curl -s ifconfig.me)
WG_PORT=51820

# === Конфиг сервера ===
sudo mkdir -p /etc/wireguard
cat <<EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $SERVER_PRIV
Address = 10.0.0.1/24
ListenPort = $WG_PORT

[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.2/32
EOF

# === Конфиг клиента ===
cat <<EOF > ~/wg_client.conf
[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0
EOF

# === Запуск WireGuard ===
sudo wg-quick up wg0

echo "========================================"
echo "✅ WireGuard установлен и запущен!"
echo "📂 Конфиг клиента: ~/wg_client.conf"
echo "🌍 Подключение к серверу: $SERVER_IP:$WG_PORT"
echo "========================================"

# === QR-код для телефона ===
echo "📱 Отсканируй этот QR в приложении WireGuard:"
qrencode -t ansiutf8 < ~/wg_client.conf
