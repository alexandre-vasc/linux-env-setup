# Flush existing rules
iptables -F
iptables -X
iptables -Z

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

### Base Rules ###
# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Block outgoing SSH, except git repos
iptables -A OUTPUT -p tcp --dport 22 -d 140.82.112.4 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -d 20.201.28.151 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j REJECT

# Allow only specific DNS server (x.x.x.x)
#iptables -A OUTPUT -p udp --dport 53 ! -d x.x.x.x -j REJECT
#iptables -A OUTPUT -p tcp --dport 53 ! -d x.x.x.x -j REJECT

### Transmission (Torrent) Rules ###
# Allow incoming connections on Transmission's port
iptables -A INPUT -p tcp --dport 51413 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p udp --dport 51413 -m conntrack --ctstate NEW -j ACCEPT

# Allow DHT/PEX (UDP traffic)
iptables -A INPUT -p udp --sport 1024:65535 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow UPnP/NAT-PMP (if enabled in Transmission)
iptables -A INPUT -p udp --sport 1900 -j ACCEPT
iptables -A INPUT -p udp --sport 5351 -j ACCEPT

### Steam In-Home Streaming (Local Network Only) ###
# Allow Steam discovery & streaming traffic (UDP)
iptables -A INPUT -p udp --dport 27031:27036 -s 192.168.0.0/16 -j ACCEPT

# Allow Steam control & streaming (TCP)
iptables -A INPUT -p tcp --dport 27036:27037 -s 192.168.0.0/16 -j ACCEPT

### Save Rules (Debian-based Systems) ###
iptables-save > /etc/iptables/rules.v4
