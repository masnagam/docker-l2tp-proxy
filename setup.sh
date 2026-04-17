export DEBIAN_FRONTEND=noninteractive

apt-get update

# IPSec
# kmod is required for using kernel modules
# libstrongswan-standard-plugins is required for 3DES support
apt-get install -y --no-install-recommends \
 ike-scan kmod netbase strongswan libstrongswan-standard-plugins strongswan-starter strongswan-charon

# L2TP
apt-get install -y --no-install-recommends xl2tpd

# HTTP Proxy
apt-get install -y --no-install-recommends privoxy

# for logging
apt-get install -y --no-install-recommends rsyslog

# Specify TZ at runtime.
apt-get install -y --no-install-recommends tzdata

# tools for debugging purposes
apt-get install -y dnsutils iproute2 iputils-ping iputils-tracepath tcpdump

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/tmp/*
rm -rf /tmp/*
