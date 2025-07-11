# sudo yum update && sudo apt upgrade -y
sudo yum install git curl -y

# remove podman and its dependencies
sudo systemctl stop podman.socket podman.service
sudo yum remove -y podman podman-docker buildah skopeo
sudo rm -rf /etc/containers/
sudo rm -rf ~/.config/containers/
sudo rm -rf ~/.local/share/containers/

# install docker
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo systemctl status docker

sudo usermod -aG docker $USER

sudo git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized/ # in /opt/mailcow-dockerized$

sudo bash generate_config.sh

# Mail server hostname (FQDN) - test.smtp.persistmail.site
# Timezone - UTC
# Do you want to disable ClamAV now? [Y/n] Y
# branch master

sudo docker compose pull
sudo docker compose up -d

