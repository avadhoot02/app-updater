#!/bin/sh
# Source and Destination directories
SOURCE_DIR=/home/avadhoot/pkgs/vmware/old_vmware/squashfs-root
DEST_DIR=/home/avadhoot/pkgs/vmware/latest-vmware
download_url='https://download3.vmware.com/software/CART24FQ2_LIN64_DebPkg_2306/VMware-Horizon-Client-2306-8.10.0-21964631.x64.deb'
ver_no=$(echo "$download_url" | awk -F '/' '{print $NF}' | awk -F '[-.]' '{print $4 "-" $5 "." $6 "." $7 "-" $8}')
version_no=$(echo "$ver_no" | sed 's/-/./g')
SER_DIR="/var/www/html/vmware-releases"
VER_DIR="/var/www/html/vmware-releases/vmware-view-horizon-$version_no"

if [ ! -d "$SER_DIR" ]; then
   echo "creating a server directory"
   mkdir -p "$SER_DIR"
fi

if [ -d "$VER_DIR" ]; then
  echo "Your Vmware App Is Already Updated"
  echo "Latest stable version is : vmware-view-horizon-$version_no"
  echo "ok"
  exit 0
fi

# Check if the directory exists before attempting to remove it
if [ -d "$DEST_DIR" ]; then
  echo "Directory exists. Removing..."
  rm -rf "$DEST_DIR"
 echo "Directory 'latest-vmware' removed successfully."
fi
echo "Updating wait till it finishes"
echo "P-15"

echo "Latest stable version is : $version_no"

# create a working directory :
mkdir -p $DEST_DIR

# Create a child directory named opt
mkdir -p $DEST_DIR/pkgs

# Download the file using curl
save_path="$DEST_DIR/vmware.deb"

echo "downloading ..."
echo "P-25"


curl -o "$save_path" "$download_url"

echo "Extracting deb package"
dpkg-deb -x "$save_path" "$DEST_DIR/"
echo "Extraction completed"
echo "deleting unnecessary files"
rm -rf "$DEST_DIR/vmware.deb"
echo "P-35"

echo "copying required files..."
#Binaries
cp -Parf "$SOURCE_DIR/usr/bin/vmware-usbarbitrator" "$DEST_DIR/usr/bin/"
cp -Parf "$SOURCE_DIR/usr/bin/vmware-view-legacy" "$DEST_DIR/usr/bin/"
cp -Parf "$SOURCE_DIR/usr/bin/vmware-view-usbdloader" "$DEST_DIR/usr/bin/"

# Libraries
cp -Parf "$SOURCE_DIR/usr/lib/cupsPPD/" "$DEST_DIR/usr/lib/"
cp -Parf "$SOURCE_DIR/usr/lib/pcoip/vchan_plugins/libscredirvchanclient.so" "$DEST_DIR/usr/lib/pcoip/vchan_plugins/"
cp -Parf "$SOURCE_DIR/usr/lib/pcoip/vchan_plugins/libviewMMDevRedir.so" "$DEST_DIR/usr/lib/pcoip/vchan_plugins/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/libsecrect.so" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/libudev.so.0" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/libcrypto.so.1.0.1" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/libssl.so.1.0.1" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/mediaprovider" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/librtavCliLib.so" "$DEST_DIR/usr/lib/vmware/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/libx264.so.157.6" "$DEST_DIR/usr/lib/vmware/"

# View Directories
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/html5mmr" "$DEST_DIR/usr/lib/vmware/view/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/integratedPrinting" "$DEST_DIR/usr/lib/vmware/view/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/scannerclient" "$DEST_DIR/usr/lib/vmware/view/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/serialportclient" "$DEST_DIR/usr/lib/vmware/view/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/usb" "$DEST_DIR/usr/lib/vmware/view/"
cp -Parf "$SOURCE_DIR/usr/lib/vmware/view/bin/vmware-view-legacy" "$DEST_DIR/usr/lib/vmware/view/bin/"

# Documentation
cp -Parf "$SOURCE_DIR/usr/share/doc/vmware-horizon-client/"* "$DEST_DIR/usr/share/doc/vmware-horizon-client/"

# Init.d script
cp -Parf "$SOURCE_DIR/etc/init.d/vmware-USBArbitrator" "$DEST_DIR/etc/init.d/"

# /etc/vmware/ directory and its contents
cp -Parf "$SOURCE_DIR/etc/vmware/"* "$DEST_DIR/etc/vmware/"

# /etc/vmware-vix directory
cp -Parf "$SOURCE_DIR/etc/vmware-vix" "$DEST_DIR/etc/"

# /etc/rc.d directory
cp -Parf "$SOURCE_DIR/etc/rc.d" "$DEST_DIR/etc/"
echo "P-50"

echo "writing package file"

cd $DEST_DIR/

find . > pkgs/007-vmware-view-horizon-$version_no

sed -i 's/^.//g' pkgs/007-vmware-view-horizon-$version_no

echo "building squashfs file system"

mksquashfs ../latest-vmware/ 007-vmware-view-horizon-$version_no.sq

chmod 755 007-vmware-view-horizon-$version_no.sq

mkdir -p "$DEST_DIR/root"
mkdir -p "$DEST_DIR/tmp"

echo "building patch file"

mv 007-vmware-view-horizon-$version_no.sq tmp/

echo '
#!/bin/sh

pids=$(pgrep -f vmware)
for pid in $pids; do
    kill $pid
done

dir=$(find /data/apps-mount/ -type d -name 007* -print | awk 'NR==1')


[ -n "$dir" ] && { mount -t aufs -o remount,del="$dir" /; umount "$dir"; rm -rf "$dir"; }

mount -o remount,rw /sda1
rm -f /sda1/data/apps/007* 2>/dev/null
cp /tmp/007-* /sda1/data/apps/
chmod 755 /sda1/data/apps/007-*
# chown -R  root:root /sda1/data/apps/007-*
mount -o remount,ro /sda1' > root/install

chmod 755 root/install

rm -rf etc/ pkgs/ usr/
echo "P-70"


tar -cvjf vmware-view-horizon-$version_no.tar.bz2 root tmp

rm -rf root/ tmp/

echo "encrypting"

damage corrupt vmware-view-horizon-$version_no.tar.bz2  1
echo "P-90"


echo "wait pushing patch to server"

\

mkdir -p "$VER_DIR"

cp -rf  vmware-view-horizon-$version_no.tar.bz2 "$VER_DIR"

echo "done"

echo "ok"
echo "vmware updated successfully"