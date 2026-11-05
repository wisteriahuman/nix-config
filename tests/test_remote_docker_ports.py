"""remote-docker-ports: `docker ps` の Ports 列から転送するポートを選ぶ部分。"""

import subprocess
import unittest
from pathlib import Path


SOURCE = (Path(__file__).resolve().parents[1] / "bin/remote-docker-ports").read_text()


def extract(name):
    body = SOURCE.split(f"\n{name}() {{", 1)[1].split("\n}\n", 1)[0]
    return f"{name}() {{{body}\n}}\n"


def published(ports_column):
    result = subprocess.run(
        ["zsh", "-f", "-c", extract("_published_tcp_ports") + "_published_tcp_ports"],
        input=ports_column, text=True, capture_output=True, timeout=10,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return result.stdout.split()


class PublishedTcpPortsTests(unittest.TestCase):
    def test_ipv4_and_ipv6_bindings_are_one_port(self):
        self.assertEqual(published("0.0.0.0:54322->5432/tcp, [::]:54322->5432/tcp\n"), ["54322"])

    def test_loopback_binding(self):
        self.assertEqual(published("127.0.0.1:54321->8000/tcp\n"), ["54321"])

    def test_unpublished_and_udp_ports_are_skipped(self):
        self.assertEqual(published("8000/tcp, 0.0.0.0:5353->5353/udp\n"), [])

    def test_ranges_are_skipped(self):
        self.assertEqual(published("0.0.0.0:54320-54329->54320-54329/tcp\n"), [])

    def test_ports_across_containers_are_deduplicated_in_order(self):
        column = "0.0.0.0:54323->3000/tcp\n0.0.0.0:54321->8000/tcp, 0.0.0.0:54323->3000/tcp\n\n"
        self.assertEqual(published(column), ["54323", "54321"])


if __name__ == "__main__":
    unittest.main()
