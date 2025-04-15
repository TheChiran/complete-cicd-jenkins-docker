#!/bin/bash
echo "Intergation test........"

#aws --version

#Data=$(aws ec2 describe-instances)
#echo "Data - "$Data
#URL=$(aws ec2 describe-instances | jq -r ' .Reservations[].Instances[] | select(.Tags[].Value == #"dev-deploy") | .PublicDnsName')
#echo "URL Data - "$URL

URL='192.168.10.177'
MAX_RETRIES=3
RETRY_DELAY=5  # seconds

if [[ "$URL" != '' ]]; then
  attempt=1
  http_code=""
  while [[ "$attempt" -le "$MAX_RETRIES" ]]; do
    echo "Attempt $attempt to connect to http://$URL:5000/live"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:5000/live)
    if [[ "$http_code" -eq 200 ]]; then
      echo "Successfully connected after $attempt attempt(s)."
      break
    else
      echo "Connection failed (HTTP code: $http_code). Retrying in $RETRY_DELAY seconds..."
      sleep "$RETRY_DELAY"
      attempt=$((attempt + 1))
    fi
  done

  if [[ "$http_code" -ne 200 ]]; then
    echo "Failed to connect to http://$URL:5000/live after $MAX_RETRIES retries."
    exit 1
  fi

  planet_data=$(curl -s -XPOST http://$URL:5000/planet -H "Content-Type: application/json" -d '{"id": "3"}')
  echo "planet_data - "$planet_data
  planet_name=$(echo "$planet_data" | jq -r .name)
  echo "planet_name - "$planet_name

  if [[ "$http_code" -eq 200 && "$planet_name" == "Earth" ]]; then
    echo "HTTP Status Code and Planet Name Tests Passed"
  else
    echo "One or more test(s) failed"
    exit 1
  fi

else
  echo "Could not fetch a token/URL; Check/Debug line 8"
  exit 1
fi