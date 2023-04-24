#!/bin/bash

git clone https://mandhsr3@bitbucket.org/mandhasrinath/apiessentials.git

cd  apiessentials/
git checkout V7.7


#!/bin/bash

echo -e "Enter \n 1. Add New Location \n 2. Remove previous commit:  "
echo -n "Enter Your Choice: "
read choice



if [ "$choice" -eq "1" ]; then
	echo "Running code for option 1..."
	# Read the new location from the user
	echo -n "Enter the new location: "
	read new_location


	# Add the new location to the Jenkinsfile
	sed -i "/def site=\[/ s/\]\$/,\"${new_location}\"]/" Jenkinsfile

	# Ask the user if the new location has preprod
	echo -n "Does the new location include preprod environment? (y/n)"
	read preprod

	# Define the new if statement for the new location
	if [[ $preprod == "y" ]]; then
		new_if="if (Locations.equals(\"$new_location\")){\n    return env_${new_location}\n}"
		env_newlocation="[\"dev\", \"qa\", \"prod\", \"dr\", \"preprod\"]"
	else
		new_if="if (Locations.equals(\"$new_location\")){\n    return env_${new_location}\n}"
		env_newlocation="[\"dev\", \"qa\", \"prod\", \"dr\"]"
	fi

	sed -i "/def env_euiecriticaldmzfeb22=.*/a def env_${new_location}=$env_newlocation" Jenkinsfile
	# Find the line number of the existing if statement
	if_line=$(grep -n "if (Locations.equals(\"usnv-criticaldmz\"))" Jenkinsfile | cut -d: -f1)

	# Add the new if statement before the existing if statement
	sed  -i "${if_line}i ${new_if}" Jenkinsfile
	sed  -i 's/"apim_promote" && ("${params.Locations}" == "us-intra"/& || "${params.Locations}" == "'"${new_location}"'"/g' Jenkinsfile
	sed  -i 's/"BuildPipeline" && ("${params.Locations}" == "us-intra"/& || "${params.Locations}" == "'"${new_location}"'"/g' Jenkinsfile
	sed  -i 's/"Env_Update" && ("${params.Locations}" == "us-intra"/& || "${params.Locations}" == "'"${new_location}"'"/g' Jenkinsfile
	sed  -i 's/"DeployPipeline" && ("${params.Locations}" == "us-intra"/& || "${params.Locations}" == "'"${new_location}"'"/g' Jenkinsfile
	sed  -i 's/\("${Pipeline}" == "DeployPipeline" && (("${params.Locations}" != "us-intra")\)/\1\ \&\& ("${params.Locations}" != "'"${new_location}"'")/g' Jenkinsfile

	git add .
	git status
	git commit -am "modified Jenkins file for adding new location"
	git push origin V7.7
elif [ "$choice" -eq "2" ]; then
	echo "Running code for option 2..."
	echo -n "Are you sure want to delete the changes from previous commit ? (y/n)"
	read confirm
	if [ $confirm == "y" ]; then
		last_commit_hash=$(git log --pretty=format:'%H' -n 1)
		git revert --no-edit $last_commit_hash
		git push origin V7.7
		echo "removed previous commit"
	fi
else
  echo "Invalid input! Please enter 1 or 2."
fi