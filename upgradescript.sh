#!/bin/bash

read -p "Enter the node type (1 for NM, 2 for ANM): " node_type

if [[ "$node_type" == "1" ]]; then
    read -p "Enter the instance name: " instance_name
    read -p "Enter the group name: " group_name
fi

file_name="maintenance.json"
directory_path="/apigw/v770/apigateway"
file_path="${directory_path}/${file_name}"
content="Content Here"

# Create the directory if it doesn't exist
mkdir -p "$directory_path"

# Create the file and write the content
echo "$content" > "$file_path"

if [ -e "$file_path" ]; then
    echo "Maintenance file created successfully."
else
    echo "An error occurred while creating the maintenance file. Exiting..."
    exit 1
fi

# Copy the folder with timestamp
backup_directory="/apigw/v770_Feb22_backup_$(date +%Y-%m-%d_%H-%M)"
cp -R "/apigw/v770/" "$backup_directory"

if [ -d "$backup_directory" ]; then
    echo "Folder copied to $backup_directory successfully."
else
    echo "An error occurred while copying the folder to $backup_directory. Exiting..."
    exit 1
fi

# Untar the package
pkg_name="/apigw/Installables/PKGNAME"
untar_directory="/apigw/77Update_Feb_23"

mkdir -p "$untar_directory"
tar xzvf "$pkg_name" -C "$untar_directory"

if [ -d "$untar_directory" ]; then
    echo "Package $pkg_name untarred successfully to $untar_directory."
else
    echo "An error occurred while untarring the package $pkg_name to $untar_directory. Exiting..."
    exit 1
fi

# Execute nodemanager and startinstance with -k option
if [[ "$node_type" == "1" ]]; then
    /apigw/v770/apigateway/posix/bin/startinstance -n "$instance_name" -g "$group_name" -k
fi

/apigw/v770/apigateway/posix/bin/nodemanager -k

# Check getcap status
getcap_output=$(getcap /apigw/v770/apigateway/platform/bin/vshell)
if [ -n "$getcap_output" ]; then
    echo "getcap output:"
    echo "$getcap_output"
    setcap_check=true
else
    setcap_check=false
    echo "setcap is not enabled."
fi

# Remove setcap if getcap status is true
if $setcap_check; then
    dzdo su -
    setcap -r /apigw/v770/apigateway/platform/bin/vshell
    echo "setcap removed for /apigw/v770/apigateway/platform/bin/vshell"
    exit  # Logout from root after setcap removal
fi

# Upgrade Script
/apigw/77update_Feb23/update_apigw.sh --install_dir /apigw/v770/ --no backup --mode unattended


