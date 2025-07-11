sudo apt update && sudo apt upgrade -y
sudo apt install git curl -y

curl -sSL https://get.docker.com/ | CHANNEL=stable sh
sudo systemctl enable --now docker
sudo apt install docker-compose-plugin

cd /etc/docker #  in /etc/docker$
sudo apt install vim
# vim daemon.json
# Add the following content to daemon.json: (skip)
# {
#   "selinux-enabled": true
# }

sudo systemctl daemon-reload
sudo systemctl restart docker

cd ../.. # in /
cd /opt # in /opt$

sudo git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized/ # in /opt/mailcow-dockerized$

sudo bash generate_config.sh

# Mail server hostname (FQDN) - test.smtp.persistmail.site
# Timezone - UTC
# Do you want to disable ClamAV now? [Y/n] Y
# branch master

sudo docker compose pull
sudo docker compose up -d

