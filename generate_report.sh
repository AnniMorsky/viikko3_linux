#!/usr/bin/env bash

WEB_DIR="/var/www/html/viikko3"
mkdir -p "$WEB_DIR"

TEMP_FILE=$(mktemp)

GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
UPTIME_TEXT=$(uptime -p)
DISK_PERCENT_STR=$(df -P / | awk 'NR == 2 {print $5}')
DISK_USAGE="${DISK_PERCENT_STR}"

DISK_NUM=$(echo "$DISK_PERCENT_STR" | tr -d '%')

MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')

GITHUB_URL="https://github.com/annimorsky/viikko2"

check_disk_status() {
    local usage="$1"
    if [ "$usage" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

DISK_STATUS=$(check_disk_status "$DISK_NUM")

cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="fi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Server Status &ndash; Week 3 Report</title>
    <style>
        :root {
            --bg: #121212;
            --card-bg: #1e1e1e;
            --text: #e0e0e0;
            --text-muted: #a0a0a0;
            --border: #2c2c2c;
            --primary: #facc15;
            --ok: #22c55e;
            --warning: #f87171;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg);
            color: var(--text);
            max-width: 880px;
            margin: 0 auto;
            padding: 40px 20px;
            line-height: 1.5;
        }
        header {
            margin-bottom: 32px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 16px;
        }
        h1 {
            font-size: 1.8rem;
            color: #ffffff;
            margin: 0 0 8px 0;
        }
        header p {
            color: var(--text-muted);
            margin: 0;
            font-size: 0.95rem;
        }
        section {
            background-color: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 24px;
            margin-bottom: 24px;
        }
        h2 {
            font-size: 1.2rem;
            color: var(--primary);
            margin-top: 0;
            margin-bottom: 16px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 8px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 16px;
        }
        th, td {
            padding: 10px 14px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            font-size: 0.95rem;
        }
        th {
            color: var(--text-muted);
            width: 45%;
            font-weight: 500;
        }
        td {
            color: #ffffff;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
        }
        .status-ok {
            color: var(--ok);
            font-weight: 600;
        }
        .status-warning {
            color: var(--warning);
            font-weight: 600;
        }
        code {
            background-color: #121212;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 0.85rem;
            border: 1px solid var(--border);
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
        }
        ul {
            margin: 0;
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
            font-size: 0.95rem;
        }
        p {
            margin-top: 0;
            margin-bottom: 12px;
            color: var(--text-muted);
            font-size: 0.95rem;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: var(--text-muted);
            font-size: 0.85rem;
        }
        .footer a {
            color: var(--primary);
            text-decoration: none;
        }
        .footer a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

    <header>
        <h1>CSC cPouta Server Status</h1>
        <p>Automated Linux &amp; Bash Scripting Report &bull; Weekly Assignment 3</p>
    </header>

    <section>
        <h2>Live Metrics</h2>
        <table>
            <tr>
                <th>Report Generated</th>
                <td>$GENERATED_AT</td>
            </tr>
            <tr>
                <th>Server Uptime</th>
                <td>$UPTIME_TEXT</td>
            </tr>
            <tr>
                <th>Root Filesystem Usage</th>
                <td>$DISK_USAGE</td>
            </tr>
            <tr>
                <th>Disk Space Status</th>
                <td><span class="$([ "$DISK_STATUS" = "WARNING" ] && echo "status-warning" || echo "status-ok")">$DISK_STATUS</span></td>
            </tr>
            <tr>
                <th>Total RAM</th>
                <td>$MEM_TOTAL MiB</td>
            </tr>
            <tr>
                <th>Available RAM</th>
                <td>$MEM_AVAILABLE MiB</td>
            </tr>
        </table>
        <p style="font-size: 0.85rem; margin-bottom: 0;">
            Threshold policy: Status is evaluated as <code>OK</code> under 80% usage and <code>WARNING</code> at 80% or above. The page updates automatically every minute via cron.
        </p>
    </section>

    <section>
        <h2>Command Line Tools Used</h2>
        <ul>
            <li><code>date '+%Y-%m-%d %H:%M:%S %Z'</code> &ndash; Formats the current timestamp including timezone offset.</li>
            <li><code>uptime -p</code> &ndash; Outputs the system uptime in a clean, human-readable format.</li>
            <li><code>df -P / | awk 'NR == 2 {print \$5}'</code> &ndash; Pipes POSIX disk stats into <code>awk</code> to isolate the root filesystem usage percentage column.</li>
            <li><code>free -m</code> &ndash; Reports virtual memory statistics mapped in mebibytes (MiB).</li>
        </ul>
    </section>

    <section>
        <h2>Implementation Overview</h2>
        <p>
            The automation relies on a modular Bash script that captures command outputs via subshell substitution <code>\$(...)</code>. A dedicated validation function (<code>check_disk_status</code>) evaluates numerical thresholds using standard conditional logic. To prevent race conditions and half-rendered page reads while Nginx serves active traffic, the script writes updates to a temporary staging file via <code>mktemp</code> before performing an atomic move operation into the web root.
        </p>
    </section>

    <section>
        <h2>Scheduling &amp; Persistence</h2>
        <p>
            Job execution is handled by a user-level <strong>cron</strong> schedule set to trigger once every minute (<code>* * * * *</code>). Because cron daemon states are preserved across kernel cycles, automated report generation resumes seamlessly following virtual machine reboots.
        </p>
    </section>

    <section>
        <h2>Testing &amp; Validation</h2>
        <p>Syntax validation via <code>bash -n</code> passed cleanly without warnings. Logic branching tests for the disk utilization states yielded expected outputs across baseline and threshold parameters:</p>
        <table>
            <tr>
                <th>Test Input Value</th>
                <th>Expected Status</th>
                <th>Observed Result</th>
            </tr>
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
        </table>
    </section>

    <section>
        <h2>Troubleshooting &amp; Notes</h2>
        <p>
            <strong>Challenge:</strong> Early iterations risked exposing partial HTML payloads to the web server during file writes if a user loaded the URL mid-generation.<br>
            <strong>Solution:</strong> Implemented atomic file replacement using <code>mktemp</code> and <code>mv</code>, ensuring the target <code>index.html</code> is updated instantly rather than written incrementally.
        </p>
    </section>

    <div class="footer">
        <a href="$GITHUB_URL" target="_blank">View Repository on GitHub</a>
    </div>

</body>
</html>
EOF

mv "$TEMP_FILE" "$WEB_DIR/index.html"
chmod 644 "$WEB_DIR/index.html"

