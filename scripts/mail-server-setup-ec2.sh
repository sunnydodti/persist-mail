sudo yum install docker -y
sudo usermod -a -G docker ec2-user
DMS_GITHUB_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master"
wget "${DMS_GITHUB_URL}/compose.yaml"
wget "${DMS_GITHUB_URL}/mailserver.env"

sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.36.2/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
sudo docker compose version

sudo systemctl start docker
sudo docker compose up -d

# docker exec -ti mailserver setup email add info@webshanks.shop

# if port 80 is already in use
sudo systemctl stop httpd

# ssl - get ssl certs using certbot
docker run --rm -it \
-v "${PWD}/docker-data/certbot/certs/:/etc/letsencrypt/" \
-v "${PWD}/docker-data/certbot/logs/:/var/log/letsencrypt/" \
-p 80:80 \
certbot/certbot certonly --standalone -d mail.persist.site

# ssl - renew ssl certs using certbot
docker run --rm -it \
-v "${PWD}/docker-data/certbot/certs/:/etc/letsencrypt/" \
-v "${PWD}/docker-data/certbot/logs/:/var/log/letsencrypt/" \
-p 80:80 \
-p 443:443 \
certbot/certbot renew