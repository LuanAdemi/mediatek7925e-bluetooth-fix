# MediaTek WiFi/Bluetooth Combo Card Fix

A fix for MediaTek WiFi/Bluetooth combo cards that are incorrectly identified as media devices, causing GVFS/GIO to interfere with Bluetooth functionality. This README is intended to give a comprehensive explanation of the issue and the script. If you need more information feel free to open an issue.

## The Problem

Some MediaTek WiFi/Bluetooth combo cards (specifically vendor ID `0489`, device ID `e111`) are being misidentified by Linux system components. When connected, the device is incorrectly recognized as:

- A PTP camera (gPhoto2)
- An MTP device (Media Transfer Protocol)
- A media player
- A color management device

This misidentification causes several issues:

### How GIO/GVFS Interferes

**GVFS** (GNOME Virtual File System) and GIO are userspace filesystem implementations used by many Linux distros. When they detect what they think is a media device (camera, phone, media player), they automatically attempt to:

1. **Mount the device** as a storage location
2. **Create a virtual filesystem** endpoint for file browsing
3. **Claim exclusive access** to the USB device
4. **Trigger desktop notifications** about the "new device"

When GVFS/GIO tries to mount your WiFi/Bluetooth card as a media device:

- The Bluetooth subsystem **loses access** to the device
- Bluetooth services **crash or fail to initialize**
- WiFi functionality may be **disrupted**
- The device becomes **unavailable** to its proper drivers

This happens because GVFS/GIO's userspace claim on the device conflicts with the kernel drivers (btusb, mt7xxx) that need low-level access to manage WiFi and Bluetooth functionality.

## Affected Devices

This fix is specifically for:

- **Vendor ID:** 0489
- **Device ID:** e111
- **Chip:** MediaTek WiFi/Bluetooth combo card
- **Common in:** Various laptop models with integrated wireless cards

An incomplete list of devices that are affected by this issue (having the wifi card installed) can be found [here](https://github.com/LuanAdemi/mediatek7925e-bluetooth-fix/blob/main/affecteddevices.md).


## Installation

### Quick Install

```bash
# Download the script
wget https://raw.githubusercontent.com/LuanAdemi/mediatek7925e-bluetooth-fix/refs/heads/main/mediatek_fix.sh

# Make it executable
chmod +x mediatek_fix.sh

# Run it with sudo
sudo ./mediatek_fix.sh --apply
```

Restart your PC (in some cases a full power cycle is needed)

### Manual Installation

See [here](https://github.com/LuanAdemi/mediatek7925e-bluetooth-fix/issues/1#issuecomment-3516650391)

## Uninstallation

To remove the fix:

```bash
sudo ./mediatek_fix.sh --undo
```

Then unplug/replug the device or reboot.

## System Requirements

- Linux kernel with udev support
- Root/sudo access

**Tested on:**
- Ubuntu 25.04
- Ubuntu 25.10
- Fedora 43

## Credits
Huge thanks to @bchardon for finding a [fix](https://github.com/LuanAdemi/mediatek7925e-bluetooth-fix/issues/1#issuecomment-3516650391) working on the new Fedora update.

## License

MIT License - Feel free to use and modify

---

**Note:** This fix is specific to the device ID `0489:e111`. If you have a different MediaTek WiFi/Bluetooth card with similar issues, you'll need to modify the vendor/device IDs in the script and udev rule.
