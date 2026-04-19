#!/usr/bin/env bash
# =============================================================================
# Diyar OS — GRUB Theme Installer
# grub-theme/install.sh
#
# Generates PNG assets via ImageMagick/Python and installs the theme.
# =============================================================================
set -euo pipefail

THEME_NAME="diyar"
THEME_DIR="/boot/grub/themes/${THEME_NAME}"
GRUB_DEFAULT="/etc/default/grub"

R='\033[0;31m' G='\033[0;32m' C='\033[0;36m' N='\033[0m'
ok()   { echo -e "${G}[OK]${N} $*"; }
info() { echo -e "${C}[  ]${N} $*"; }
die()  { echo -e "${R}[!!]${N} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root."

# --- Create theme directory ---
install -d "${THEME_DIR}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Copy theme.txt ---
install -m644 "${SCRIPT_DIR}/theme.txt" "${THEME_DIR}/theme.txt"

# --- Generate assets via Python (PIL/Pillow) ---
info "Generating GRUB theme assets..."

python3 - <<'PYEOF'
from PIL import Image, ImageDraw
import os

THEME_DIR = "/boot/grub/themes/diyar"
BG       = (10,  13,  20)
GOLD     = (201, 150, 58)
GOLD_MID = (232, 193, 112)
TEAL     = (26, 107, 124)
MID      = (26,  40,  64)
DARK     = (13,  21,  37)
SEL_BG   = (20,  32,  52)
SEL_HI   = (201, 150, 58)

def save(img, name):
    img.save(os.path.join(THEME_DIR, name))
    print(f"  generated: {name}")

# --- Background 1280x800 (GRUB uses this internally) ---
bg = Image.new("RGB", (1280, 800), BG)
d  = ImageDraw.Draw(bg)
# Subtle horizontal rules
for y in [80, 720]:
    for x in range(0, 1280, 4):
        d.line([(x,y),(x+2,y)], fill=(*GOLD, 30), width=1)
# Corner ornaments — top-left
d.line([(40,40),(40,90)], fill=(*GOLD,70), width=1)
d.line([(40,40),(90,40)], fill=(*GOLD,70), width=1)
# top-right
d.line([(1240,40),(1240,90)], fill=(*GOLD,70), width=1)
d.line([(1190,40),(1240,40)], fill=(*GOLD,70), width=1)
# bottom-left
d.line([(40,760),(40,710)], fill=(*GOLD,70), width=1)
d.line([(40,760),(90,760)], fill=(*GOLD,70), width=1)
# bottom-right
d.line([(1240,760),(1240,710)], fill=(*GOLD,70), width=1)
d.line([(1190,760),(1240,760)], fill=(*GOLD,70), width=1)
save(bg, "background.png")

# --- Selected item highlight: 600x36 ---
sel = Image.new("RGBA", (600, 36), (0,0,0,0))
d = ImageDraw.Draw(sel)
# Left gold accent bar
d.rectangle([(0,0),(3,35)], fill=(*GOLD_MID, 220))
# Background fill
d.rectangle([(4,0),(599,35)], fill=(*SEL_BG, 180))
# Bottom hairline
d.line([(4,35),(599,35)], fill=(*GOLD,60), width=1)
save(sel, "select_c.png")
# GRUB needs _l, _r, _c tiles
sel_l = Image.new("RGBA", (4, 36), (0,0,0,0))
ImageDraw.Draw(sel_l).rectangle([(0,0),(3,35)], fill=(*GOLD_MID, 220))
save(sel_l, "select_l.png")
sel_r = Image.new("RGBA", (1, 36), (0,0,0,0))
save(sel_r, "select_r.png")

# --- Horizontal rule: 1x1 gold pixel (scaled by GRUB) ---
hrule = Image.new("RGBA", (1, 1), (*GOLD, 100))
save(hrule, "hrule.png")

# --- Terminal box tiles (9-slice) ---
def make_terminal_tiles():
    for name, w, h, corners in [
        ("terminal_box_c.png", 4, 4, False),
        ("terminal_box_n.png", 4, 1, False),
        ("terminal_box_s.png", 4, 1, False),
        ("terminal_box_e.png", 1, 4, False),
        ("terminal_box_w.png", 1, 4, False),
        ("terminal_box_ne.png",4, 4, True),
        ("terminal_box_nw.png",4, 4, True),
        ("terminal_box_se.png",4, 4, True),
        ("terminal_box_sw.png",4, 4, True),
    ]:
        img = Image.new("RGBA", (w, h), (13, 21, 37, 200))
        save(img, name)
make_terminal_tiles()

print("  All assets generated.")
PYEOF

ok "GRUB theme assets generated."

# --- Install font (generate GRUB font from system Unifont) ---
info "Generating GRUB font..."
if command -v grub-mkfont &>/dev/null; then
    for size in 11 12 14 22; do
        # Try multiple font sources
        for font_src in \
            /usr/share/fonts/truetype/unifont/unifont.ttf \
            /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
            /usr/share/fonts/dejavu/DejaVuSans.ttf; do
            if [[ -f "$font_src" ]]; then
                grub-mkfont -s "$size" -o "${THEME_DIR}/Unifont_Regular_${size}.pf2" \
                    "$font_src" 2>/dev/null && \
                    ok "Font size ${size} generated." && break || true
            fi
        done
    done
    # Create symlinks with expected names
    for size in 11 12 14 22; do
        src="${THEME_DIR}/Unifont_Regular_${size}.pf2"
        dst="${THEME_DIR}/Unifont Regular ${size}.pf2"
        [[ -f "$src" ]] && ln -sf "$src" "$dst" 2>/dev/null || true
    done
else
    warn "grub-mkfont not found — fonts will use GRUB defaults."
fi

# --- Copy theme files ---
cp "${SCRIPT_DIR}/theme.txt" "${THEME_DIR}/theme.txt"

# --- Update /etc/default/grub ---
info "Updating /etc/default/grub..."

if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT"; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" "$GRUB_DEFAULT"
else
    echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >> "$GRUB_DEFAULT"
fi

# Enable graphics mode
sed -i 's/^#*GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,1280x720,auto/' "$GRUB_DEFAULT" \
    || echo "GRUB_GFXMODE=1920x1080,1280x720,auto" >> "$GRUB_DEFAULT"

sed -i 's/^#*GRUB_GFXPAYLOAD_LINUX=.*/GRUB_GFXPAYLOAD_LINUX=keep/' "$GRUB_DEFAULT" \
    || echo "GRUB_GFXPAYLOAD_LINUX=keep" >> "$GRUB_DEFAULT"

# Update GRUB
info "Running update-grub..."
update-grub

ok "Diyar OS GRUB theme installed → ${THEME_DIR}"
