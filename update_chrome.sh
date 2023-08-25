#!/bin/bash


#  Step 1: Define the URL of the Chrome package repository
repo_url="http://dl.google.com/linux/chrome/deb/dists/stable/main/binary-amd64/Packages"

# Step 2: Use 'curl' to fetch the Packages file and extract the version number using 'grep'
version_no=$(curl -s "$repo_url" | grep -m1 -A 10 '^Package: google-chrome-stable$' | grep -oP 'Version: \K\S+')

# Step 3: Replace hyphens with dots in the version number
version_no=${version_no//-*/}

# Step 4: Print the latest version number
# echo "Latest available Google Chrome version: $version_no"

if  [ -d "/var/www/html/chrome-releases/Google-Chrome-$version_no" ]; then
       echo "Your Chrome Browser Is Already Updated"
       echo " Latest Stable Version Is : $version_no"
       echo  "ok"

	exit 0
fi
	
# Function to run the chrome script
chrome_script() {


directory="/home/avadhoot/pkgs/chrome/latest-chrome"

# Check if the directory exists before attempting to remove it
if [ -d "$directory" ]; then
 # echo "Directory exists. Removing..."
  rm -rf "$directory"
 # echo "Directory 'latest-chrome' removed successfully."
fi
echo "Updating Chrome wait till it finishes.."

# create a working directory :
mkdir -p ~/pkgs/chrome/latest-chrome

# Create a child directory named opt
mkdir -p ~/pkgs/chrome/latest-chrome/pkgs
cd ~/pkgs/chrome/latest-chrome/



# : Download the latest version of Google Chrome for Ubuntu using curl
echo "Downloading the latest version of Google Chrome..."
echo "P-15"


download_url=$(curl -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" | grep -oP 'href="\K[^"]+')
curl -sLO "$download_url"


# : Extract the Debian package in the current directory
echo "Extracting the Debian package..."
echo "P-25"


dpkg-deb -x google-chrome-stable_current_amd64.deb .

echo "done extraction"
echo "P-50"




#  Find out the version number
# version=$(zcat ./usr/share/doc/google-chrome-stable/changelog.gz | head -n 1 | grep -oP '\(\K[^\)]+')
# version_no=$(zcat ./usr/share/doc/google-chrome-stable/changelog.gz | head -n 1 | grep -oP '\(\K[^\)]+' | sed 's/-1$//')

# echo "Google Chrome version: $version_no"

# Step 4: Clean up - remove the downloaded package
rm -rf  google-chrome-stable_current_amd64.deb

chmod 755  opt/google/chrome/libvulkan.so.1
chmod 4755 opt/google/chrome/chrome-sandbox 

rm -rf etc/
rm -rf usr/share/doc
rm -rf usr/share/man

# create a packages file

echo "creating package file"


touch pkgs/025-Google-Chrome-$version_no

find . > pkgs/025-Google-Chrome-$version_no
# remove .
sed -i 's/^.//g' pkgs/025-Google-Chrome-$version_no

mksquashfs ../latest-chrome/ 025-Google-Chrome-$version_no.sq

mkdir -p ~/pkgs/chrome/latest-chrome/root
mkdir -p ~/pkgs/chrome/latest-chrome/tmp

echo "writing install script"


echo '
#!/bin/sh

pids=$(pgrep -f google)
for pid in $pids; do
    kill $pid
done

dir=$(find /data/apps-mount/ -type d -name 025* -print | awk 'NR==1')
[ -n "$dir" ] && { mount -t aufs -o remount,del="$dir" /; umount "$dir"; rm -rf "$dir"; }

mount -o remount,rw /sda1
rm -f /sda1/data/apps/025* 2>/dev/null
cp /tmp/025-Google-* /sda1/data/apps/
chmod 755 /sda1/data/apps/025-Google-*
chown -R  root:root /sda1/data/apps/025-Google-*
mount -o remount,ro /sda1' > ~/pkgs/chrome/latest-chrome/root/install

echo "assigning necessary permissions"
echo "P-75"


chmod 755 025-Google-Chrome-$version_no.sq
chmod 755 root/install
mv 025-Google-Chrome-$version_no.sq  tmp/
rm -rf usr/ opt/ pkgs/

tar -cvjf Google-Chrome-$version_no.tar.bz2 root tmp

rm -rf root/ tmp/

damage corrupt Google-Chrome-$version_no.tar.bz2 1


echo "wait pushing patch to server"


mkdir -p /var/www/html/chrome-releases/Google-Chrome-$version_no
cp -rf /home/avadhoot/pkgs/chrome/latest-chrome/* /var/www/html/chrome-releases/Google-Chrome-$version_no/


echo "chrome has been updated successfully..."


echo "ok"


}
chrome_script
