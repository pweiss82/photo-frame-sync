# Photo Frame Sync

A bash script that synchronizes photos from Google Drive to a local slideshow folder, converts HEIC images to JPG, and manages a photo frame display using `feh`.

## Features

- **Google Drive Sync**: Uses `rclone` to sync photos from a Google Drive shared folder
- **HEIC Conversion**: Automatically converts HEIC images to JPG using multiple fallback methods
- **Slideshow Management**: Starts and manages `feh` slideshow with configurable delay
- **Cleanup**: Removes orphaned files and HDR gain maps
- **Logging**: Comprehensive logging of all operations

## Prerequisites

### Required Software
- `rclone` - For Google Drive synchronization
- `feh` - For slideshow display
- `heif-convert` - For HEIC to JPG conversion (primary method)

### Optional Software (used as fallbacks)
- ImageMagick (`magick` or `convert`) - Alternative HEIC conversion
- `exiftool` - Extract preview images from HEIC files
- `rsync` - Efficient file copying
- `xdpyinfo` - X display detection
- `pkill`/`pgrep` - Process management

### System Requirements
- Linux system with X11 display
- Google Drive access with rclone configured
- Sufficient disk space for photo storage

## Installation

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd photoFrame
   ```

2. Configure rclone for Google Drive access:
   ```bash
   rclone config
   ```
   Follow the setup wizard to configure your Google Drive remote.

3. Update the configuration variables in `sync-photos.sh`:
   - `RAW_DIR`: Directory for raw photos from Google Drive
   - `DISPLAY_DIR`: Directory for processed photos ready for display
   - `RCLONE_REMOTE`: Your configured rclone remote name
   - `RCLONE_TEAM_DRIVE_ID`: Your Google Drive team drive ID
   - `RCLONE_SOURCE`: Source folder path in Google Drive

4. Make the script executable:
   ```bash
   chmod +x sync-photos.sh
   ```

## Configuration

Edit the configuration section at the top of `sync-photos.sh`:

```bash
RAW_DIR="/home/gfd/Pictures/PhotoFrame/Raw"
DISPLAY_DIR="/home/gfd/Pictures/PhotoFrame/Display"
RCLONE_REMOTE="gdrive"
RCLONE_TEAM_DRIVE_ID="0ANrWAw4_0pIuUk9PVA"
RCLONE_SOURCE="Display on TV"
SLIDESHOW_DELAY="10"
```

## Usage

### Manual Run
```bash
./sync-photos.sh
```

### Automated Scheduling
Add to crontab for regular synchronization:
```bash
# Sync every 30 minutes
*/30 * * * * /path/to/photoFrame/sync-photos.sh

# Or sync every hour
0 * * * * /path/to/photoFrame/sync-photos.sh
```

## How It Works

1. **Sync**: Downloads photos from Google Drive to the raw directory
2. **Convert**: Converts HEIC images to JPG using multiple fallback methods
3. **Copy**: Copies non-HEIC images to the display directory
4. **Cleanup**: Removes orphaned files and HDR gain maps
5. **Display**: Restarts the feh slideshow with new photos

## HEIC Conversion Methods

The script tries multiple methods to convert HEIC images:

1. **heif-convert** (primary) - Fast and efficient
2. **ImageMagick** - Fallback using `magick` or `convert`
3. **exiftool** - Extracts preview images as last resort
4. **Quarantine** - Moves problematic files to `.quarantine` directory

## Logging

All operations are logged to `/home/gfd/Pictures/PhotoFrame/sync.log` with timestamps.

## Troubleshooting

### Common Issues

1. **X Display Not Ready**: Ensure X11 is running and `DISPLAY` is set correctly
2. **HEIC Conversion Fails**: Install `heif-convert` or ImageMagick
3. **Rclone Errors**: Verify Google Drive configuration and permissions
4. **Permission Denied**: Check file permissions and ownership

### Debug Mode

Run with verbose output:
```bash
bash -x sync-photos.sh
```

## License

This project is open source. Feel free to modify and distribute.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues and questions, please open an issue on GitHub. 