#!/usr/bin/env bash
set -euxo pipefail

# 0. Preflight: run as root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Please run as root or via sudo!"
  exit 1
fi

# 1. Disable swap
echo "[1] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Load kernel modules
echo "[2] Loading kernel modules..."
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# 3. Sysctl params
echo "[3] Applying sysctl settings..."
cat <<EOF >/etc/sysctl.d/99-k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# 4. Install basic prerequisites
echo "[4] Installing prerequisites..."
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  git \
  unzip \
  wget \
  jq

# 5. Install Docker CE + containerd
echo "[5] Installing Docker and containerd..."
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
cat <<EOF >/etc/containerd/config.toml
$(containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/')
EOF
systemctl restart containerd
systemctl enable containerd docker

# 6. Install Kubernetes components
echo "[6] Installing kubelet, kubeadm, kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo "deb [signed-by=/etc/apt/keyrings/k8s.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ ./" \
  > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

# 7. Open firewall ports via UFW
echo "[7] Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
for port in \
  22 \
  80 443 \
  6443 2379:2380 10250 10251 10252 30000:32767 \
  8080 9000; do
  ufw allow $port/tcp
done
ufw --force enable

# 8. Install Java, Maven
echo "[8] Installing Java 17, Maven..."
apt-get install -y openjdk-17-jdk maven

# 9. Install Jenkins
echo "[9] Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins
systemctl enable jenkins

# 10. Install SonarQube
echo "[10] Installing SonarQube..."
cd /opt
wget -q https://binaries.sonarsource.com/CommercialDistribution/sonarqube/sonarqube-10.2.0.72605.zip
unzip -q sonarqube-10.2.0.72605.zip
ln -s sonarqube-10.2.0.72605 sonarqube
useradd --no-create-home --shell /usr/sbin/nologin sonar
chown -R sonar:sonar sonarqube-10.2.0.72605

cat <<EOF >/etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

echo "✅ Bootstrap complete!"
