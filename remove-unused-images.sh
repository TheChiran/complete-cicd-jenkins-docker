#!/bin/bash

# Get a list of all "solar-system" image IDs
solar_system_image_ids=$(docker images -q --filter "reference=*solar-system*")

if [ -z "$solar_system_image_ids" ]; then
  echo "No 'solar-system' images found."
  exit 0
fi

echo "Checking 'solar-system' images for running containers..."

# Iterate through each "solar-system" image ID
for image_id in $solar_system_image_ids; do
  # Check if any container is using this image ID
  if ! docker ps -aq --filter "ancestor=$image_id" | grep -q .; then
    echo "Image ID '$image_id' is not used by any running container. Removing..."
    docker rmi "$image_id"
  else
    echo "Image ID '$image_id' is being used by a container. Skipping removal."
  fi
done

echo "Finished checking and removing unused 'solar-system' images."