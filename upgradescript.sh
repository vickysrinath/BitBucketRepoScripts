#!/bin/bash

read -p "Enter the node type (1 for NM, 2 for ANM): " node_type

if [[ "$node_type" == "1" ]]; then
    read -p "Enter the instance name: " instance_name
    read -p "Enter the group name: " group_name
fi

apigw_directory="/apigw/v770/apigateway"
maintenance_file_path="${apigw_directory}/maintenance.json"
content="Content Here"


# Create the maintanience file and write the content
echo "$content" > "$maintenance_file_path"

if [ -e "$maintenance_file_path" ]; then
    echo "Maintenance file created successfully."
else
    echo "An error occurred while creating the maintenance file. Exiting..."
    exit 1
fi

# Backup the current verison
backup_directory="/apigw/v770_Feb22_backup_$(date +%Y-%m-%d_%H-%M)"
cp -R "/apigw/v770/" "$backup_directory"

if [ -d "$backup_directory" ]; then
    echo "Backup to directory $backup_directory is successful."
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

# Kill the Exisitng Process
if [[ "$node_type" == "1" ]]; then
    /apigw/v770/apigateway/posix/bin/startinstance -n "$instance_name" -g "$group_name" -k
fi

/apigw/v770/apigateway/posix/bin/nodemanager -k

# Check getcap status
getcap_output=$(getcap /apigw/v770/apigateway/platform/bin/vshell)
if [ -n "$getcap_output" ]; then
    echo "setcap is enabled."
    setcap_check=true
else
    setcap_check=false
    echo "setcap is not enabled."
fi

# Remove setcap if setcap status is true
if $setcap_check; then
    dzdo su -
    setcap -r /apigw/v770/apigateway/platform/bin/vshell
    echo "setcap removed for /apigw/v770/apigateway/platform/bin/vshell"
    exit  
fi

# Upgrade Script
upgrade_command_output=$(/apigw/77update_Feb23/update_apigw.sh --install_dir /apigw/v770/ --no backup --mode unattended 2>&1)
if echo "$upgrade_command_output" | grep -q "System update completed$"; then
    echo "Upgrade done."
else
    echo "An error occurred during the upgrade. Please check the logs for more details."
fi

if $setcap_check; then
    dzdo su -
    setcap 'cap_net_bind_service=+ep /apigw/v770/apigateway/platform/bin/vshell'
    echo "setcap enabled for /apigw/v770/apigateway/platform/bin/vshell"
    exit  
fi

#start process
/apigw/v770/apigateway/posix/bin/nodemanager -d
if [[ "$node_type" == "1" ]]; then
    /apigw/v770/apigateway/posix/bin/startinstance -n "$instance_name" -g "$group_name" -d
fi
