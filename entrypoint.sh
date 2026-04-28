set -eu

# ==============================================================================
# VPN CONNECTION ISSUE & WORKAROUND SUMMARY
# ------------------------------------------------------------------------------
# ISSUE: 
#   xl2tpd-control would stall during connection, and /etc/ppp/resolv.conf 
#   was never created.
#
# CAUSE: 
#   "Tunnel ID Mismatch" (Zombie Sessions). When the container was previously 
#   stopped without a graceful disconnect, the VPN server (LNS) kept the old 
#   Tunnel ID active. Upon restart, the server sent packets using the old ID, 
#   which the new xl2tpd instance rejected (Log: "Can not find tunnel"). 
#   This prevented the PPP layer from starting.
#
# SOLUTION: 
#   Automate a graceful shutdown using a 'trap'. This ensures that the server 
#   is explicitly notified to release the Tunnel ID and IPsec SA before the 
#   container exits, allowing for a clean state on the next connection attempt.
# ==============================================================================
cleanup() {
  # Disable traps to prevent recursive calls during the shutdown sequence.
  trap - EXIT INT TERM

  echo "Disconnecting VPN..."
  # 1. CRITICAL: Send a Call-Disconnect-Notify (CDN) to the LNS (Server).
  # This releases the Tunnel/Call IDs on the server side immediately, 
  # preventing the "Can not find tunnel" mismatch error on the next boot.
  xl2tpd-control disconnect-lac vpn || true
  sleep 1

  echo "Stopping xl2tpd..."
  # 2. Stop the xl2tpd service gracefully.
  service xl2tpd stop || true

  echo "Disconnecting ipsec..."
  # 3. Terminate the IKE/IPsec session.
  # Sends a DELETE payload to the server to clear Security Associations (SA).
  ipsec down vpn || true
  sleep 1

  echo "Stopping ipsec..."
  # 4. Shut down the IPsec service.
  # Must be stopped AFTER xl2tpd to ensure the encrypted path remains 
  # available for the L2TP disconnect notification.
  service ipsec stop || true

  echo "Cleanup complete, exiting"
  exit 0
}

# Trap termination signals to trigger the cleanup subroutine.
trap cleanup EXIT INT TERM

# --- Start services ---
rsyslogd -n &
sh /app/ipsec.sh
sh /app/l2tp.sh

# --- Start proxy in background ---
# Running in the background allows the shell to remain responsive to signals.
sh /app/proxy.sh &
PROXY_PID=$!

echo "VPN services started. Monitoring proxy process (PID: $PROXY_PID)..."

# --- Wait Loop ---
# 'wait' is a special command that allows the shell to catch signals (SIGTERM)
# immediately. Without this, the shell ignores the trap until the child process exits.
while kill -0 $PROXY_PID 2>/dev/null; do
  # The '& wait $!' pattern is a robust way to keep the shell interruptible.
  sleep 1 & wait $!
done
