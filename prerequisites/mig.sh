sudo tee /usr/local/bin/setup_mig.sh >/dev/null <<'EOF'
#!/bin/bash
# MIG Setup Script

# 1) Disable MIG
nvidia-smi -mig 0 -i 0

# 2) Enable MIG
nvidia-smi -mig 1 -i 0

# 3) Destroy any old GPU/Compute Instances
nvidia-smi mig -dci -i 0
nvidia-smi mig -dgi -i 0

# 4) Create desired MIG GPU Instances
nvidia-smi mig -cgi 9,15,19,19 -i 0 -C
EOF

sudo chmod +x /usr/local/bin/setup_mig.sh

sudo tee /etc/systemd/system/mig-setup.service >/dev/null <<'EOF'
[Unit]
Description=Configure MIG on system startup

# This ensures we only start after the nvidia driver modules are loaded.
# And also after multi-user.target to avoid race conditions with other GPU-using services
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup_mig.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mig-setup.service
