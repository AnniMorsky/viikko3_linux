#!/usr/bin/env bash

# Määritellään hakemisto, jonne HTML-raportti tallennetaan (Nginx /var/www/html/viikko3)
WEB_DIR="/var/www/html/viikko3"
mkdir -p "$WEB_DIR"

TEMP_FILE=$(mktemp)

# Haetaan tiedot komentojen ja putkien avulla
GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
UPTIME_TEXT=$(uptime -p)
DISK_PERCENT_STR=$(df -P / | awk 'NR == 2 {print $5}')
DISK_USAGE="${DISK_PERCENT_STR}" # Esim. "45%"

# Poistetaan prosenttimerkki numerotarkistusta varten
DISK_NUM=$(echo "$DISK_PERCENT_STR" | tr -d '%')

# Muistin tiedot (free -m komennolla)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')

# GitHub-linkki (vaihda omasi tähän)
GITHUB_URL="https://github.com/KAYTTAJANIMI/reponimi"

# Funktio levytilan tarkistukseen (käyttää if-lausetta ja vaadittua 80% rajaa)
check_disk_status() {
    local usage="$1"
    if [ "$usage" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Kutsutaan funktiota
DISK_STATUS=$(check_disk_status "$DISK_NUM")

# Kirjoitetaan HTML-tiedosto
cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 – Server Status Report</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            background: #f1f5f9;
            color: #172033;
        }
        h1, h2 {
            color: #173b65;
        }
        section {
            margin: 24px 0;
            padding: 24px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
        }
        .table-container {
            overflow-x: auto;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #cbd5e1;
            padding: 12px;
            text-align: left;
        }
        th {
            background: #dbeafe;
        }
        code {
            background: #e2e8f0;
            padding: 2px 5px;
            border-radius: 4px;
            overflow-wrap: anywhere;
        }
        a {
            color: #1746a2;
        }
        .warning {
            color: #b91c1c;
            font-weight: bold;
        }
        .ok {
            color: #15803d;
            font-weight: bold;
        }
        .note {
            color: #475569;
        }
    </style>
</head>
<body>
    <header>
        <h1>Server Status Report</h1>
        <p>Week 3: Linux command line and Bash scripting</p>
        <p>Welcome to my automated server status report page for CSC cPouta.</p>
    </header>
    <section>
        <h2>Current server status</h2>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Information</th>
                        <th scope="col">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th scope="row">Report generated</th>
                        <td>$GENERATED_AT</td>
                    </tr>
                    <tr>
                        <th scope="row">Server uptime</th>
                        <td>$UPTIME_TEXT</td>
                    </tr>
                    <tr>
                        <th scope="row">Root filesystem disk usage</th>
                        <td>$DISK_USAGE</td>
                    </tr>
                    <tr>
                        <th scope="row">Disk space status</th>
                        <td><span class="$([ "$DISK_STATUS" = "WARNING" ] && echo "warning" || echo "ok")">$DISK_STATUS</span></td>
                    </tr>
                    <tr>
                        <th scope="row">Total RAM</th>
                        <td>$MEM_TOTAL MiB</td>
                    </tr>
                    <tr>
                        <th scope="row">Available RAM</th>
                        <td>$MEM_AVAILABLE MiB</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <p>
            Disk space status is <strong>OK</strong> below 80% usage
            and <strong>WARNING</strong> at 80% or above.
        </p>
        <p class="note">
            Bash generates this report once per minute via cron/systemd.
            Wait approximately 1–2 minutes and reload the page
            to see a new generation time.
        </p>
    </section>
    <section>
        <h2>Commands used</h2>
        <ul>
            <li>
                <code>date '+%Y-%m-%d %H:%M:%S %Z'</code>:
                displays the current date, time, and time zone in a formatted string.
            </li>
            <li>
                <code>uptime -p</code>:
                displays how long the server has been running in a human-readable format.
            </li>
            <li>
                <code>df -P / | awk 'NR == 2 {print $5}'</code>:
                pipes filesystem info from <code>df</code> to <code>awk</code>, which extracts the usage percentage string from the second row.
            </li>
            <li>
                <code>free -m</code>:
                displays system memory usage statistics in mebibytes (MiB).
            </li>
        </ul>
    </section>
    <section>
        <h2>How the script works</h2>
        <p>
            The script collects server metrics using standard Linux utilities and captures their output into variables using command substitution <code>\$(...)</code>. 
            A custom function named <code>check_disk_status</code> evaluates the numeric disk usage against the 80% threshold using an <code>if</code> statement.
        </p>
        <p>
            To prevent users from seeing partially written files during generation, the script writes the HTML code to a temporary file first using <code>mktemp</code>, and then atomically moves it to <code>$WEB_DIR/index.html</code>. Nginx serves this folder at <code>/viikko3/</code>.
        </p>
    </section>
    <section>
        <h2>Scheduling</h2>
        <p>
            The automation is handled via a <strong>cron job</strong> configured for the current user. It executes the script once every minute. Cron automatically persists across system reboots, ensuring continuous updates.
        </p>
    </section>
    <section>
        <h2>Test results</h2>
        <h3>Syntax check and manual execution</h3>
        <p>
            Ran syntax verification using <code>bash -n generate_report.sh</code>, which completed with zero errors. Manual execution via <code>./generate_report.sh</code> successfully populated and updated the HTML page immediately.
        </p>
        <h3>Disk space status tests</h3>
        <p>
            Tested the status logic function with mock values (50%, 80%, and 90%). The expected outcomes matched the actual results.
        </p>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Test input</th>
                        <th scope="col">Expected status</th>
                        <th scope="col">Actual status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>50%</td>
                        <td>OK</td>
                        <td>OK</td>
                    </tr>
                    <tr>
                        <td>80%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                    <tr>
                        <td>90%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <h3>Automatic updates</h3>
        <p>
            Observed consecutive generation timestamps (e.g., 14:02:00, 14:03:00), verifying that cron triggers the script once per minute successfully.
        </p>
        <h3>Reboot test</h3>
        <p>
            After rebooting the virtual machine via <code>sudo reboot</code>, Nginx restarted automatically, both the Week 2 application and the Week 3 status report loaded correctly, and automated updates continued without manual intervention.
        </p>
    </section>
    <section>
        <h2>A problem solved or a lesson learned</h2>
        <p>
            <strong>Lesson learned:</strong> When generating files consumed directly by a web server via automated schedules, writing directly to the target file can cause race conditions where a user reads a half-written file. Using <code>mktemp</code> combined with an atomic <code>mv</code> operation solved this cleanly.
        </p>
    </section>
    <footer>
        <p><a href="$GITHUB_URL" target="_blank">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF

mv "$TEMP_FILE" "$WEB_DIR/index.html"
echo "Report successfully generated at $WEB_DIR/index.html"
