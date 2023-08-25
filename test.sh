#!/bin/bash

download_url='https://download3.vmware.com/software/CART24FQ2_LIN64_DebPkg_2306/VMware-Horizon-Client-2306-8.10.0-21964631.x64.deb'
ver_no=$(echo "$download_url" | awk -F '/' '{print $NF}' | awk -F '[-.]' '{print $4 "-" $5 "." $6 "." $7 "-" $8}')
version_no=$(echo "$ver_no" | sed 's/-/./g')
echo "Latest stable version is : $version_no"

