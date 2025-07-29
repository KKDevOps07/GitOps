#!/bin/bash
set -euo pipefail

MASTER_PRIVATE_IP="${MASTER_PRIVATE_IP:-192.168.1.5}"
POD_CIDR="10.10.0.0/16"
JOIN_CMD_FILE="/tmp/kubeadm_join_cmd.sh"
CALICO_VERSION="v3.28.0"

echo "[Step 1] Disable swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
swapon --show

echo "[Step 2] Load kernel modules"
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "[Step 3] Configure sysctl"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward   = 1
EOF
sudo sysctl --system

echo "[Step 4] Install Docker & Containerd"
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo mkdir -p /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service

echo "[Step 5] Install Kubernetes components"
sudo apt-get install -y curl ca-certificates apt-transport-https
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

PRIVATE_IP=$(hostname -I | awk '{print $1}')

if [ "$PRIVATE_IP" == "$MASTER_PRIVATE_IP" ]; then
    echo "[Step 6] Initializing Kubernetes Master"
    sudo kubeadm init --apiserver-advertise-address=$MASTER_PRIVATE_IP --pod-network-cidr=$POD_CIDR

    echo "[Step 7] Configure kubectl for the current user"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "[Step 8] Install Calico CNI"
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml
    curl -O https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/custom-resources.yaml
    sed -i "s|cidr: 192\\.168\\.0\\.0/16|cidr: $POD_CIDR|g" custom-resources.yaml
    kubectl create -f custom-resources.yaml

    echo "[Step 9] Generate join command"
    kubeadm token create --print-join-command > $JOIN_CMD_FILE
    chmod +r $JOIN_CMD_FILE

    echo "[Step 10] Join command saved at $JOIN_CMD_FILE"
else
    echo "[Step 6] Waiting for master to be ready..."
    while ! ping -c 1 $MASTER_PRIVATE_IP &>/dev/null; do sleep 5; done
    echo "Master is reachable. Waiting for join command..."

    while ! ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/your-key.pem ubuntu@$MASTER_PRIVATE_IP "test -f $JOIN_CMD_FILE"; do
        sleep 5
    done

    echo "[Step 7] Fetching join command"
    scp -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/your-key.pem ubuntu@$MASTER_PRIVATE_IP:$JOIN_CMD_FILE /tmp/kubeadm_join_cmd.sh

    echo "[Step 8] Joining the cluster"
    sudo bash /tmp/kubeadm_join_cmd.sh
fi

echo "[Step 11] Kubernetes setup complete for $(hostname)"
kubectl get nodes || true
