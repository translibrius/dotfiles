#!/usr/bin/env python3
"""emotefont: emotes.txt -> TwitchEmotes.ttf (color bitmap font) + emotes.gen.ts (name -> glyph map).

usage: emotefont.py [--ts OUT.ts] [--only N]      (add a line to emotes.txt, run, restart wezterm)

Terminal can't inline images through ConPTY, but it can draw a font. So every emote is a
glyph in Supplementary PUA-B (U+100000 + line index in emotes.txt).

Font layout copies NotoColorEmoji: CBDT/CBLC with PNG strikes and NO glyf table. That is on
purpose: FreeType only loads a bitmap strike from a *scalable* font at an exact ppem match,
while a bitmap-only font makes wezterm pick the strike and scale it to the cell itself.
"""
import argparse, io, os, sys, urllib.request
from pathlib import Path

from PIL import Image
from fontTools.fontBuilder import FontBuilder
from fontTools.ttLib import newTable
from fontTools.ttLib.tables.BitmapGlyphMetrics import SmallGlyphMetrics
from fontTools.ttLib.tables.C_B_D_T_ import cbdt_bitmap_format_17
from fontTools.ttLib.tables.E_B_L_C_ import BitmapSizeTable, SbitLineMetrics, Strike, eblc_index_sub_table_1

HERE = Path(__file__).parent
CACHE = HERE / "cache"
FIRST_CP = 0x100000  # plane 16: Nerd Fonts squat on U+F0001.. (Material Design icons)
PX = 128  # strike size; 4x emotes are 112-128px so this is ~native
# Baseline split of the PX square, same proportion as Noto (950/-250)
ASC = round(PX * 0.79)
DESC = PX - ASC
UPM = 1024
# wezterm scales a strike to the row height, so an emote is 1 row tall and 1 row wide.
# Iosevka's cell is 9x22 px at 13pt, so that is 2.44 cells: the mod pads each glyph to
# CELLS cells and BEARING centers it in them. Wider primary font -> fix CELL_ASPECT.
CELL_ASPECT = 9 / 22
CELLS = 3
BEARING = round(PX * (CELLS * CELL_ASPECT - 1) / 2)


def read_list(path):
    emotes = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        name, src, *frame = line.split()
        emotes.append((name, src, int(frame[0].lstrip("@")) if frame else None))
    names = [e[0] for e in emotes]
    dupes = {n for n in names if names.count(n) > 1}
    if dupes:
        sys.exit(f"emotes.txt: duplicate names: {', '.join(sorted(dupes))}")
    return emotes


def fetch(cp, src):
    if not src.startswith(("http://", "https://")):
        return (HERE / src).read_bytes()
    cached = CACHE / f"{cp:05X}"
    stamp = CACHE / f"{cp:05X}.url"
    if cached.exists() and stamp.exists() and stamp.read_text() == src:
        return cached.read_bytes()
    # CDNs 403 the default python UA
    req = urllib.request.Request(src, headers={"User-Agent": "Mozilla/5.0 emotefont"})
    data = urllib.request.urlopen(req, timeout=30).read()
    CACHE.mkdir(exist_ok=True)
    cached.write_bytes(data)
    stamp.write_text(src)
    return data


def to_strike_png(raw, frame):
    """One frame, fit into a transparent PX*PX square, centered."""
    src = Image.open(io.BytesIO(raw))
    # Plenty of animated emotes fade in from nothing, so default to the first frame with something on it
    for k in [frame] if frame is not None else range(getattr(src, "n_frames", 1)):
        src.seek(k)
        im = src.convert("RGBA")
        if sum(im.getchannel("A").histogram()[128:]) > 0.05 * im.width * im.height:
            break
    # Emotes drawn in a corner of a big empty canvas (Cluegi, Clap) are ants at 22px otherwise
    im = im.crop(im.getchannel("A").getbbox() or (0, 0, im.width, im.height))
    scale = min(PX / im.width, PX / im.height)
    w, h = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    im = im.resize((w, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (PX, PX), (0, 0, 0, 0))
    canvas.paste(im, ((PX - w) // 2, (PX - h) // 2))
    out = io.BytesIO()
    canvas.save(out, "PNG", optimize=True)
    return out.getvalue()


def build_font(pngs, out_path):
    glyph_names = [f"e{i:04d}" for i in range(len(pngs))]
    order = [".notdef"] + glyph_names

    fb = FontBuilder(unitsPerEm=UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({FIRST_CP + i: g for i, g in enumerate(glyph_names)})
    fb.setupHorizontalMetrics({g: (UPM, 0) for g in order})
    asc, desc = round(UPM * ASC / PX), -round(UPM * DESC / PX)
    fb.setupHorizontalHeader(ascent=asc, descent=desc)
    fb.setupNameTable({"familyName": "Twitch Emotes", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=asc, sTypoDescender=desc, usWinAscent=asc, usWinDescent=-desc)
    fb.setupPost()
    font = fb.font

    cbdt = font["CBDT"] = newTable("CBDT")
    cbdt.version = 3.0
    strike_data = {}
    for g, png in zip(glyph_names, pngs):
        glyph = cbdt_bitmap_format_17(None, font)
        m = glyph.metrics = SmallGlyphMetrics()
        m.height, m.width = PX, PX
        m.BearingX, m.BearingY, m.Advance = BEARING, ASC, PX
        glyph.imageData = png
        strike_data[g] = glyph
    cbdt.strikeData = [strike_data]

    cblc = font["CBLC"] = newTable("CBLC")
    cblc.version = 3.0
    size = BitmapSizeTable()
    size.colorRef = 0
    size.startGlyphIndex, size.endGlyphIndex = 1, len(glyph_names)
    size.ppemX = size.ppemY = PX
    size.bitDepth = 32
    size.flags = 1  # horizontal metrics
    for attr in ("hori", "vert"):
        lm = SbitLineMetrics()
        lm.ascender, lm.descender, lm.widthMax = ASC, -DESC, PX
        lm.caretSlopeNumerator = lm.caretSlopeDenominator = lm.caretOffset = 0
        lm.minOriginSB = lm.minAdvanceSB = lm.maxBeforeBL = lm.minAfterBL = 0
        lm.pad1 = lm.pad2 = 0
        setattr(size, attr, lm)
    sub = eblc_index_sub_table_1(None, font)
    sub.indexFormat, sub.imageFormat = 1, 17
    sub.firstGlyphIndex, sub.lastGlyphIndex = 1, len(glyph_names)
    sub.names = glyph_names
    strike = Strike()
    strike.bitmapSizeTable = size
    strike.indexSubTables = [sub]
    cblc.strikes = [strike]

    # A running wezterm keeps the font mapped: Windows then refuses to truncate or replace it,
    # but renaming it out of the way is allowed. Stale copies get swept on the next run.
    for stale in out_path.parent.glob("*.stale"):
        try:
            stale.unlink()
        except OSError:
            pass
    tmp = out_path.with_suffix(".tmp")
    font.save(tmp)
    try:
        tmp.replace(out_path)
        return False
    except PermissionError:
        out_path.replace(out_path.with_suffix(f".{os.getpid()}.stale"))
        tmp.replace(out_path)
        return True


def write_ts(emotes, ts_path):
    lines = ["// Generated by dotfiles/tools/emotefont/emotefont.py from emotes.txt. Do not edit.",
             "export const EMOTES: Record<string, string> = {"]
    for i, (name, *_) in enumerate(emotes):
        lines.append(f'  {name!r}: "\\u{{{FIRST_CP + i:X}}}",'.replace("'", '"'))
    lines.append("}")
    ts_path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main():
    ap = argparse.ArgumentParser(description="Build the Twitch emote font from emotes.txt")
    ap.add_argument("--ts", type=Path, default=HERE / "../../.claude/skills/twitch-emotes/hooks/emotes.gen.ts",
                    help="where the name -> glyph map goes (default: the twitch-emotes mod)")
    ap.add_argument("--only", type=int, help="build only the first N emotes (for testing)")
    args = ap.parse_args()

    emotes = read_list(HERE / "emotes.txt")[: args.only]
    pngs, failed = [], []
    for i, (name, src, frame) in enumerate(emotes):
        try:
            pngs.append(to_strike_png(fetch(FIRST_CP + i, src), frame))
        except Exception as e:
            failed.append(f"  {name}: {src}\n    {type(e).__name__}: {e}")
    if failed:
        # A hole would shift nothing (codepoints are by line), but a blank glyph is worse than a loud fail
        sys.exit("emotefont: could not load:\n" + "\n".join(failed))

    # Own folder: wezterm font_dirs walks the whole tree and .venv is not a snack
    out = HERE / "font" / "TwitchEmotes.ttf"
    out.parent.mkdir(exist_ok=True)
    was_in_use = build_font(pngs, out)
    write_ts(emotes, args.ts)
    print(f"{out.name}: {len(emotes)} emotes, U+{FIRST_CP:X}..U+{FIRST_CP + len(emotes) - 1:X}, {out.stat().st_size // 1024} KiB")
    if was_in_use:
        print("font was in use: restart wezterm to see the new glyphs")


if __name__ == "__main__":
    main()
