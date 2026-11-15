#!/usr/bin/env python3
"""Bundle the architecture deck into one portable HTML file.

Run from anywhere:  python3 presentation/architecture-deck/build.py
Output:             presentation/Argus-Architecture-Deck.html
"""
import base64
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PRES = HERE.parent
OUT = PRES / "Argus-Architecture-Deck.html"


def data_uri(path: Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def screenshot_uri(path: Path) -> str:
    """Downscale phone screenshots with macOS `sips` when available (keeps the file small)."""
    if shutil.which("sips"):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / (path.stem + ".jpg")
            subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82",
                            "--resampleWidth", "620", str(path), "--out", str(out)],
                           check=True, capture_output=True)
            return data_uri(out, "image/jpeg")
    return data_uri(path, "image/png")


def main() -> None:
    html = (HERE / "index.html").read_text()
    css = (HERE / "styles.css").read_text()
    css = re.sub(r'url\("\.\./assets/(Poppins-[A-Za-z]+\.ttf)"\)',
                 lambda m: f'url("{data_uri(PRES / "assets" / m.group(1), "font/ttf")}")', css)
    js = (HERE / "app.js").read_text()
    data = (PRES / "data.js").read_text()

    html = html.replace('<link rel="stylesheet" href="styles.css">', f"<style>\n{css}\n</style>")
    html = html.replace('<script src="../data.js"></script>', f"<script>\n{data}\n</script>")
    html = html.replace('<script src="app.js"></script>', f"<script>\n{js}\n</script>")
    html = re.sub(r'src="\.\./assets/(app-[a-z]+\.png)"',
                  lambda m: f'src="{screenshot_uri(PRES / "assets" / m.group(1))}"', html)

    leftovers = re.findall(r'(?:src|href)="(?!data:|#)[^"]+"', html)
    if leftovers:
        raise SystemExit(f"Unbundled references remain: {leftovers}")
    OUT.write_text(html)
    print(f"Wrote {OUT.relative_to(PRES.parent)} ({OUT.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
