#!/bin/bash
main_dir="/home/avadhoot/pkgs/citrix/latest-citrix"
usb_dir="$main_dir/usb"
usb_conf_file="/home/avadhoot/pkgs/citrix/latest-citrix/opt/Citrix/ICAClient/usb.conf"
file_path="/home/avadhoot/pkgs/citrix/latest-citrix/etc/icaclient/nls/en/module.ini"

ica_path="/home/avadhoot/Downloads/$1"
# echo "$ica_path"
usb_path="/home/avadhoot/Downloads/$2"
# echo "$usb_path"

icaclient_version=$(echo "$1" | grep -oP '\d+\.\d+\.\d+\.\d+')
# echo "Latest stable version is : $icaclient_version"


if  [ -d "/var/www/html/citrix-releases/Citrix-Workspace-$icaclient_version" ]; then
       echo "Your Citrix App Is Already Updated"
       echo " Latest Stable Version Is : Citrix-Workspace-$icaclient_version"
       
       echo  "ok"

	     exit 0
fi



# Remove main directory if it exists
if [ -d "$main_dir" ]; then
    echo "removing old main working direcory"
    rm -r "$main_dir"
    echo "removed old main working directory"
fi

echo "Making new main working directory"
# Create main directory
mkdir -p "$main_dir"
echo "Making temperory usb directory"
# Create usb directory within main directory
mkdir -p "$usb_dir"

cd "$main_dir/"
echo "P-15"


# Download and extract Citrix packages
citrix_package() {
    echo "extracting $ica_path package..."
    dpkg-deb -x "$ica_path"  "$main_dir"
	
    echo "extracting $usb_path package"

    dpkg-deb -x "$usb_path"  "$usb_dir"
    
    echo "merging  $usb_path packages into $ica_path package"

    # Move and organize files
    mv "$usb_dir/etc/init.d/"* "$main_dir/etc/init.d/"
    mv "$usb_dir/etc/udev" "$main_dir/etc/"
    mv "$usb_dir/opt/Citrix/ICAClient/"* "$main_dir/opt/Citrix/ICAClient/"
    mv "$usb_dir/usr/share/doc/"* "$main_dir/usr/share/doc/"

    # Clean up extracted directories
    rm -rf usb/
    rm -rf lib/


    echo "Done merging !"
    echo "P-25"

}

# Run the download function
citrix_package

# ##########################module.ini update  section #####################

# Define the file path variable

# Function to update VirtualDriver values in the [ICA 3.0] section
update_virtual_driver() {
  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
  fi

  # Create a temporary file to store the updated content
  tmp_file="${file_path}.tmp"

  # Use a flag to identify the [ICA 3.0] section
  in_ica_section=0

  # Read the file line by line and update the VirtualDriver line
  while IFS= read -r line; do
    if [ "$in_ica_section" -eq 1 ] && [[ "$line" == VirtualDriver* ]]; then
      # Append additional values to the existing VirtualDriver line
      line+=" ,GenericUSB,SpeechMikeAudio,PSPDPM,SpeechMikeMixer,SpeechMike,PSPHID,CiscoMeetingsVirtualChannel,CiscoTeamsVirtualChannel,HDXRTME,CiscoVirtualChannel,Imprivata,FTCtxBr,ZoomMedia"
      in_ica_section=0
    fi

    echo "$line" >> "$tmp_file"

    # Check for the start of the [ICA 3.0] section
    if [ "$line" == "[ICA 3.0]" ]; then
      in_ica_section=1
    fi
  done < "$file_path"

  # Replace the original file with the updated content
  mv "$tmp_file" "$file_path"
}

# Function to append key-value pairs after "VDGDT=On"
append_after_vdgdt() {
  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
  fi

  # Create a temporary file to store the updated content
  tmp_file="${file_path}.tmp"

  # Use a flag to check if "VDGDT=On" is found
  found_vdgdt=0

  # Preserve leading and trailing spaces
  while IFS= read -r line; do
    # Use a custom IFS to capture leading and trailing spaces
    IFS=

    # Check for "VDGDT=On" and append the new key-value pairs after it
    if [ "$found_vdgdt" -eq 1 ]; then
      echo "HDXRTME=Off" >> "$tmp_file"
      echo "CiscoVirtualChannel=Off" >> "$tmp_file"
      echo "CiscoMeetingsVirtualChannel=Off" >> "$tmp_file"
      echo "CiscoTeamsVirtualChannel=On" >> "$tmp_file"
      echo "Imprivata=Off" >> "$tmp_file"
      echo "FTCtxBr=Off" >> "$tmp_file"
      echo "SpeechMikeAudio=On" >> "$tmp_file"
      echo "SpeechMike=Off" >> "$tmp_file"
      echo "SpeechMikeMixer=On" >> "$tmp_file"
      echo "PSPDPM=Off" >> "$tmp_file"
      echo "PSPHID=On" >> "$tmp_file"
      echo "ZoomMedia=Off" >> "$tmp_file"

      found_vdgdt=0
    fi

    echo "$line" >> "$tmp_file"

    # Check for the start of "VDGDT=On" section
    if [ "$line" == "VDGDT=On" ]; then
      found_vdgdt=1
    fi
  done < "$file_path"

  # Replace the original file with the updated content
  mv "$tmp_file" "$file_path"
}

# Function to append sections after a specific line in a file
append_sections_after_line() {
  line_to_append_after="$1"
  sections_to_append="$2"

  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
  fi

  # Create a temporary file to store the updated content
  tmp_file="${file_path}.tmp"

  # Use a flag to check if the line is found
  found_line=0

  # Read the file line by line and append the sections
  while IFS= read -r line; do
    echo "$line" >> "$tmp_file"

    # Check for the line and append the new sections after it
    if [ "$found_line" -eq 1 ]; then
      echo "$sections_to_append" >> "$tmp_file"
      found_line=0
    fi

    if [ "$line" = "$line_to_append_after" ]; then
      found_line=1
    fi
  done < "$file_path"

  # Replace the original file with the updated content
  mv "$tmp_file" "$file_path"
}

# Sections to append after "DriverName = VDFIDO.DLL" line ends
new_sections='
[GenericUSB]
DriverName = VDGUSB.DLL

[FTCtxBr]
DriverName=FTCTXBR.DLL
LogLevel=1

[CiscoVirtualChannel]
DriverName=VDCISCO.DLL

[Imprivata]
DriverName=vdimp.dll

[HDXRTME]
DriverName=HDXRTME.so

[CiscoMeetingsVirtualChannel]
DriverName=libCiscoMeetingsCitrixPlugin.so

[CiscoTeamsVirtualChannel]
DriverName=libCiscoTeamsCitrixPlugin.so

[ZoomMedia]
DriverName=ZoomMedia.so

[SpeechMike]
DriverName=VDPSPCTR.dll
LIB_DIR=/opt/Citrix/ICAClient/SpMikeLib
LIB_NAME=libCtxSpMike.so
HIDDEV_DIR=/dev/usb/
JOYDEV_DIR=/dev/input/
FCBUTTON1=12
FCBUTTON2=4
FCBUTTON3=14
FCBUTTON4=10

[SpeechMikeAudio]
DriverName=VDPSPAUD.dll
LIB_DIR=/opt/Citrix/ICAClient/SpMikeLib
LIB_NAME=libCtxSbExtAlsa.so
FORCE_PCM=0

[SpeechMikeMixer]
DriverName=VDPSPMIX.dll
LIB_DIR=/opt/Citrix/ICAClient/SpMikeLib
LIB_NAME=libCtxMixerAlsa.so
DELAY_SET=0

[PSPDPM]
DriverName=VDPSPDPM.dll
LIB_DIR=/opt/Citrix/ICAClient/SpMikeLib
LIB_NAME=libCtxHidMan.so
DPM_DIR="/tmp/PhilipsDPM"
DPM_DRIVE= "P:\"

[PSPHID]
DriverName=VDPSPHID.dll
LIB_DIR=/opt/Citrix/ICAClient/SpMikeLib
LIB_NAME=libCtxHIDManagerRemoteClient.so
'

# Function to find and replace text in a file
find_replace() {
  search_pattern="$1"
  replacement="$2"

  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
  fi

  # Perform the find and replace operation using sed
  sed -i "s/${search_pattern}/${replacement}/g" "$file_path"
}

echo "Appending Values In [ICA 3.0] [VirtualDriver]  "
# Call the function to update the VirtualDriver values
update_virtual_driver

echo "Appending Key Values Pairs  in [ICA 3.0] section"
# Call the function to append key-value pairs after "VDGDT=On"
append_after_vdgdt

echo "Appending required sections in module.ini file"

# Append new sections after "DriverName = VDFIDO.DLL" line ends
append_sections_after_line "DriverName = VDFIDO.DLL" "$new_sections"

echo "Applying required settings..."

# Find and replace VDWEBRTC=On with VDWEBRTC=Off
find_replace "VDWEBRTC=On" "VDWEBRTC=Off"

# Find and replace CDViewerScreen=FALSE with CDViewerScreen=TRUE
find_replace "CDViewerScreen=FALSE" "CDViewerScreen=TRUE"

# Find and replace JitterBufferEnabled=TRUE with JitterBufferEnabled=FALSE
find_replace "JitterBufferEnabled=TRUE" "JitterBufferEnabled=FALSE"

echo "Updated module.ini file"
echo "P-35"


# ################################usb.conf update section ##################

# Define the path to the usb.conf file
echo "Updating usb.ini file"

# Add new lines after "DENY: vid=df04 pid=0004 # Nuance Mouse"
sed -i '/DENY: vid=df04 pid=0004 # Nuance Mouse/a \
#GENERAL RULES\n\
ALLOW: vid=147e\n\
ALLOW: vid=0c27' $usb_conf_file

# Add new lines after "DENY: class=e0 # Wireless controller"
sed -i '/DENY:  class=e0 # Wireless controller/a \
DENY: class=ff\n\
DENY: class=03 subclass=00 # Touch Panel' $usb_conf_file

# Replace "DENY: class=0b # Smartcard" with "ALLOW: class=0b # Smartcard"
sed -i 's/DENY:  class=0b # Smartcard/ALLOW: class=0b # Smartcard/' $usb_conf_file

echo "Updated usb.ini file!"
echo "P-50"


# ############################# req files section ############

echo "copying required files"
# Define source and destination directories
src_dir="/home/avadhoot/pkgs/citrix/citrix-required/opt/Citrix/ICAClient"
dst_dir="/home/avadhoot/pkgs/citrix/latest-citrix/opt/Citrix/ICAClient/"
lib_source="/home/avadhoot/pkgs/citrix/citrix-required/usr"
lib_dest="/home/avadhoot/pkgs/citrix/latest-citrix/usr/"



# Move files with renaming (rename the file in its current position)
echo "creating backup of original files by renaming "

mv "$dst_dir/lib/UIDialogLib.so" "$dst_dir/lib/UIDialogLib.so-orig"
mv "$dst_dir/lib/UIDialogLibWebKit3.so" "$dst_dir/lib/UIDialogLibWebKit3.so-orig"
mv "$dst_dir/lib/UIDialogLibWebKit3_ext/UIDialogLibWebKit3_ext.so" "$dst_dir/lib/UIDialogLibWebKit3_ext/UIDialogLibWebKit3_ext.so-orig"
mv "$dst_dir/util/storebrowse" "$dst_dir/util/storebrowse.bin"
 
# Copy required directories
cp -r "$src_dir/cef" "$dst_dir"
cp -rf /opt/Citrix/ICAClient/pkginf/ /home/avadhoot/pkgs/citrix/latest-citrix/opt/Citrix/ICAClient/
# cp -r "$src_dir/config/gstpresets" "$dst_dir/config/"
cp -rf /opt/Citrix/ICAClient/config/gstpresets/* /home/avadhoot/pkgs/citrix/latest-citrix/opt/Citrix/ICAClient/config/gstpresets/


# Copy individual files

cp -d "$src_dir/util/gst_play" "$dst_dir/util/"
cp -d "$src_dir/util/gst_read" "$dst_dir/util/"
cp -d "$src_dir/util/libgstflatstm.so" "$dst_dir/util/"
cp -d "$src_dir/util/storebrowse" "$dst_dir/util/"
cp -d "$src_dir/eula.txt" "$dst_dir/"
cp -d "$src_dir/vdimp.dll" "$dst_dir/"
cp -d "$src_dir/config/wfclient.template" "$dst_dir/config/"
cp -d "$src_dir/config/module.ini" "$dst_dir/config/"
cp -d "$src_dir/config/appsrv.template" "$dst_dir/config/"
cp -d "$src_dir/lib/UIDialogLib.so" "$dst_dir/lib/"
cp -r  "$src_dir/lib/UIDialogLibWebKit3.so" "$dst_dir/lib/"
cp -r "$src_dir/wfica.sh" "$dst_dir/"

# cp "$src_dir/lib/WebView_ext/libextension.so" "$dst_dir/lib/WebView_ext/"

echo "copying required libraries"

# Copy specific files to subdirectories
cp -r "$src_dir/lib/UIDialogLibWebKit3_ext/UIDialogLibWebKit3_ext.so" "$dst_dir/lib/UIDialogLibWebKit3_ext/"

#Copy required libraries

cp -rf "$lib_source/lib" "$lib_dest"
cp -rf "$lib_source/lib64" "$lib_dest"
cp -rf "$lib_source/llvm-10" "$lib_dest"



# Display completion message
echo "Required files and libraries are copied successfully!"

# #############comment section###############


# Function to append sections after a specific line in a file
append_sections_after_line() {
  line_to_append_after="$1"
  sections_to_append="$2"

  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
  fi

  # Create a temporary file to store the updated content
  tmp_file="${file_path}.tmp"

  # Use a flag to check if the line is found
  found_line=0

  # Read the file line by line and append the sections
  while IFS= read -r line; do
    echo "$line" >> "$tmp_file"

    # Check for the line and append the new sections after it
    if [ "$found_line" -eq 1 ]; then
      # Append the new sections
      echo "$sections_to_append" >> "$tmp_file"
      found_line=0
    fi

    if [ "$line" = "$line_to_append_after" ]; then
      # Append the comment line
      echo ";*****VXL***" >> "$tmp_file"
      found_line=1
    fi
  done < "$file_path"

  # Replace the original file with the updated content
  mv "$tmp_file" "$file_path"
}

# New sections and comment to be appended
new_sections_and_comment='
;*****VXL***
DesktopApplianceMode=True
'

# Append the comment and sections after "SRNotification=TRUE"
append_sections_after_line "SRNotification=TRUE" "$new_sections_and_comment"

echo "added comment in module.ini"
echo "P-70"




# ################ package section ##################

echo "generating package file"

# Define the file path
file_path_ver="/home/avadhoot/pkgs/citrix/latest-citrix/usr/share/doc/icaclient/changelog.gz"

mkdir -p /home/avadhoot/pkgs/citrix/latest-citrix/pkgs/

cd /home/avadhoot/pkgs/citrix/latest-citrix/

# Check if the file exists
if [ ! -f "$file_path_ver" ]; then
    echo "Error: File not found!"
    exit 1
fi

# Use 'zgrep' to extract the version number from the compressed file
version_no=$(zgrep -oP 'icaclient \(\K[\d.]+' "$file_path_ver")

# Check if version_no is empty (indicating no match found)
if [ -z "$version_no" ]; then
    echo "Error: Version number not found in the file."
    exit 1
fi

# Print the extracted version number
echo "Version number: $version_no"

echo "creating package file"

find . > pkgs/002-Citrix-Workspace-$version_no

sed -i 's/^.//g' pkgs/002-Citrix-Workspace-$version_no

# creating .sq
echo "creating squashfs "

mksquashfs ../latest-citrix/ 002-Citrix-Workspace-$version_no.sq
chmod 755 002-Citrix-Workspace-$version_no.sq

rm -rf usr/ opt/ pkgs/ etc/

mkdir -p root/
mkdir -p tmp/
mv 002-Citrix-Workspace-$version_no.sq tmp/

echo "writing install script"

echo '
#!/bin/sh

pids=$(pgrep -f citrix)
for pid in $pids; do
    kill $pid
done

dir=$(find /data/apps-mount/ -type d -name 002* -print | awk 'NR==1')
[ -n "$dir" ] && { mount -t aufs -o remount,del="$dir" /; umount "$dir"; rm -rf "$dir"; }

mount -o remount,rw /sda1
rm -f /sda1/data/apps/002* 2>/dev/null
cp /tmp/002-* /sda1/data/apps/
chmod 755 /sda1/data/apps/002-*
# chown -R  root:root /sda1/data/apps/025-Google-*
mount -o remount,ro /sda1' > root/install

chmod 755 root/install

echo "Generating patch..."
echo "P-90"


tar -cjvf Citrix-Workspace-$version_no.tar.bz2 root/ tmp/

damage corrupt Citrix-Workspace-$version_no.tar.bz2 1

echo "P-95"


echo "wait uploading patch to server"
mkdir -p /var/www/html/citrix-releases/Citrix-Workspace-$icaclient_version
cp -rf /home/avadhoot/pkgs/citrix/latest-citrix/Citrix-Workspace-$version_no.tar.bz2 /var/www/html/citrix-releases/Citrix-Workspace-$icaclient_version
echo "Done uploading"
echo "citrix updated successfully"
echo "ok"














