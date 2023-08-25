#!/bin/sh


# check if latest version is already exist

version_no=$(curl -fI 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US' | grep -o 'firefox-[0-9.]\+[0-9]')
# echo "$version_no"

if [ -d "/var/www/html/firefox-releases/$version_no" ]; then

echo "Your Firefox Browser Is Already Updated"
echo "Latest Stable Version Is : Mozilla-Firefox-$version_no"
echo "0xff"
    exit 0
fi
echo " Latest available version is $version_no "
echo "P-15"

# Function to run the Firefox script
firefox_script() {
    

directory="/home/avadhoot/pkgs/firefox/latest-firefox"

# Check if the directory exists before attempting to remove it
if [ -d "$directory" ]; then
 # echo "Directory exists. Removing..."
  rm -rf "$directory"
  # echo "Directory 'latest-firefox' removed successfully."
fi

echo "Updating Firefox wait till it finishes. It will notify you with  'Successfull Message' once it is done."
echo "P-25"


# create a working directory :
mkdir -p ~/pkgs/firefox/latest-firefox

# Create a child directory named opt
mkdir -p ~/pkgs/firefox/latest-firefox/opt
mkdir -p ~/pkgs/firefox/latest-firefox/pkgs
mkdir -p ~/pkgs/firefox/latest-firefox/usr
cd ~/pkgs/firefox/latest-firefox/


# Fetch the download link for the latest Firefox Debian package
latest_firefox_url=$(curl -s 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US' | grep -oP 'https://[^"]+\.tar\.bz2')
# version_no=$(curl -s 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US' | grep -oP 'firefox-\K\d+\.\d+\.\d+')
# echo "Latest Firefox version: $version_no"

# echo "Latest Firefox version: $version_no"

if [ -z "$latest_firefox_url" ]; then
    echo "Failed to fetch the latest Firefox package URL."
    exit 1
fi

echo "Downloading latest version of firefox"
echo "P-35"

# Download the latest Debian package of Firefox
wget "$latest_firefox_url" -O latest_firefox.tar.bz2


echo "extracting package"

# Extract the downloaded Debian package
tar -xvf latest_firefox.tar.bz2 -C opt/

#remove latest_firefox.tar.bz2
rm latest_firefox.tar.bz2

echo "Done Exctraction"
echo "P-50"

# ver_file_path="/home/avadhoot/pkgs/firefox/latest-firefox/opt/firefox/application.ini"  # Path to the sq file

# Fetch the Version number from the application.ini file and store it in a variable
# version_no=$(grep -E '^Version=' "$ver_file_path" | cut -d'=' -f2)

# echo "Fetched Version number: $version_no"




#  Create a distribution directory and copy the old Firefox distribution files
mkdir -p opt/firefox/distribution
echo "copying necessary files"

# copy the old Firefox distribution files

cp -rf ~/pkgs/firefox/firefox-required/defaults/* opt/firefox/defaults/
cp -rf ~/pkgs/firefox/firefox-required/distribution/* opt/firefox/distribution/

cp -rf ~/pkgs/firefox/firefox-required/usr/* usr/

echo "creating package file"
echo "P-70"


# create a packages file

touch pkgs/005-$version_no

find . > pkgs/005-$version_no

# remove .
sed -i 's/^.//g' pkgs/005-$version_no

mksquashfs ../latest-firefox/ 005-$version_no.sq

rm -rf usr/ opt/ pkgs/
mkdir -p root/
mkdir -p tmp/

echo "writing install script"

cat > ~/pkgs/firefox/latest-firefox/root/install << 'EOF'
#!/bin/sh

pids=$(pgrep -f firefox)
for pid in $pids; do
    kill $pid
done

dir=$(find /data/apps-mount/ -type d -name 005* -print | awk 'NR==1')
[ -n "$dir" ] && { mount -t aufs -o remount,del="$dir" /; umount "$dir"; rm -rf "$dir"; }

mount -o remount,rw /sda1

rm -f /sda1/data/apps/005-firefox-* 2>/dev/null
cp /tmp/005-firefox-* /sda1/data/apps/
chmod 755 /sda1/data/apps/005-firefox-*
mount -o remount,ro /sda1

EOF


echo "assigning necessary permissions"

mv 005-$version_no.sq tmp/
chmod 755 tmp/005-$version_no.sq
chmod 755 root/install

tar -cvjf $version_no.tar.bz2 root tmp

 rm -rf root/ 
 rm -rf tmp/

echo "P-90"

damage corrupt $version_no.tar.bz2 1

echo "pushing patch to server"

mkdir -p /var/www/html/firefox-releases/$version_no

cp -rf /home/avadhoot/pkgs/firefox/latest-firefox/* /var/www/html/firefox-releases/$version_no/

echo "firefox has been updated successfully..."

echo "0xff"

}

firefox_script
