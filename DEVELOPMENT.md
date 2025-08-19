# Development Guide

This guide helps you set up a local development environment for the photo frame sync script on macOS.

## Prerequisites

All required tools have been installed via Homebrew:

- ✅ `rclone` - Google Drive synchronization
- ✅ `heif-convert` - HEIC to JPG conversion
- ✅ `imagemagick` - Alternative image conversion (magick/convert)
- ✅ `exiftool` - EXIF data extraction
- ✅ `rsync` - Efficient file copying
- ✅ `feh` - Image viewer/slideshow
- ✅ `pkill`/`pgrep` - Process management

## Local Setup

### 1. Directory Structure
```
~/Pictures/PhotoFrame/
├── Raw/          # Source photos from Google Drive
├── Display/      # Processed photos ready for slideshow
└── sync.log      # Log file
```

### 2. Test Scripts

- `sync-photos.sh` - Original script for Raspberry Pi
- `sync-photos-local.sh` - Local test version with Mac paths

### 3. Running Tests

```bash
# Test the local version (skips rclone sync)
./sync-photos-local.sh

# Test the original script
./sync-photos.sh
```

## Testing HEIC Conversion

To test with real HEIC files:

1. **Get a test HEIC file**:
   - Take a photo with your iPhone
   - Transfer it to your Mac
   - Copy it to `~/Pictures/PhotoFrame/Raw/`

2. **Run the conversion test**:
   ```bash
   ./sync-photos-local.sh
   ```

3. **Check the results**:
   - Look for converted JPG in `~/Pictures/PhotoFrame/Display/`
   - Check the log file: `cat ~/Pictures/PhotoFrame/sync.log`

## Testing with Real Google Drive

1. **Configure rclone**:
   ```bash
   rclone config
   ```
   - Add a new remote for Google Drive
   - Follow the authentication process

2. **Update the script configuration**:
   Edit `sync-photos-local.sh` and uncomment the rclone section:
   ```bash
   RCLONE_REMOTE="your_remote_name"
   RCLONE_TEAM_DRIVE_ID="your_team_drive_id"
   RCLONE_SOURCE="your_folder_path"
   ```

3. **Test with real sync**:
   ```bash
   ./sync-photos-local.sh
   ```

## Testing Slideshow (Optional)

To test the feh slideshow on macOS:

1. **Install X11** (if not already installed):
   ```bash
   brew install --cask xquartz
   ```

2. **Start X11**:
   - Open XQuartz from Applications
   - Or run: `open -a XQuartz`

3. **Enable feh in the script**:
   Edit `sync-photos-local.sh` and uncomment:
   ```bash
   kill_feh_if_running
   start_feh
   ```

## Development Workflow

1. **Make changes** to `sync-photos-local.sh`
2. **Test locally** with `./sync-photos-local.sh`
3. **Check logs** in `~/Pictures/PhotoFrame/sync.log`
4. **When satisfied**, update `sync-photos.sh` with your changes
5. **Commit and push** to GitHub

## Common Issues

### HEIC Conversion Fails
- Ensure `heif-convert` is installed: `which heif-convert`
- Try ImageMagick fallback: `magick input.heic output.jpg`
- Check file permissions and disk space

### Rclone Authentication Issues
- Run `rclone config` to reconfigure
- Check your Google Drive permissions
- Verify the remote name and path

### X11/feh Issues
- Install XQuartz: `brew install --cask xquartz`
- Start XQuartz before running feh
- Check DISPLAY environment variable

### Permission Issues
- Ensure script is executable: `chmod +x sync-photos-local.sh`
- Check directory permissions: `ls -la ~/Pictures/PhotoFrame/`

## Debugging

### Verbose Output
```bash
bash -x sync-photos-local.sh
```

### Check Tool Availability
```bash
which rclone heif-convert magick convert exiftool rsync feh
```

### Test Individual Components
```bash
# Test HEIC conversion
heif-convert test.heic test.jpg

# Test ImageMagick
magick test.heic test.jpg

# Test rsync
rsync -a source/ destination/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes locally
4. Update documentation if needed
5. Submit a pull request

## Resources

- [Rclone Documentation](https://rclone.org/docs/)
- [HEIF Converter](https://github.com/strukturag/libheif)
- [ImageMagick](https://imagemagick.org/)
- [feh Documentation](https://feh.finalrewind.org/) 