#!/usr/bin/env python3
"""
PDANet Transparent Proxy
Replaces redsocks. Accepts TCP connections redirected by iptables,
forwards them via PDANet HTTP CONNECT proxy.
"""
import socket, struct, select, os, sys

PROXY_HOST = "192.168.49.1"
PROXY_PORT = 8000
LISTEN_PORT = 12345
BUF_SIZE = 65536

def handle_client(client, addr):
    try:
        dst = client.getsockopt(socket.SOL_IP, 80, 16)
        dst_port = struct.unpack('!H', dst[2:4])[0]
        dst_ip = socket.inet_ntoa(dst[4:8])
    except OSError:
        client.close()
        return

    relay = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    relay.settimeout(15)
    try:
        relay.connect((PROXY_HOST, PROXY_PORT))
    except Exception:
        client.close()
        return

    relay.sendall(f"CONNECT {dst_ip}:{dst_port} HTTP/1.0\r\n\r\n".encode())
    try:
        resp = relay.recv(4096)
    except socket.timeout:
        client.close(); relay.close(); return

    if b"200" not in resp:
        client.close(); relay.close(); return

    client.setblocking(0)
    relay.setblocking(0)
    done = False
    while not done:
        rlist, _, _ = select.select([client, relay], [], [], 1)
        for sock in rlist:
            try:
                data = sock.recv(BUF_SIZE)
                if not data:
                    done = True
                    break
                if sock is client:
                    relay.sendall(data)
                else:
                    client.sendall(data)
            except (ConnectionError, OSError):
                done = True
                break
    client.close()
    relay.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', LISTEN_PORT))
    server.listen(128)
    print(f"PDANet transparent proxy on {LISTEN_PORT}", flush=True)
    while True:
        client, addr = server.accept()
        pid = os.fork()
        if pid == 0:
            server.close()
            handle_client(client, addr)
            os._exit(0)
        else:
            client.close()

if __name__ == "__main__":
    main()
