Ansible Tasks

General
- Update and upgrade the repository
	sudo apt update && sudo apt upgrade -y

- Expose Port (Master & Worker)
- Turn off swap
    sudo nano /etc/fstab
    comment out the swap.img line

- Install containerd, kubeadm, kubectl, kubelet
    sudo apt install -y containerd

    # Create default config
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml

    # Enable and start the service
    sudo systemctl restart containerd
    sudo systemctl enable containerd

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    - Setup IP forwarding
        sudo sysctl --system
        ```bash
        sudo systemctl enable --now kubelet
        sudo swapoff -a
        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
        net.ipv4.ip_forward = 1
        EOF
        sudo sysctl --system

- Cluster Configuration Setup for Master & Worker
- Install Calico CNI
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

Master
- Expose Ports to Kubernetes Worker Nodes
    # Expose the ports to Worker 1 & Worker 2
    # Allow inbound traffic on Kubernetes Control Plane ports
    sudo ufw allow from {ip_worker_1} to any port 6443 proto tcp
    sudo ufw allow from {ip_worker_1} to any port 10250 proto tcp
    sudo ufw allow from {ip_worker_2} to any port 6443 proto tcp
    sudo ufw allow from {ip_worker_2} to any port 10250 proto tcp

    # Optionally allow etcd communication (if needed)
    sudo ufw allow from {ip_worker_1} to any port 2379:2380 proto tcp
    sudo ufw allow from {ip_worker_2} to any port 2379:2380 proto tcp

    # Allow traffic for NodePort Services (for worker node communication with the cluster)
    sudo ufw allow 30000:32767/tcp
    sudo ufw allow 30000:32767/tcp

- Cluster Configuration Setup For Master
    nano kubeadm-config.yaml

    # kubeadm-config.yaml
    kind: ClusterConfiguration
    apiVersion: kubeadm.k8s.io/v1beta4
    kubernetesVersion: v1.21.0 # change version as needed
    ---
    kind: KubeletConfiguration
    apiVersion: kubelet.config.k8s.io/v1beta1
    cgroupDriver: systemd

    sudo kubeadm init --config kubeadm-config.yaml


Worker
- Expose Ports to the Kubernetes Master Nodes
    # Kubernetes API server
    sudo ufw allow from {ip_master_1} to any port 6443 proto tcp

    # Kubelet API (control plane talks to worker's Kubelet)
    sudo ufw allow from {ip_master_1} to any port 10250 proto tcp

    # etcd client API (optional, if control plane hosts etcd)
    sudo ufw allow from {ip_master_1} to any port 2379:2380 proto tcp

    # NodePort range (allow service traffic from workers)
    sudo ufw allow from {ip_master_1} to any port 30000:32767 proto tcp
    sudo ufw allow OpenSSH

- Cluster Configuration Setup For Worker
    # kubeadm-config-worker.yaml
    kind: KubeletConfiguration
    apiVersion: kubelet.config.k8s.io/v1beta1
    cgroupDriver: systemd

    sudo mkdir -p /var/lib/kubelet
    sudo containerd config dump | grep -i cgroup # if cgroup is false, modify it to true
    sudo cp kubeadm-config-worker.yaml /var/lib/kubelet/config.yaml
    sudo /etc/containerd/config.toml
    # [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    #  SystemdCgroup = true
    sudo systemctl daemon-reexec
    sudo systemctl restart containerd
    sudo systemctl restart kubelet