"""Shared helpers: plain-urllib download from Zenodo + remote ZIP access by HTTP Range.

No secrets, no user information: only a generic User-Agent is sent.
Downloaded files are DATA ONLY - they are parsed, never executed.
"""
import io
import os
import sys
import time
import urllib.parse
import urllib.request
import zipfile

UA = "open-data-fetch-script/1.0 (python-urllib)"
HERE = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.dirname(HERE)
DERIVED = os.path.join(DATA_DIR, "derived")
# raw downloads go here (git-ignored); override with env DATA_CACHE or --cache
DEFAULT_CACHE = os.environ.get("DATA_CACHE", os.path.join(DATA_DIR, "raw_cache"))


def cache_dir(argv=None):
    argv = sys.argv if argv is None else argv
    c = DEFAULT_CACHE
    if "--cache" in argv:
        c = argv[argv.index("--cache") + 1]
    os.makedirs(c, exist_ok=True)
    os.makedirs(DERIVED, exist_ok=True)
    return c


def zenodo_url(record, key):
    return "https://zenodo.org/api/records/%s/files/%s/content" % (
        record, urllib.parse.quote(key))


def _open(url, headers=None, retries=5):
    h = {"User-Agent": UA}
    if headers:
        h.update(headers)
    last = None
    for i in range(retries):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=120)
        except Exception as e:  # noqa
            last = e
            time.sleep(3 * (i + 1))
    raise last


def download(url, dest, expected_size=None):
    """Download url to dest unless already present (with matching size)."""
    if os.path.exists(dest) and (expected_size is None or os.path.getsize(dest) == expected_size):
        return dest
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".part"
    with _open(url) as r, open(tmp, "wb") as f:
        while True:
            b = r.read(1 << 20)
            if not b:
                break
            f.write(b)
    os.replace(tmp, dest)
    return dest


class HttpRangeFile(io.RawIOBase):
    """Read-only seekable file over HTTP Range requests (to read ZIP members
    of a multi-GB archive without downloading the archive)."""

    def __init__(self, url, block=1 << 16):
        self.url = url
        self.pos = 0
        self.block = block
        self._cache = {}
        with _open(url, {"Range": "bytes=0-0"}) as r:
            cr = r.headers.get("Content-Range")
            if r.status != 206 or not cr:
                raise IOError("server does not support Range requests")
            self.size = int(cr.split("/")[1])
        self.bytes_fetched = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, off, whence=0):
        if whence == 0:
            self.pos = off
        elif whence == 1:
            self.pos += off
        else:
            self.pos = self.size + off
        return self.pos

    def _get(self, a, b):
        with _open(self.url, {"Range": "bytes=%d-%d" % (a, b - 1)}) as r:
            d = r.read()
        self.bytes_fetched += len(d)
        return d

    def read(self, n=-1):
        if n < 0:
            n = self.size - self.pos
        n = max(0, min(n, self.size - self.pos))
        if n == 0:
            return b""
        out = bytearray()
        a = self.pos
        end = a + n
        if n > 4 * self.block:  # big sequential read: one request, no cache
            out += self._get(a, end)
        else:
            blk = a // self.block
            while blk * self.block < end:
                if blk not in self._cache:
                    if len(self._cache) > 64:
                        self._cache.clear()
                    s = blk * self.block
                    self._cache[blk] = self._get(s, min(s + self.block, self.size))
                d = self._cache[blk]
                lo = max(a, blk * self.block) - blk * self.block
                hi = min(end, (blk + 1) * self.block) - blk * self.block
                out += d[lo:hi]
                blk += 1
        self.pos = end
        return bytes(out)

    def readinto(self, b):
        d = self.read(len(b))
        b[:len(d)] = d
        return len(d)


def remote_zip(url):
    f = HttpRangeFile(url)
    return zipfile.ZipFile(io.BufferedReader(f, buffer_size=1 << 16)), f


def write_listing(zf, path):
    with open(path, "w", encoding="utf-8") as f:
        f.write("size_bytes\tcompressed_bytes\tname\n")
        for i in zf.infolist():
            f.write("%d\t%d\t%s\n" % (i.file_size, i.compress_size, i.filename))


def fetch_members(url, want, dest_dir, listing_path=None):
    """Extract from a remote ZIP only the members for which want(name) is True.
    Files are written (as data) under dest_dir keeping the archive path.
    Returns list of (member_name, local_path)."""
    import json
    marker = os.path.join(dest_dir, "_fetched.json")
    if os.path.exists(marker):
        with open(marker, encoding="utf-8") as f:
            return [tuple(x) for x in json.load(f)]
    os.makedirs(dest_dir, exist_ok=True)
    zf, _ = remote_zip(url)
    if listing_path:
        write_listing(zf, listing_path)
    out = []
    root = os.path.realpath(dest_dir)
    for info in zf.infolist():
        n = info.filename
        if n.endswith("/") or not want(n):
            continue
        local = os.path.realpath(os.path.join(dest_dir, *[p for p in n.split("/") if p not in ("", ".", "..")]))
        if not local.startswith(root + os.sep):
            raise IOError("unsafe member path: " + n)
        os.makedirs(os.path.dirname(local), exist_ok=True)
        with zf.open(info) as src, open(local, "wb") as dst:
            dst.write(src.read())
        out.append((n, local))
    with open(marker, "w", encoding="utf-8") as f:
        json.dump(out, f)
    return out


def zenodo_file(record, key, cache):
    """Download one Zenodo file into cache/<record>/ and verify size+md5 against the API."""
    import hashlib
    import json
    dest = os.path.join(cache, str(record), os.path.basename(key))
    with _open("https://zenodo.org/api/records/%s" % record) as r:
        meta = json.load(r)
    ent = [f for f in meta["files"] if f["key"] == key][0]
    for attempt in range(3):
        download(zenodo_url(record, key), dest, expected_size=ent["size"])
        h = hashlib.md5()
        with open(dest, "rb") as f:
            for b in iter(lambda: f.read(1 << 20), b""):
                h.update(b)
        if "md5:" + h.hexdigest() == ent["checksum"]:
            return dest
        os.remove(dest)
    raise IOError("checksum mismatch for " + key)
