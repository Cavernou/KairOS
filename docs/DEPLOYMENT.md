# KairOS Deployment Guide

## Home Node Deployment (Linux)

### Prerequisites
- Linux server (Ubuntu 20.04+ recommended)
- Tailscale installed and authenticated
- Go 1.24+ (for building from source)

### Installation

1. **Download and Install**
```bash
# Download the compiled binary or build from source
wget https://github.com/kairos-project/kairos/releases/latest/kairos-node-linux-amd64
chmod +x kairos-node-linux-amd64
sudo mv kairos-node-linux-amd64 /usr/local/bin/kairos-node

# Create service directory
sudo mkdir -p /var/lib/kairos
sudo useradd -r -s /bin/false kairos
sudo chown kairos:kairos /var/lib/kairos
```

2. **Configure**
```bash
# Create config file
sudo mkdir -p /etc/kairos
sudo cp config.example.yaml /etc/kairos/config.yaml

# Edit configuration
sudo nano /etc/kairos/config.yaml
```

3. **Install as Systemd Service**
```bash
# Create service file
sudo tee /etc/systemd/system/kairos-node.service > /dev/null <<EOF
[Unit]
Description=KairOS Home Node
After=network.target

[Service]
Type=simple
User=kairos
Group=kairos
ExecStart=/usr/local/bin/kairos-node -config /etc/kairos/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable kairos-node
sudo systemctl start kairos-node
sudo systemctl status kairos-node
```

### Tailscale Setup
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and join tailnet
sudo tailscale up --advertise-routes=192.168.1.0/24 --accept-routes=false

# Enable subnet routing (if needed)
sudo tailscale set --advertise-routes=192.168.1.0/24 --accept-routes=false
```

## iOS App Deployment

### Development Build
```bash
cd ios/KairOS
xcodebuild -project KairOS.xcodeproj -scheme KairOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Production Build
1. Open `ios/KairOS/KairOS.xcodeproj` in Xcode
2. Set team and bundle identifier
3. Configure provisioning profiles
4. Archive and distribute via App Store or Enterprise

### ALICE Model Setup
```bash
# Place ALICE_2.0 folder in project root
# Run distillation script (if provided)
python3 ALICE_2.0/distillation_script.py

# Convert to Core ML
coremltools convert --model-type transformer --input ALICE_Lite_model --output ALICELite.mlmodel
```

## Network Configuration

### Firewall Rules
```bash
# Allow gRPC traffic (default port 8080)
sudo ufw allow 8080/tcp

# Allow Tailscale
sudo ufw allow 41641/udp
```

### DNS Configuration
Ensure devices can resolve the Home Node via Tailscale magic DNS:
- `home-node.kairos.ts.net` should resolve to the node's Tailscale IP

## Testing the Installation

1. **Node Health Check**
```bash
curl http://localhost:8081/mock/v1/status
```

2. **Device Activation**
- Install iOS app on device
- Enter K-number and passcode
- Use admin code from node logs to activate

3. **Message Test**
- Send test message between devices
- Verify queue persistence when offline

## Monitoring

### Logs
```bash
# Systemd logs
sudo journalctl -u kairos-node -f

# Application logs
sudo tail -f /var/log/kairos/node.log
```

### Metrics
Monitor via the mock HTTP endpoint:
```bash
curl http://localhost:8081/mock/v1/health
```

## Backup and Recovery

### Node Data Backup
```bash
# Stop service
sudo systemctl stop kairos-node

# Backup database
sudo cp /var/lib/kairos/node.db /backup/kairos-$(date +%Y%m%d).db

# Restart service
sudo systemctl start kairos-node
```

### Blackbox Recovery
iOS app users can restore from `.kairbox` files via the Files app.

## Troubleshooting

### Common Issues

1. **Node not reachable**
   - Check Tailscale status: `sudo tailscale status`
   - Verify firewall rules
   - Check service logs

2. **Device activation fails**
   - Verify admin code in node logs
   - Check network connectivity
   - Ensure K-number format is correct (K-XXXX-XXXX)

3. **Messages not delivering**
   - Check queue status in node logs
   - Verify recipient device is online
   - Check trust scores

### Performance Tuning

1. **Database Optimization**
```sql
-- Add indexes for better performance
CREATE INDEX idx_message_queue_receiver ON message_queue(receiver_kair);
CREATE INDEX idx_message_queue_retry ON message_queue(next_retry);
```

2. **Memory Management**
- Monitor node memory usage
- Adjust queue TTL if needed
- Consider Redis for high-throughput scenarios

## Security Considerations

1. **Network Security**
   - Use Tailscale's ACLs to restrict access
   - Enable node-to-node encryption
   - Regular security updates

2. **Data Protection**
   - Encrypt Blackbox files with strong passcodes
   - Regular key rotation
   - Secure backup storage

3. **Access Control**
   - Implement device revocation
   - Monitor trust scores
   - Audit logs regularly
