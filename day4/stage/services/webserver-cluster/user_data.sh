#! /bin/bash
sudo dnf install -y httpd

cat > /var/www/html/index.html <<EOF
<h1>Hello, World</h1>
<p>B address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

sudo systemctl start httpd

