#!/usr/bin/env python3
import asyncio, logging, os, signal, socket, struct, subprocess, sys

log = logging.getLogger(__name__)

PROXY_HOST = os.environ.get("PDANET_PROXY_HOST")
if not PROXY_HOST:
    print("ERROR: PDANET_PROXY_HOST not set. Run via pdanet-proxy-start", file=sys.stderr)
    sys.exit(1)

PROXY_PORT = int(os.environ.get("PDANET_PROXY_PORT", "8000"))
LISTEN_PORT = int(os.environ.get("PROXY_LISTEN_PORT", "12345"))
PID_FILE = os.environ.get("PDANET_PROXY_PID_FILE", "/tmp/pdanet-proxy.pid")
START_WARMUP = os.environ.get("PDANET_PROXY_START_WARMUP", "1") != "0"
BUF = 65536
CHAIN = "PDANET"
CONN_TMO = 15
_loaded_nf_nat = False


def ipt(*args):
    subprocess.run(
        ["iptables", "-t", "nat", *args],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def module_loaded(name):
    try:
        with open("/proc/modules", "r", encoding="utf-8") as fh:
            return any(line.startswith(f"{name} ") for line in fh)
    except OSError:
        return False


def module_usage_count(name):
    try:
        with open("/proc/modules", "r", encoding="utf-8") as fh:
            for line in fh:
                if line.startswith(f"{name} "):
                    parts = line.split()
                    if len(parts) >= 3:
                        return int(parts[2])
                    return 0
    except (OSError, ValueError):
        pass
    return 0


def load_nf_nat():
    if module_loaded("nf_nat"):
        log.info("nf_nat already loaded")
        return False

    rc = subprocess.run(
        ["modprobe", "nf_nat"],
        check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode
    if rc == 0 and module_loaded("nf_nat"):
        log.info("nf_nat module loaded")
        return True

    log.warning("nf_nat load failed (non-fatal)")
    return False


def unload_nf_nat():
    if not _loaded_nf_nat:
        return

    refs = module_usage_count("nf_nat")
    if refs != 1:
        log.info("nf_nat still in use (%d refs); leaving loaded", refs)
        return

    rc = subprocess.run(
        ["modprobe", "-r", "nf_nat"],
        check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode
    if rc == 0:
        log.info("nf_nat module unloaded")
    else:
        log.warning("nf_nat unload failed")


def iptables_chain_exists():
    return subprocess.run(
        ["iptables", "-t", "nat", "-L", CHAIN, "-n"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0


def iptables_rules_valid():
    try:
        proc = subprocess.run(
            ["iptables", "-t", "nat", "-L", CHAIN, "-n"],
            check=True, capture_output=True, text=True,
        )
    except subprocess.CalledProcessError:
        return False

    lines = proc.stdout.splitlines()
    bypass = any("RETURN" in line and PROXY_HOST in line for line in lines)
    redirect = any("REDIRECT" in line and f"to:{LISTEN_PORT}" in line for line in lines)
    return bypass and redirect


def setup_iptables():
    if iptables_chain_exists() and iptables_rules_valid():
        log.info("iptables %s chain already applied", CHAIN)
        return

    subprocess.run(["iptables", "-t", "nat", "-D", "OUTPUT", "-p", "tcp", "-j", CHAIN],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["iptables", "-t", "nat", "-F", CHAIN],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["iptables", "-t", "nat", "-X", CHAIN],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    ipt("-N", CHAIN)
    for net in (
        "0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8",
        "169.254.0.0/16", "172.16.0.0/12", "192.168.0.0/16",
        "198.18.0.0/15", "224.0.0.0/4", "240.0.0.0/4",
    ):
        ipt("-A", CHAIN, "-d", net, "-j", "RETURN")
    ipt("-A", CHAIN, "-d", PROXY_HOST, "-j", "RETURN")
    ipt("-A", CHAIN, "-p", "tcp", "--dport", "53", "-j", "RETURN")
    ipt("-A", CHAIN, "-p", "tcp", "--dport", "853", "-j", "RETURN")
    ipt("-A", CHAIN, "-p", "tcp", "-j", "REDIRECT", "--to-ports", str(LISTEN_PORT))
    ipt("-I", "OUTPUT", "1", "-p", "tcp", "-j", CHAIN)

    log.info("iptables %s chain applied (%s)", CHAIN, PROXY_HOST)


def remove_iptables():
    for cmd in (
        ("-D", "OUTPUT", "-p", "tcp", "-j", CHAIN),
        ("-F", CHAIN),
        ("-X", CHAIN),
    ):
        subprocess.run(["iptables", "-t", "nat", *cmd],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log.info("iptables %s chain removed", CHAIN)


def write_pid_file():
    try:
        with open(PID_FILE, "w", encoding="utf-8") as fh:
            fh.write(f"{os.getpid()}\n")
    except OSError as e:
        log.warning("failed to write PID file %s: %s", PID_FILE, e)


def remove_pid_file():
    try:
        if os.path.exists(PID_FILE):
            os.unlink(PID_FILE)
    except OSError:
        pass


def get_orig_dst(sock):
    try:
        dst = sock.getsockopt(socket.SOL_IP, 80, 16)
        port = struct.unpack("!H", dst[2:4])[0]
        ip = socket.inet_ntoa(dst[4:8])
        return ip, port
    except OSError:
        return None, None


def resolve_ipv4(host, port):
    for family, socktype, proto, _, sockaddr in socket.getaddrinfo(
        host, port, type=socket.SOCK_STREAM, proto=socket.IPPROTO_TCP
    ):
        if family == socket.AF_INET:
            return sockaddr[0], port
    raise OSError(f"no IPv4 address found for {host}")


def parse_host_from_http(data):
    try:
        text = data.decode("iso-8859-1")
    except UnicodeDecodeError:
        return None

    if "\r\n\r\n" not in text and not text.endswith("\r\n"):
        return None

    lines = text.splitlines()
    if not lines:
        return None
    parts = lines[0].split()
    if len(parts) < 2:
        return None

    host = None
    for line in lines[1:]:
        if not line:
            break
        if line.lower().startswith("host:"):
            host = line.split(":", 1)[1].strip()
            break
    if not host:
        return None

    if host.startswith("[") and "]" in host:
        host = host[1:host.index("]")]
        port = 80
    elif ":" in host:
        host, port_text = host.rsplit(":", 1)
        try:
            port = int(port_text)
        except ValueError:
            return None
    else:
        port = 80

    try:
        return resolve_ipv4(host, port)
    except OSError:
        return None


def parse_sni_from_tls(data):
    if len(data) < 5 or data[0] != 0x16:
        return None

    rec_len = struct.unpack("!H", data[3:5])[0]
    if len(data) < 5 + rec_len or data[5] != 0x01:
        return None

    hs_len = int.from_bytes(data[6:9], "big")
    body = memoryview(data[9:9 + hs_len])
    if len(body) < hs_len:
        return None

    idx = 0
    if len(body) < 34:
        return None
    idx += 2  # version
    idx += 32  # random

    if idx >= len(body):
        return None
    sid_len = body[idx]
    idx += 1 + sid_len
    if idx + 2 > len(body):
        return None
    cs_len = struct.unpack("!H", body[idx:idx + 2])[0]
    idx += 2 + cs_len
    if idx >= len(body):
        return None
    comp_len = body[idx]
    idx += 1 + comp_len
    if idx + 2 > len(body):
        return None

    ext_len = struct.unpack("!H", body[idx:idx + 2])[0]
    idx += 2
    end = idx + ext_len
    if end > len(body):
        return None

    while idx + 4 <= end:
        ext_type = struct.unpack("!H", body[idx:idx + 2])[0]
        ext_size = struct.unpack("!H", body[idx + 2:idx + 4])[0]
        idx += 4
        ext_data = body[idx:idx + ext_size]
        idx += ext_size
        if ext_type != 0 or len(ext_data) < 5:
            continue

        if len(ext_data) < 2:
            return None
        list_len = struct.unpack("!H", ext_data[:2])[0]
        pos = 2
        limit = min(len(ext_data), 2 + list_len)
        while pos + 3 <= limit:
            name_type = ext_data[pos]
            name_len = struct.unpack("!H", ext_data[pos + 1:pos + 3])[0]
            pos += 3
            if pos + name_len > limit:
                return None
            if name_type == 0:
                try:
                    host = bytes(ext_data[pos:pos + name_len]).decode("ascii")
                except UnicodeDecodeError:
                    return None
                try:
                    return resolve_ipv4(host, 443)
                except OSError:
                    return None
            pos += name_len

    return None


def probe_connectivity():
    proc = subprocess.run(
        [
            "env", "-u", "http_proxy", "-u", "https_proxy",
            "-u", "HTTP_PROXY", "-u", "HTTPS_PROXY",
            "curl", "-s", "--noproxy", "*", "-m", "10",
            "https://1.1.1.1/cdn-cgi/trace",
        ],
        check=False, capture_output=True, text=True,
    )
    if proc.returncode != 0:
        return None

    for line in proc.stdout.splitlines():
        if line.startswith("ip="):
            return line.split("=", 1)[1].strip()
    return None


async def read_initial_bytes(c_r, limit=4096):
    try:
        return await asyncio.wait_for(c_r.read(limit), timeout=5)
    except asyncio.TimeoutError:
        return b""


async def read_until_header_end(c_r, initial=b""):
    data = bytearray(initial)
    while b"\r\n\r\n" not in data and len(data) < 65536:
        more = await read_initial_bytes(c_r, 4096)
        if not more:
            break
        data.extend(more)
    return bytes(data)


def parse_explicit_connect(data):
    if b"\r\n\r\n" not in data:
        return None

    header_end = data.index(b"\r\n\r\n") + 4
    headers = data[:header_end]
    buffered = data[header_end:]

    first_line = headers.split(b"\r\n", 1)[0]
    parts = first_line.strip().split(b" ", 2)
    if len(parts) < 3 or parts[0] != b"CONNECT":
        return None

    target = parts[1].decode()
    if ":" in target:
        dst_ip, dst_port = target.rsplit(":", 1)
        dst_port = int(dst_port)
    else:
        dst_ip, dst_port = target, 443

    return dst_ip, dst_port, buffered


async def parse_fallback_destination(c_r, first_chunk):
    dst = parse_host_from_http(first_chunk)
    if dst:
        return dst, first_chunk, "HTTP Host"

    dst = parse_sni_from_tls(first_chunk)
    if dst:
        return dst, first_chunk, "TLS SNI"

    return None, first_chunk, None


async def fwd(src, dst):
    try:
        while True:
            data = await src.read(BUF)
            if not data:
                break
            dst.write(data)
            await dst.drain()
    except (ConnectionError, OSError, asyncio.CancelledError):
        pass


async def fwd_with_prefix(src, dst, prefix=b""):
    if prefix:
        dst.write(prefix)
        await dst.drain()
    await fwd(src, dst)


async def handle(c_r, c_w):
    sock = c_w.get_extra_info("socket")
    dst_ip, dst_port = await asyncio.get_running_loop().run_in_executor(
        None, get_orig_dst, sock
    )

    mode = "transparent"
    buffered = b""
    fallback_name = None
    if not dst_ip or not dst_port:
        log.warning("SO_ORIGINAL_DST failed - using fallback detection")
        first_chunk = await read_initial_bytes(c_r)
        if not first_chunk:
            log.warning("could not determine original destination - closing connection")
            c_w.close()
            return
        if first_chunk.startswith(b"CONNECT "):
            mode = "explicit"
            request = await read_until_header_end(c_r, first_chunk)
            parsed = parse_explicit_connect(request)
            if not parsed:
                c_w.write(b"HTTP/1.0 400 Bad Request\r\n\r\n")
                await c_w.drain()
                c_w.close()
                return
            dst_ip, dst_port, buffered = parsed
        else:
            if first_chunk.startswith((b"GET ", b"POST ", b"HEAD ", b"PUT ", b"DELETE ", b"OPTIONS ", b"PATCH ", b"TRACE ")):
                first_chunk = await read_until_header_end(c_r, first_chunk)
            parsed, buffered, fallback_name = await parse_fallback_destination(c_r, first_chunk)
            if not parsed:
                log.warning("could not determine original destination - closing connection")
                c_w.close()
                return
            dst_ip, dst_port = parsed
            log.info("conn=%s:%s detected via %s", dst_ip, dst_port, fallback_name)
    elif dst_ip == "127.0.0.1" and dst_port == LISTEN_PORT:
        mode = "explicit"
        try:
            line = await asyncio.wait_for(c_r.readline(), timeout=5)
        except asyncio.TimeoutError:
            c_w.close()
            return
        if not line.startswith(b"CONNECT "):
            c_w.write(b"HTTP/1.0 400 Bad Request\r\n\r\n")
            await c_w.drain()
            c_w.close()
            return
        request = await read_until_header_end(c_r, line)
        parsed = parse_explicit_connect(request)
        if not parsed:
            c_w.write(b"HTTP/1.0 400 Bad Request\r\n\r\n")
            await c_w.drain()
            c_w.close()
            return
        dst_ip, dst_port, buffered = parsed

    dst = f"{dst_ip}:{dst_port}"
    log.info("conn=%s %s", dst, mode)

    try:
        r_r, r_w = await asyncio.wait_for(
            asyncio.open_connection(PROXY_HOST, PROXY_PORT), timeout=CONN_TMO,
        )
    except (asyncio.TimeoutError, OSError) as e:
        log.warning("conn=%s connect failed: %s", dst, e)
        if mode == "explicit":
            try:
                c_w.write(b"HTTP/1.0 502 Bad Gateway\r\n\r\n")
                await c_w.drain()
            except (ConnectionError, OSError):
                pass
        c_w.close()
        return

    try:
        req = f"CONNECT {dst_ip}:{dst_port} HTTP/1.0\r\n\r\n"
        r_w.write(req.encode())
        await r_w.drain()

        resp = await asyncio.wait_for(r_r.readline(), timeout=CONN_TMO)
        parts = resp.split(b" ", 2)
        if len(parts) < 2 or parts[1] != b"200":
            log.warning("conn=%s CONNECT rejected: %s", dst,
                        resp.strip().decode(errors="replace"))
            if mode == "explicit":
                c_w.write(b"HTTP/1.0 502 Bad Gateway\r\n\r\n")
                await c_w.drain()
            return

        while True:
            l = await asyncio.wait_for(r_r.readline(), timeout=CONN_TMO)
            if l in (b"\r\n", b"\n", b""):
                break

        if mode == "explicit":
            c_w.write(b"HTTP/1.0 200 Connection established\r\n\r\n")
            await c_w.drain()

        log.info("conn=%s tunnel up", dst)

        t1 = asyncio.create_task(fwd_with_prefix(c_r, r_w, buffered))
        t2 = asyncio.create_task(fwd(r_r, c_w))
        done, pending = await asyncio.wait(
            [t1, t2], return_when=asyncio.FIRST_COMPLETED,
        )
        for t in pending:
            t.cancel()

    finally:
        try:
            r_w.close()
        except (ConnectionError, OSError):
            pass
        c_w.close()
        log.info("conn=%s closed", dst)


async def main():
    if os.geteuid() != 0:
        print("ERROR: root required (run with sudo)", file=sys.stderr)
        sys.exit(1)

    global _loaded_nf_nat
    server = None
    try:
        _loaded_nf_nat = load_nf_nat()
        setup_iptables()

        shutdown = asyncio.Event()

        def on_signal():
            log.info("signal received, shutting down")
            shutdown.set()

        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            try:
                loop.add_signal_handler(sig, on_signal)
            except (NotImplementedError, RuntimeError):
                pass

        server = await asyncio.start_server(handle, "127.0.0.1", LISTEN_PORT)
        log.info("proxy on 127.0.0.1:%d upstream=%s:%s", LISTEN_PORT, PROXY_HOST, PROXY_PORT)
        write_pid_file()

        if START_WARMUP:
            ext_ip = await asyncio.to_thread(probe_connectivity)
            if ext_ip:
                log.info("startup ready (IP %s)", ext_ip)
            else:
                log.warning("startup not ready (external connectivity check failed)")
        else:
            log.info("startup warmup disabled")

        await shutdown.wait()
        log.info("stopping server")
    finally:
        if server is not None:
            server.close()
            try:
                await server.wait_closed()
            except Exception:
                pass
        unload_nf_nat()
        remove_iptables()
        remove_pid_file()
        log.info("shutdown complete")


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] %(levelname)-8s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stdout,
    )
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
