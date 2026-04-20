# diyar-branding

> Visual identity assets for **Diyar OS — ديار**
> Wallpaper · GRUB theme · Plymouth boot splash · GTK3 theme · Icon theme · Logo

---

## Repository structure

```
diyar-branding/
├── wallpapers/
│   └── diyar-default.svg        ← 1920×1080 geometric Arabic wallpaper (SVG)
│
├── grub-theme/
│   ├── theme.txt                ← GRUB2 theme descriptor
│   └── install.sh               ← generates PNG assets + installs theme
│
├── plymouth/
│   ├── diyar-theme/
│   │   ├── diyar.plymouth       ← Plymouth theme descriptor
│   │   └── diyar.script         ← Animated boot splash script
│   └── install.sh               ← generates PNG assets + registers theme
│
├── gtk-theme/
│   ├── gtk-3.0/
│   │   └── gtk.css              ← Full GTK3 stylesheet (dark, gold accent)
│   └── index.theme              ← GTK theme metadata
│
├── icons/
│   ├── index.theme              ← Icon theme metadata (inherits Papirus-Dark)
│   └── scalable/
│       └── apps/
│           └── diyar-os.svg     ← App icon (geometric dal mark)
│
├── scripts/
│   └── install-branding.sh      ← Master installer (deploys everything)
│
├── diyar-logo.svg               ← Primary logo mark
└── README.md                    ← This file
```

---

## Design language

- Deep navy base `#0D1525`
- Gold primary accent `#C9963A` / `#E8C170`
- Teal secondary `#1A6B7C` / `#24A0B5`
- Zero border-radius on containers — sharp, geometric
- Islamic 8-point star geometric texture
- Logo: the letter **د** (Dal) deconstructed into a geometric mark

---

## Installation

```bash
# Install everything at once (requires root)
sudo bash scripts/install-branding.sh

# Or install individual components
sudo bash grub-theme/install.sh
sudo bash plymouth/install.sh
```

### Manual GTK theme install
```bash
sudo cp -r gtk-theme/ /usr/share/themes/Diyar/
```

### Manual icon theme install
```bash
sudo cp -r icons/ /usr/share/icons/Diyar/
sudo gtk-update-icon-cache -f /usr/share/icons/Diyar/
```

---

## Integration with diyar-os

The hook `0070-branding.hook.chroot` (in `diyar-os/config/hooks/live/`) clones this repo during ISO build and runs `install-branding.sh` inside the chroot automatically.

---

*ديار — وطن رقمي بهوية حقيقية*
