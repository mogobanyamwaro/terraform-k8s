# Get your IP
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "My IP is: $IP_ADDR"

# Initialize cluster

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=$IP_ADDR \
  --cri-socket=unix:///var/run/containerd/containerd.sock
