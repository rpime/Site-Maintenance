-- Generate a unique ID (timestamp-based)
set uniqueID to (do shell script "date +%s")

-- Trigger persistent notification with unique group ID
do shell script "/opt/homebrew/bin/terminal-notifier -title 'Jubilee Backup' -message 'Opening Total Upkeep Dashboard…' -group " & uniqueID