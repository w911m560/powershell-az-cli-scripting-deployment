#! /usr/bin/env bash

set -ex

# -- env vars --

export DEBIAN_FRONTEND=noninteractive
HOME=/home/student

# dir where nginx will look for the SSL cert and key
nginx_ssl_dir=/etc/nginx/external

# ssl 
tls_key_path="${nginx_ssl_dir}/key.pem"
tls_cert_path="${nginx_ssl_dir}/cert.pem"

# -- install dependencies --

apt-get update && apt-get install nginx -y

# -- end install dependencies --

# -- generate self signed cert --

# create random generator file
touch /tmp/.rnd

# create certs dir
mkdir "$nginx_ssl_dir"

openssl req -x509 -newkey rsa:4086 \
-subj "/C=US/ST=Missouri/L=St. Louis/O=The LaunchCode Foundation/CN=localhost" \
-keyout "$tls_key_path" \
-out "$tls_cert_path" \
-days 3650 -nodes -sha256 \
-rand /tmp/.rnd

# -- end self signed cert --

# -- configure nginx --

nginx_conf=/etc/nginx/nginx.conf

# save default conf as a backup
mv "$nginx_conf" "${nginx_conf}.bak"

cat << EOF > "$nginx_conf"
events {}
http {
  # proxy settings
  proxy_redirect          off;
  proxy_set_header        Host \$host;
  proxy_set_header        X-Real-IP \$remote_addr;
  proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto \$scheme;
  client_max_body_size    10m;
  client_body_buffer_size 128k;
  proxy_connect_timeout   90;
  proxy_send_timeout      90;
  proxy_read_timeout      90;
  proxy_buffers           32 4k;

  limit_req_zone \$binary_remote_addr zone=one:10m rate=5r/s;
  server_tokens  off;

  sendfile on;
  keepalive_timeout   29; # Adjust to the lowest possible value that makes sense for your use case.
  client_body_timeout 10; client_header_timeout 10; send_timeout 10;

  upstream api{
    server localhost:5000;
  }

  server {
    listen     *:80;
    add_header Strict-Transport-Security max-age=15768000;
    return     301 https://\$host\$request_uri;
  }

  server {
    listen                    *:443 ssl;
    server_name               codeeventsapi.com;
    ssl_certificate           $tls_cert_path;
    ssl_certificate_key       $tls_key_path;
    ssl_protocols             TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers               "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve            secp384r1;
    ssl_session_cache         shared:SSL:10m;
    ssl_session_tickets       off;
    ssl_stapling              on; #ensure your cert is capable
    ssl_stapling_verify       on; #ensure your cert is capable

    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    #Redirects all traffic
    location / {
      proxy_pass http://api;
      limit_req  zone=one burst=10 nodelay;
    }
  }
}
EOF

# reload nginx to use this new conf file
nginx -s reload
