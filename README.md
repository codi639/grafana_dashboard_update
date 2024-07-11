# Grafana Dashboard Custom Variable Builder Script

This Bash script automates the process of modifying and uploading a Grafana dashboard configuration to build a custom variable using Grafana's API. It fetches the current dashboard JSON, integrates external data, updates the dashboard JSON, and uploads the modified JSON back to Grafana.

## Requirements

- Bash (tested on GNU Bash)
- `curl` command-line tool
- `jq` for JSON manipulation

## Setup

1. Clone the Repository:

```bash
git clone https://github.com/codi639/grafana_dashboard_update
```

2. Set Grafana Variables:
  - Modify the following variables in the script (update_dashboard.sh):
  - GRAFANA_URL: URL of your Grafana instance.
  - API_KEY: API key for authentication with Grafana.
  - DASHBOARD_UID: UID of the Grafana dashboard you want to modify.
  - DASHBOARD_JSON_PATH: Local path where the original dashboard JSON is stored.
  - FTTH_client_input: Path to a text file (ftth_clients.txt) containing IP addresses and router names.

3. External Data Setup:
  - Implement the appropriate command or API call to fetch external data and store it in ftth_clients.txt as IP addresses and router names (e.g.:
192.168.1.1:router1
192.168.1.2:router2).

4. Setup a Grafana API key
  - Using the administration parameter of your Grafana instance, configure an API key that have the good permissions concerning your dashboard.
  - You should also take note of the UID of the dashboard you want to make change.

## Usage
1. Do a backup of your actual Dashboard in case things goes bad.

2. Run the Script:

```bash
./update_dashboard.sh
```

3. Verify Execution:
- Verify changes in the Grafana dashboard specified by DASHBOARD_UID. You may also find the changes using the Grafana UI in the variables parameter.

## Script Details
### Fetching Current Dashboard JSON

Uses curl to retrieve the JSON of the specified Grafana dashboard (`DASHBOARD_UID`) and stores it locally (`DASHBOARD_JSON_PATH`).

### Processing External Data

Uncomment and implement data fetching from an external API to populate ftth_clients.txt with IP addresses and router names.

### JSON Formatting Function

Uses `jq` to ensure proper indentation and formatting of JSON files (`good_json_indentation` function).

### Building Custom Variable

Reads ftth_clients.txt to construct the Grafana custom variable.
Generates a JSON structure (`OPTIONS`) containing the custom variable based on the data fetched and located in `FTTH_client_input`.

### Constructing Modified Dashboard JSON

Uses `awk` to extract relevant parts from the original dashboard JSON (`DASHBOARD_JSON_PATH`).
Appends constructed OPTIONS and completes the JSON structure to create a modified JSON (`/tmp/cutted_dashboard.json`).

### Final Steps

Ensures proper formatting of `/tmp/cutted_dashboard.json`.
Uploads the modified dashboard JSON back to Grafana using curl and the Grafana API (/api/dashboards/db).

## Notes

This script assumes familiarity with Grafana's API and JSON structure for dashboards.
Adjust paths, commands, and variables according to your specific Grafana setup and requirements.
Always validate changes in Grafana after running the script to ensure the desired custom variable is properly updated.
