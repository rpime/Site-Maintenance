-- Ensure log file and folder exist
do shell script "mkdir -p ~/git/site-maint/bkp && touch ~/git/site-maint/bkp/tu-backup.log"
set logFile to ((path to home folder as text) & "git:site-maint:bkp:tu-backup.log") as alias

-- Safely close previous access
try
	close access logFile
end try

-- Open log file for writing
set logHandle to open for access logFile with write permission
write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Script started" & linefeed to logHandle

-- Ensure dialog shows on top
tell application "Finder" to activate
delay 0.2

-- Show dialog
write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Prompting user…" & linefeed to logHandle
try
	display dialog "Open Total Upkeep Dashboard in Chrome?" buttons {"Cancel", "Open"} default button "Open"
	if button returned of result is "Open" then
		write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] User clicked Open" & linefeed to logHandle

		-- Launch notification subscript (foreground)
		try
			do shell script "osascript ~/git/site-maint/bkp/notify-tu-backup.scpt"
			write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Notification launched" & linefeed to logHandle
		on error errMsg number errNum
			write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Notification error: " & errMsg & " (code " & errNum & ")" & linefeed to logHandle
		end try

		-- Open Chrome to TU Dashboard
		write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Launching Chrome…" & linefeed to logHandle
		tell application "Google Chrome"
			activate
			make new window
			set URL of active tab of window 1 to "https://thejubileebible.org/wp-admin/admin.php?page=boldgrid-backup"
		end tell
		write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Chrome opened successfully" & linefeed to logHandle
	else
		write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] User clicked Cancel" & linefeed to logHandle
	end if
on error errMsg number errNum
	write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Prompt error: " & errMsg & " (code " & errNum & ")" & linefeed to logHandle
end try

-- Final log line
write "[" & (do shell script "date +'%Y-%m-%d %H:%M:%S'") & "] Script ended" & linefeed to logHandle
try
	close access logHandle
end try
