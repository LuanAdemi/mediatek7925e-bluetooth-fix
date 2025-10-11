# MediaTek WiFi/Bluetooth Combo Card Fix

A fix for MediaTek WiFi/Bluetooth combo cards that are incorrectly identified as media devices, causing GVFS/GIO to interfere with Bluetooth functionality.

## The Problem

Some MediaTek WiFi/Bluetooth combo cards (specifically vendor ID `0489`, device ID `e111` from Foxconn/Hon Hai) are being misidentified by Linux system components. When connected, the device is incorrectly recognized as:

- A PTP camera (gPhoto2)
- An MTP device (Media Transfer Protocol)
- A media player
- A color management device

This misidentification causes several issues:

### How GIO/GVFS Interferes

**GVFS** (GNOME Virtual File System) is a userspace filesystem implementation used by many Linux desktop environments. When it detects what it thinks is a media device (camera, phone, media player), it automatically attempts to:

1. **Mount the device** as a storage location
2. **Create a virtual filesystem** endpoint for file browsing
3. **Claim exclusive access** to the USB device
4. **Trigger desktop notifications** about the "new device"

When GVFS tries to mount your WiFi/Bluetooth card as a media device:

- The Bluetooth subsystem **loses access** to the device
- Bluetooth services **crash or fail to initialize**
- WiFi functionality may be **disrupted**
- The device becomes **unavailable** to its proper drivers
- Desktop environment may show **error notifications**

This happens because GVFS's userspace claim on the device conflicts with the kernel drivers (btusb, mt76) that need low-level access to manage WiFi and Bluetooth functionality.

## Affected Devices

This fix is specifically for:

- **Vendor ID:** 0489 (Foxconn / Hon Hai)
- **Device ID:** e111
- **Chip:** MediaTek WiFi/Bluetooth combo card
- **Common in:** Various laptop models with integrated wireless cards

### How to Check If You're Affected

Run this command to see if your device is misidentified:

```bash
lsusb -d 0489:e111 -v 2>/dev/null | grep -E "idVendor|idProduct"
```

Then check udev properties:

```bash
udevadm info --query=all --name=/dev/bus/usb/*/$(lsusb | grep 0489:e111 | awk '{print $4}' | sed 's/://') 2>/dev/null | grep -E "GPHOTO2|MTP|MEDIA_PLAYER"
```

If you see properties like `ID_GPHOTO2=1`, `ID_MTP_DEVICE=1`, or `ID_MEDIA_PLAYER=1`, you're affected by this issue.

## The Solution

This script creates a **udev rule** that prevents the misidentification by:

1. **Removing false device properties** (GPHOTO2, MTP, MEDIA_PLAYER flags)
2. **Instructing GVFS to ignore the device** using `GVFS_IGNORE` environment variable
3. **Telling UDISKS to skip the device** using `UDISKS_IGNORE` environment variable
4. **Preventing automatic mounting** while allowing proper drivers to function

The fix works at the udev level, which processes device events before GVFS can claim the device.

### What the udev Rule Does

The rule matches your specific device by vendor/product ID and:

- Clears incorrect identification flags
- Tells userspace tools to ignore the device
- Allows kernel drivers (btusb, mt76) to claim it normally
- Prevents desktop environments from trying to mount it

## Installation

### Quick Install

```bash
# Download the script
wget https://github.com/YOUR_USERNAME/mediatek-bluetooth-fix/raw/main/fix-mediatek-bluetooth.sh

# Make it executable
chmod +x fix-mediatek-bluetooth.sh

# Run it with sudo
sudo ./fix-mediatek-bluetooth.sh
```

### Manual Installation

If you prefer to manually create the udev rule:

1. Create the file `/etc/udev/rules.d/99-mediatek-wifi-bluetooth.rules`:

```bash
sudo nano /etc/udev/rules.d/99-mediatek-wifi-bluetooth.rules
```

2. Add this content:

```
# MediaTek WiFi/Bluetooth combo card - prevent misidentification
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0489", ATTRS{idProduct}=="e111", \
    ENV{UDISKS_IGNORE}="1", \
    ENV{GVFS_IGNORE}="1", \
    ENV{ID_GPHOTO2}="", \
    ENV{GPHOTO2_DRIVER}="", \
    ENV{ID_MEDIA_PLAYER}="", \
    ENV{ID_MTP_DEVICE}="", \
    ENV{COLORD_DEVICE}="", \
    ENV{COLORD_KIND}=""
```

3. Reload udev rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=usb --attr-match=idVendor=0489 --attr-match=idProduct=e111
```

4. Unplug and replug the device (or reboot)

## Verification

After applying the fix, verify it's working:

```bash
udevadm info /dev/bus/usb/*/$(lsusb | grep 0489:e111 | awk '{print $4}' | sed 's/://') 2>/dev/null | grep -E 'ID_GPHOTO2|ID_MTP|ID_MEDIA'
```

This should return **empty output** if the fix is working correctly.

Check that Bluetooth is functioning:

```bash
systemctl status bluetooth
bluetoothctl show
```

## Uninstallation

To remove the fix:

```bash
sudo rm /etc/udev/rules.d/99-mediatek-wifi-bluetooth.rules
sudo udevadm control --reload-rules
```

Then unplug/replug the device or reboot.

## Troubleshooting

### Bluetooth still not working after fix

1. Restart the Bluetooth service:
```bash
sudo systemctl restart bluetooth
```

2. Check for other conflicting services:
```bash
systemctl status bluetooth
dmesg | grep -i bluetooth
```

3. Verify the udev rule is loaded:
```bash
udevadm test /sys/bus/usb/devices/*/3-5 2>&1 | grep -i "99-mediatek"
```

### Device not detected

If `lsusb` doesn't show your device:

1. Check physical connection
2. Try different USB ports
3. Check kernel messages: `dmesg | tail -50`
4. Verify USB controller is working: `lsusb` (should show other devices)

## System Requirements

- Linux kernel with udev support
- Root/sudo access

**Tested on:**
- Ubuntu 25.04+
- Fedora 42

## License

MIT License - Feel free to use and modify
---

**Note:** This fix is specific to the device ID `0489:e111`. If you have a different MediaTek WiFi/Bluetooth card with similar issues, you'll need to modify the vendor/device IDs in the script and udev rule.
