#!/bin/bash

# Prompt user to confirm they have read the script
read -r -p "Did you read all the script before starting it? If not, please do, it's not that long and takes some very specific parameters (Y/n): " answer
case "${answer^^}" in
    y|Y )
        echo "Starting the script..."
        ;;
    * )
        echo "Please read the script before running it."
        exit 1
        ;;
esac

# Grafana variables
GRAFANA_URL="Your Grafana URL"
API_KEY="Your Grafana API Key"
DASHBOARD_UID="Your Grafana Dashboard UID"

# Local variables
FTTH_client_input="/local/path/ftth_clients.txt"
DASHBOARD_JSON_PATH="/loca/path/model2.json"

# Fetch the current dashboard JSON
curl -s -X GET "$GRAFANA_URL/api/dashboards/uid/$DASHBOARD_UID" -H "Authorization: Bearer $API_KEY" -o "$DASHBOARD_JSON_PATH"

# Fetch and process data from external API
# IMPORTANT: Place here the appropriate command or API call that fetches data and stores it in $FTTH_client_input
# This step is crucial for the script to work correctly. Ensure data is fetched and stored in the correct file ($FTTH_client_input).
# This script is working with IP address and router with and the file is formed like:
# 192.168.1.1:router1
# 192.168.1.2:router2


# Function to ensure good JSON indentation using jq
good_json_indentation() {
  local input_file="$1"
  local output_file=/tmp/modified_dashboard.json

  jq '.' "$input_file" > "$output_file"
  mv "$output_file" "$input_file"
}

# Invoke function to indent the fetched dashboard JSON
good_json_indentation "$DASHBOARD_JSON_PATH"

#########################################################
# From there, the script is build for my specific case, #
# you will probably need to adapt it to your case       #
#########################################################

# Read the ftth_clients.txt and prepare JSON custom variable for Grafana dashboard
OPTIONS="{\"current\": {\"selected\": false, \"text\": \"All\", \"value\": \"\$__all\"}, \"hide\": 0, \"includeAll\": true, \"multi\": false, \"name\": \"routersNameAndIP\", \"options\": [{\"selected\": true, \"text\": \"All\", \"value\": \"\$__all\"}"
while IFS=: read -r ip name; do
  OPTIONS+=", {\"selected\": false, \"text\": \"$ip\", \"value\": \"$name\"}"
done < "$FTTH_client_input"

# Build the query line for the custom variable
result=""
while IFS= read -r line; do
  # Replace the first colon with ' : ' and append to result
  formatted_line=$(echo "$line" | sed 's/:/ : /')
  if [ -z "$result" ]; then
    result="$formatted_line"
  else
    result="$result, $formatted_line"
  fi
done < "$FTTH_client_input"

# Append the end of the json variable
OPTIONS+="],\"query\": \"$result\", \"queryValue\": \"\", \"skipUrlSync\": false, \"type\": \"custom\"}"

# Define the end part of the dashboard JSON. You'll need to update this part based on your original dashboard JSON structure (take a note of your dashboard version to make it match).
# I still did not find a way to do this dynamically by taking it from the original one
END="] }, \"time\": {\"from\": \"now-1h\", \"to\": \"now\"}, \"timepicker\": {\"refresh_intervals\": [ \"30s\"]}, \"timezone\": \"\", \"title\": \"Your Dashbord Title\", \"uid\": \"the UID\", \"version\": the version,\"weekstart\": \"\"}}"

# Extract relevant part from original dashboard JSON and append options and end to create the modified dashboard JSON
# This is where the script cut the original json dashboard giving some information
# In my case I chosed a variable named "ip": everything after that is beeing cutted
awk '/"name": "ip"/ {found=1} {print} /}/ && found {exit}' $DASHBOARD_JSON_PATH > /tmp/cutted_dashboard.json

##########################################
# From there the script is again generic #
##########################################

# Append the custom variable options and end to the cutted dashboard JSON
echo "$OPTIONS" >> /tmp/cutted_dashboard.json
echo "$END" >> /tmp/cutted_dashboard.json

# Ensure proper JSON formatting for the modified dashboard JSON
good_json_indentation /tmp/cutted_dashboard.json

# Set execution permission on the modified JSON file (not typically necessary for JSON files)
chmod +x /tmp/cutted_dashboard.json

# Enable debug mode to trace script execution (kinda cool if you have issues)
set -x

# Upload the modified dashboard back to Grafana
curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d @/tmp/cutted_dashboard.json # Using @ for a file

