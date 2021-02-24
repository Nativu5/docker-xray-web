sudo setcap 'cap_net_bind_service=+ep' /usr/bin/socat

~/.acme.sh/acme.sh --issue --standalone -d yourdomain.com -keylength ec-256 --force

~/.acme.sh/acme.sh --install-cert -d yourdomain.com --ecc \
            --fullchain-file /path/to/cert/xray.crt \
            --key-file /path/to/cert/xray.key

chmod +r /path/to/cert/xray.key