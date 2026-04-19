#!/usr/bin/env bash
# =============================================================================
# Diyar OS — Master Branding Installer
# scripts/install-branding.sh
#
# Deploys: wallpaper, GTK theme, icon theme, GRUB theme, Plymouth splash
# Usage:   sudo bash scripts/install-branding.sh
# =============================================================================
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' C='\033[0;36m' Y='\033[1;33m' B='\033[1m' N='\033[0m'
info() { echo -e "${C}${B}[DIYAR]${N} $*"; }
ok()   { echo -e "${G}${B}[  OK ]${N} $*"; }
warn() { echo -e "${Y}${B}[ WRN ]${N} $*"; }
die()  { echo -e "${R}${B}[ ERR ]${N} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash scripts/install-branding.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING_DIR="$(dirname "${SCRIPT_DIR}")"

# ── 1. Wallpaper ─────────────────────────────────────────────────────────────
info "Installing wallpaper..."
WALLPAPER_DEST="/usr/share/diyar-os/wallpapers"
mkdir -p "$WALLPAPER_DEST"

# Convert SVG to high-quality JPG/PNG using rsvg-convert or Inkscape
SVG_SRC="${BRANDING_DIR}/wallpapers/diyar-default.svg"
JPG_DEST="${WALLPAPER_DEST}/diyar-default.jpg"
PNG_DEST="${WALLPAPER_DEST}/diyar-default.png"

if command -v rsvg-convert &>/dev/null; then
    rsvg-convert -w 1920 -h 1080 -f png -o "$PNG_DEST" "$SVG_SRC"
    ok "Wallpaper PNG generated (rsvg-convert): ${PNG_DEST}"
elif command -v inkscape &>/dev/null; then
    inkscape --export-type=png --export-filename="$PNG_DEST" \
             -w 1920 -h 1080 "$SVG_SRC"
    ok "Wallpaper PNG generated (inkscape): ${PNG_DEST}"
elif command -v convert &>/dev/null; then
    convert -size 1920x1080 "$SVG_SRC" "$JPG_DEST"
    ok "Wallpaper JPG generated (ImageMagick): ${JPG_DEST}"
else
    # Install SVG directly — XFCE4 can use SVG wallpapers
    install -Dm644 "$SVG_SRC" "${WALLPAPER_DEST}/diyar-default.svg"
    warn "No SVG converter found — installed SVG directly."
    warn "Install librsvg2-bin for PNG conversion: apt-get install librsvg2-bin"
fi

# Copy SVG always
install -Dm644 "$SVG_SRC" "${WALLPAPER_DEST}/diyar-default.svg"

# Also install login wallpaper (same for now)
for dest in "${WALLPAPER_DEST}/diyar-login.jpg" "${WALLPAPER_DEST}/diyar-login.png"; do
    [[ -f "${JPG_DEST}" ]] && ln -sf "$JPG_DEST" "$dest" 2>/dev/null || true
    [[ -f "${PNG_DEST}" ]] && ln -sf "$PNG_DEST" "$dest" 2>/dev/null || true
done

ok "Wallpaper installed → ${WALLPAPER_DEST}"

# ── 2. Logo ───────────────────────────────────────────────────────────────────
info "Installing logo..."
LOGO_DEST="/usr/share/pixmaps"
install -Dm644 "${BRANDING_DIR}/diyar-logo.svg" "${LOGO_DEST}/diyar-logo.svg"

# Generate raster sizes
if command -v rsvg-convert &>/dev/null; then
    for size in 16 24 32 48 64 128 256; do
        mkdir -p "/usr/share/icons/hicolor/${size}x${size}/apps"
        rsvg-convert -w $size -h $size -f png \
            -o "/usr/share/icons/hicolor/${size}x${size}/apps/diyar-os.png" \
            "${BRANDING_DIR}/diyar-logo.svg" 2>/dev/null || true
    done
    ok "Logo raster sizes generated."
fi
ok "Logo installed."

# ── 3. GTK Theme ─────────────────────────────────────────────────────────────
info "Installing GTK theme..."
GTK_DEST="/usr/share/themes/Diyar"
mkdir -p "${GTK_DEST}/gtk-3.0"
install -Dm644 "${BRANDING_DIR}/gtk-theme/gtk-3.0/gtk.css" \
               "${GTK_DEST}/gtk-3.0/gtk.css"
install -Dm644 "${BRANDING_DIR}/gtk-theme/index.theme" \
               "${GTK_DEST}/index.theme"
ok "GTK theme installed → ${GTK_DEST}"

# ── 4. Icon Theme ─────────────────────────────────────────────────────────────
info "Installing icon theme..."
ICON_DEST="/usr/share/icons/Diyar"
cp -r "${BRANDING_DIR}/icons/." "${ICON_DEST}/"
# Place our custom app icons
for size in 16 24 32 48 64 128; do
    mkdir -p "${ICON_DEST}/${size}x${size}/apps"
    if command -v rsvg-convert &>/dev/null; then
        rsvg-convert -w $size -h $size -f png \
            -o "${ICON_DEST}/${size}x${size}/apps/diyar-os.png" \
            "${BRANDING_DIR}/icons/scalable/apps/diyar-os.svg" 2>/dev/null || true
    fi
done
gtk-update-icon-cache -f -t "${ICON_DEST}" 2>/dev/null || true
ok "Icon theme installed → ${ICON_DEST}"

# ── 5. GRUB Theme ─────────────────────────────────────────────────────────────
info "Installing GRUB theme..."
if [[ -d /boot/grub ]]; then
    bash "${BRANDING_DIR}/grub-theme/install.sh"
    ok "GRUB theme installed."
else
    warn "GRUB not found — skipping GRUB theme."
fi

# ── 6. Plymouth ───────────────────────────────────────────────────────────────
info "Installing Plymouth theme..."
if command -v plymouth-set-default-theme &>/dev/null; then
    bash "${BRANDING_DIR}/plymouth/install.sh"
    ok "Plymouth theme installed."
else
    warn "Plymouth not installed — skipping boot splash."
fi

# ── 7. System-wide GTK / icon defaults ────────────────────────────────────────
info "Setting system-wide defaults..."

# Update /etc/environment
if ! grep -q "DIYAR_THEME" /etc/environment 2>/dev/null; then
    cat >> /etc/environment <<'EOF'
GTK_THEME=Diyar
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
EOF
fi

# GTK 3 settings system-wide
mkdir -p /etc/gtk-3.0
cat > /etc/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-font-name=Vazirmatn 10
gtk-icon-theme-name=Diyar
gtk-theme-name=Diyar
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=close,minimize,maximize:
EOF

# Rebuild icon caches
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo -e "${B}${G}╔═══════════════════════════════════════════════════╗${N}"
echo -e "${B}${G}║   Diyar OS Branding installed successfully         ║${N}"
echo -e "${B}${G}╠═══════════════════════════════════════════════════╣${N}"
echo -e "${B}${G}║${N}  Wallpaper  → /usr/share/diyar-os/wallpapers/     ${B}${G}║${N}"
echo -e "${B}${G}║${N}  GTK theme  → /usr/share/themes/Diyar/            ${B}${G}║${N}"
echo -e "${B}${G}║${N}  Icons      → /usr/share/icons/Diyar/             ${B}${G}║${N}"
echo -e "${B}${G}║${N}  GRUB theme → /boot/grub/themes/diyar/            ${B}${G}║${N}"
echo -e "${B}${G}║${N}  Plymouth   → /usr/share/plymouth/themes/diyar/   ${B}${G}║${N}"
echo -e "${B}${G}╚═══════════════════════════════════════════════════╝${N}"
