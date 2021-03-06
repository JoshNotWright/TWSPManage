#!/bin/bash
# Server Management Tool for TheWrightServer

HOST=$(jq -r '.host' config.json)
APIKEY=$(jq -r '.apikey' config.json)
applicationKey=$(jq -r '.applicationKey' config.json)
paperEggID=$(jq -r '.paperEggID' config.json)
snapshotEggID=$(jq -r '.snapshotEggID' config.json)
paperGeyserEggID=$(jq -r '.paperGeyserEggID' config.json)
companyName=$(jq -r '.companyName' config.json)
ANNOUNCE_MESSAGE="This server is going down momentarily. This process is automated, and the server will be returning soon."

# API call to request server install and then wait 10 seconds
function ServerInstall {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    GetFriendlyName
    GetServerState 
    if [ $ServerState = "ONLINE" ]; then
        RunningServers+=("$n")
    fi
    curl -s "$HOST/api/client/servers/$n/settings/reinstall" > /dev/null \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -H 'Authorization: Bearer '$APIKEY'' \
            -X POST
    msgs=( "Updating $FriendlyName." "Updating $FriendlyName.." "Updating $FriendlyName..." "$FriendlyName is now updating!" "Done" )
    for i in {1..5}; do
    sleep 2
    echo XXX
    echo $(( i * 20 ))
    echo ${msgs[i-1]}
    echo XXX
    done |whiptail --gauge "Please wait while the server is starting update" 6 60 0
}

# API call to request server start and then wait 10 seconds
function ServerStart {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    while true; do
        GetFriendlyName
        GetServerState
        if [ $ServerState = "ONLINE" ] || [ $ServerState = "starting" ]; then
            break
        fi
        curl "$HOST/api/client/servers/$n/power" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -H 'Authorization: Bearer '$APIKEY'' \
            -X POST \
            -d '{
        "signal": "start"
        }'
        msgs=( "Starting $FriendlyName." "Starting $FriendlyName.." "Starting $FriendlyName..." "$FriendlyName is almost ready!" "Done" )
        for i in {1..5}; do
        sleep 2
        echo XXX
        echo $(( i * 20 ))
        echo ${msgs[i-1]}
        echo XXX
        done |whiptail --gauge "Please wait while the server is starting" 6 60 0
        break
    done
}

# API call to request server stop and wait 10 seconds
function ServerStop {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    while true; do
        GetServerState
        GetFriendlyName
        if [ $ServerState = "OFFLINE" ] || [ $ServerState = "stopping" ]; then
            break
        fi
        curl "$HOST/api/client/servers/$n/power" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -H 'Authorization: Bearer '$APIKEY'' \
            -X POST \
            -d '{
        "signal": "stop"
        }'
        msgs=( "Stopping $FriendlyName." "Stopping $FriendlyName.." "Stopping $FriendlyName..." "$FriendlyName is shutting down!" "Done" )
        for i in {1..5}; do
        sleep 2
        echo XXX
        echo $(( i * 20 ))
        echo ${msgs[i-1]}
        echo XXX
        done |whiptail --gauge "Please wait while the server is shutting down" 6 60 0
        break
    done
}

# API call to request server restart and wait 10 seconds
function ServerRestart {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    while true; do
        GetFriendlyName
        GetServerState
        if [ $ServerState = "OFFLINE" ] || [ $ServerState = "stopping" ]; then
            break
        fi
        curl "$HOST/api/client/servers/$n/power" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -H 'Authorization: Bearer '$APIKEY'' \
            -X POST \
            -d '{
        "signal": "restart"
        }'
        msgs=( "Restarting $FriendlyName." "Restarting $FriendlyName.." "Restarting $FriendlyName..." "$FriendlyName is restarting!" "Done" )
        for i in {1..5}; do
        sleep 2
        echo XXX
        echo $(( i * 20 ))
        echo ${msgs[i-1]}
        echo XXX
        done |whiptail --gauge "Please wait while the server is restarting" 6 60 0
        break
    done
}

# API call to request server backup and wait 10 seconds
function Backup {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    GetFriendlyName
    GetBackupLimit
    GetBackupCount
    if [[ "$BackupCount" -eq "$BackupLimit" ]]; then
        echo "Reached backup limit on $FriendlyName, removing oldest"
        BackupRemoveOldest
        curl -s "$HOST/api/client/servers/$n/backups" > /dev/null \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$APIKEY'' \
        -X POST
        msgs=( "Backing up $FriendlyName." "Backing up $FriendlyName.." "Backing up $FriendlyName..." "$FriendlyName is backing up!" "Done" )
            for i in {1..5}; do
            sleep 2
            echo XXX
            echo $(( i * 20 ))
            echo ${msgs[i-1]}
            echo XXX
            done |whiptail --gauge "Please wait while the server starts backup" 6 60 0
    elif [[ "$BackupCount" -gt "$BackupLimit" ]]; then
        echo "It appears you have more backups on $FriendlyName than your server allows for. Removing oldest backups before attempting a new one."
        while true; do
            BackupRemoveOldest
            GetBackupCount
            if [[ "$BackupCount" -gt "$((BackupLimit-1))" ]]; then
                continue
            else
                break
            fi
        done
        echo "Extra backups removed. Starting new backup!"
        curl -s "$HOST/api/client/servers/$n/backups" > /dev/null \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$APIKEY'' \
        -X POST
        msgs=( "Backing up $FriendlyName." "Backing up $FriendlyName.." "Backing up $FriendlyName..." "$FriendlyName is backing up!" "Done" )
            for i in {1..5}; do
            sleep 2
            echo XXX
            echo $(( i * 20 ))
            echo ${msgs[i-1]}
            echo XXX
            done |whiptail --gauge "Please wait while the server starts backup" 6 60 0
    else
        curl -s "$HOST/api/client/servers/$n/backups" > /dev/null \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$APIKEY'' \
        -X POST
        msgs=( "Backing up $FriendlyName." "Backing up $FriendlyName.." "Backing up $FriendlyName..." "$FriendlyName is backing up!" "Done" )
            for i in {1..5}; do
            sleep 2
            echo XXX
            echo $(( i * 20 ))
            echo ${msgs[i-1]}
            echo XXX
            done |whiptail --gauge "Please wait while the server starts backup" 6 60 0
    fi
}

# API calls that updates the variables (Whitelist, Current Version, and Player Count) for the snapshot server
function SnapshotVariableChange {
     LATEST_VERSION=`curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.snapshot'` > /dev/null
     LATEST_RELEASE=`curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release'` > /dev/null
     clear
     msgs=( "Updating variables." "Updating variables.." "Updating variables..." "Variables updated" "Done" )
     for i in {1..5}; do
     sleep 2
     echo XXX
     echo $(( i * 20 ))
     echo ${msgs[i-1]}
     echo XXX
     done |whiptail --gauge "Please wait while the server variables update" 6 60 0
     if [ "$LATEST_VERSION" == "$LATEST_RELEASE" ]; then
     echo "There is not currently a snapshot build. Whitelisting the server"
     curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "WHITELIST",
      "value": "true"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "CURRENT_VERSION",
      "value": "CLOSED // NO SNAPSHOT"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "PLAYER_COUNT",
      "value": "0"
    }'

    else
    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "WHITELIST",
      "value": "false"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "CURRENT_VERSION",
      "value": "'"$LATEST_VERSION"'"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -d '{
      "key": "PLAYER_COUNT",
      "value": "10"
    }'
    fi
}

# API call that sends a message on the server and waits 5 seconds
function AnnounceMessage {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    while true; do
        GetFriendlyName
        GetServerState
        if [ $ServerState = "OFFLINE" ] || [ $ServerState = "stopping" ]; then
            break
        fi
        curl -s "$HOST/api/client/servers/$n/command" > /dev/null \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$APIKEY' ' \
        -X POST \
        -d '{
        "command": "say '"$ANNOUNCE_MESSAGE"'"
    }'
        msgs=( "Sending message on $FriendlyName." "Sending message on $FriendlyName.." "Sending message on $FriendlyName..." "Message has been sent to $FriendlyName" "Done" )
        for i in {1..5}; do
        sleep 1
        echo XXX
        echo $(( i * 20 ))
        echo ${msgs[i-1]}
        echo XXX
        done |whiptail --gauge "Please wait while the server announces your message" 6 65 0
        break
    done
}

# API call that sends a message to announce when it's updating and waits 5 seconds
function AnnounceDowntimeUpdate {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    while true; do
        GetFriendlyName
        GetServerState
        if [ $ServerState = "OFFLINE" ] || [ $ServerState = "stopping" ]; then
            break
        fi
        curl -s "$HOST/api/client/servers/$n/command" > /dev/null \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$APIKEY'' \
        -X POST \
        -d '{
        "command": "say This server is going down momentarily to update. This process is automated, and is expected to take around 5 minutes to complete."
    }'
        msgs=( "Sending message on $FriendlyName." "Sending message on $FriendlyName.." "Sending message on $FriendlyName..." "Message has been sent to $FriendlyName" "Done" )
        for i in {1..5}; do
        sleep 1
        echo XXX
        echo $(( i * 20 ))
        echo ${msgs[i-1]}
        echo XXX
        done |whiptail --gauge "Please wait while the server announces the default message" 6 65 0
        break
    done
}

function BackupRemoveOldest {
    CheckBackupForLock 0
    if [[ "$BackupLockStatus" == true ]]; then
        echo "Oldest backup is locked. Searching for oldest unlocked backup..."
        BackupLoopCount=1
        GetBackupLimit
        GetFriendlyName
        while true; do
            CheckBackupForLock $BackupLoopCount
            if [[ "$BackupLockStatus" == false ]]; then
                GetBackupLimit    
                echo "Found unlocked backup ${BackupList[$BackupLoopCount]}"
                break
            elif [[ "$BackupLoopCount" == "$BackupLimit" ]]; then
                echo "There are no unlocked backup slots left on $FriendlyName. Please unlock one and try again."
                exit
            else
                let BackupLoopCount++
                continue
            fi
        done
    fi
    echo "Removing Backup: ${BackupList[$BackupLoopCount]}"
    curl -s "$HOST/api/client/servers/$n/backups/${BackupList[$BackupLoopCount]}" > /dev/null \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X DELETE
}

function GetBackupList {
    BackupList=()
    BackupList=($( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.data[].attributes' | jq -r '.uuid'
     )
    )
}

function CheckBackupForLock {
    GetBackupList
    BackupLockStatus=$( curl -s "$HOST/api/client/servers/$n/backups/${BackupList[$1]}" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.is_locked'
     )
    
}

function GetFailedBackup {
    # Pulls the UUID of any backup(s) that has the key is_successful = false 
    FailedBackup=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r ".data[].attributes | select((.uuid) and .is_successful=="false")" | jq -r '.uuid'
     )
}

function DeleteFailedBackup {
    GetFailedBackup
    # This uses the first 36 characters of the FailedBackup list to ensure that only one is fed through at a time
    curl -s "$HOST/api/client/servers/$n/backups/${FailedBackup:0:36}" > /dev/null \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X DELETE
}

function HandleFailedBackup {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    GetFriendlyName
    GetFailedBackup
    # If there's no failed backups, we don't have to do anything :D
     if [ ${#FailedBackup} = 0 ]; then
        echo "There doesn't appear to be any failed backups on $FriendlyName"
    # If there's only one failed backup, we can just proceed like normal, just delete it and attempt a new one
     elif [ ${#FailedBackup} = 36 ]; then
        echo "Found failed backup on $FriendlyName | Backup: $FailedBackup"
        DeleteFailedBackup
        echo "Failed Backup: $FailedBackup removed, starting new backup attempt on $FriendlyName"
        sleep 2
        Backup
        BEGIN=$(date +%s)
        BACK="\b\b\b\b"
        # This loop checks if the backup has completed before moving on to the next server to check. This helps ensure that it doesn't fail again
        # It also includes a stopwatch to show how long the current process has been running
        while true; do
            NOW=$(date +%s)
            let DIFF=$(($NOW - $BEGIN))
            let MINS=$(($DIFF / 60))
            let SECS=$(($DIFF % 60))
            GetBackupStatus
            if [ "$BackupStatus" = "null" ]; then
            echo -ne "Please wait while $FriendlyName backs up. Time Elapsed: $MINS:`printf %02d $SECS`"\\r
            else
            echo -ne "$FriendlyName has completed it's backup in $(DisplayTime $DIFF)"\\n
            sleep 1
            break
            fi
        done
    # If there's more than 36 characters in the string, then there's multiple failed backups, and we need to handle it differently
     elif [ ${#FailedBackup} > 36 ]; then
        echo "Found multiple failed backups on $FriendlyName"
        # This loop deletes every failed backup except the last without attempting a new backup. Once the string is equal to 36 characters \
        # you know you're on your last failed backup, so the loop breaks. 
        while true; do
            DeleteFailedBackup
            echo "Failed Backup: ${FailedBackup:0:36} removed, checking if there are more failed backups before starting new attempt"
            sleep 1
            GetFailedBackup
            if [ ${#FailedBackup} = 36 ]; then
                break
            else   
                continue
            fi
        done
        # Once the loop breaks, the user is notified that this is the last one, and then we attempt a new backup
        DeleteFailedBackup
        echo "Failed Backup: $FailedBackup removed, this is the last one, attempting new backup"
        sleep 2
        Backup
        BEGIN=$(date +%s)
        BACK="\b\b\b\b"
        # This loop checks if the backup has completed before moving on to the next server to check. This helps ensure that it doesn't fail again
        # It also includes a stopwatch to show how long the current process has been running
        while true; do
            NOW=$(date +%s)
            let DIFF=$(($NOW - $BEGIN))
            let MINS=$(($DIFF / 60))
            let SECS=$(($DIFF % 60))
            GetBackupStatus
            if [ "$BackupStatus" = "null" ]; then
            echo -ne "Please wait while $FriendlyName backs up. Time Elapsed: $MINS:`printf %02d $SECS`"\\r
            else
            echo -ne "$FriendlyName has completed it's backup in $(DisplayTime $DIFF)"\\n
            sleep 1
            break
            fi
        done
     fi
}

function GetLatestBackupUUID {
    LatestBackupUUID=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.data[].attributes' | jq -r '.uuid'
     )
     LatestBackupUUID="${LatestBackupUUID: -36}"

}

function GetBackupStatus {
    GetLatestBackupUUID
    BackupStatus=$( curl -s "$HOST/api/client/servers/$n/backups/$LatestBackupUUID" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.completed_at'
     )
    
}

function GetFriendlyName {
     FriendlyName=$( curl -s "$HOST/api/client/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.name'
    )
}

function GetFriendlyNameByID {
     FriendlyName=$( curl -s "$HOST/api/application/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$applicationKey'' \
     -X GET | jq -r '.attributes' | jq -r '.name'
    )
}

function GetLastBackup {
    # Pulls the current time
    Now=$(date)
    # Pulls the last backups time using jq to filter down to the last 36 characters of the created_at list
    LastBackup=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.data[].attributes' | jq -r '.completed_at'
     )
     # Convert now to seconds
     SecondsNow=$(date -d"$Now" +%s)
     # Convert lastbackup to seconds
     LastBackup=$(date -d"${LastBackup: -25}" +%s 2> /dev/null)
     LastBackupString=$LastBackup
     LastBackup=$((SecondsNow - LastBackup))
 
}

function GetLastUsed {
    GetFriendlyName
    GetMCWorld
    Now=$(date)
    LastUsed=$( curl -s "$HOST/api/client/servers/$n/files/list?directory=$MCWorld" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.data[].attributes | select(.name=="playerdata")' | jq -r '.modified_at'
     )
     # Convert now to seconds
     SecondsNow=$(date -d"$Now" +%s)
     # Convert LastUsed to seconds
     SecondsLastUsed=$(date -d"$LastUsed" +%s 2> /dev/null)
     # Calculate and store the difference
     LastUsed=$((SecondsNow - SecondsLastUsed))
}

function GetLastPlayerUsed {
    GetFriendlyName
    LastPlayerUsed=$( curl -s "$HOST/api/client/servers/$n/files/contents?file=%2Fusercache.json" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.[0].name'
     )
    
}

function GetServerStatus {
    GetFriendlyName
    GetSuspensionStatus  
    if [ "$SuspensionStatus" = "true" ]; then
        echo "$FriendlyName | Suspended"
    else
        GetLastBackup
        GetLastUsed
        GetLastPlayerUsed
        GetServerState
        LastUsedDifference=$(DisplayTime $LastUsed)
        LastBackupDifference=$(DisplayTime $LastBackup)
        if [ ${#LastBackupString} = 0 ]; then
            if [ $LastUsed -gt 300 ]; then
                echo "$FriendlyName | $ServerState | Last Used: $LastUsedDifference ago | Last Player: $LastPlayerUsed | Backup In Progress"
            else
                echo "$FriendlyName | $ServerState | In Use | Current Player: $LastPlayerUsed | Backup In Progress"
            fi
        else
            if [ $LastUsed -gt 300 ]; then
                echo "$FriendlyName | $ServerState | Last Used: $LastUsedDifference ago | Last Player: $LastPlayerUsed | Last Backup: $LastBackupDifference ago"
            else
                echo "$FriendlyName | $ServerState | In Use | Current Player: $LastPlayerUsed | Last Backup: $LastBackupDifference ago"
            fi
        fi
    fi
}

# Converts seconds to time
function DisplayTime {
  local T=$1
  local MM=$((T/60/60/24/30))
  local D=$((T/60/60/24%30))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $MM > 0 )) && printf '%d months ' $MM
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $MM > 0 || $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S

}

function GetBackupLimit {
    BackupLimit=$( curl -s "$HOST/api/client/servers/$n/" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.feature_limits' | jq -r '.backups'
     )
}

# API GET List Backups and use JQ to pull object total to set that as BackupCount
function GetBackupCount {
     BackupCount=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.meta' | jq -r '.pagination' | jq -r '.total' 
     )
}

# Calls the server details list with egg parameter and filters it down to the egg name with JQ
function GetServerEgg {
    ServerEgg=$( curl -s "$HOST/api/client/servers/$n?include=egg" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.relationships' | jq -r '.egg' | jq -r '.attributes' | jq -r '.name'
     )
}

function GetMCWorld {
    MCWorld=$( curl -s "$HOST/api/client/servers/$n/files/contents?file=server.properties" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET  | grep -w "level-name"
     )
    MCWorld=${MCWorld:11}
}

function DowntimePrompt {
    whiptail --title "$companyName" --yesno "Do you want to announce a custom downtime message?" --defaultno 8 78 
}

function DowntimeMessageInput {
    ANNOUNCE_MESSAGE=$(whiptail --inputbox "What would you like your message to be?" 8 78 3>&1 1>&2 2>&3)
}

function CheckServerInstallStatus {
    InstallStatus=$( curl -s "$HOST/api/client/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.is_installing'
     )
}

function ServerInstallWait {
    for i in {1..50}; do
                CheckServerInstallStatus
                if [ $InstallStatus == "false" ]; then
                    break
                fi
                sleep 1.5
                echo XXX
                echo $(( i * 2 ))
                echo "Please wait while the servers install"
                echo XXX
        done |whiptail --gauge "Please wait while the servers install" 6 60 0
}

function ServerStartWait {
    for i in {1..50}; do
                GetServerState
                if [ $ServerState == "ONLINE" ]; then
                    break
                fi
                sleep 1.5
                echo XXX
                echo $(( i * 2 ))
                echo "Please wait while the servers start"
                echo XXX
        done |whiptail --gauge "Please wait while the servers start" 6 60 0
}

function ServerInstallBuffer {
    for i in {1..20}; do
                sleep 1
                echo XXX
                echo $(( i * 5 ))
                echo "Please wait for the server installation to begin"
                echo XXX
            done |whiptail --gauge "Please wait for the server installation to begin" 6 60 0
}

function GetServerState {
    ServerState=$( curl -s "$HOST/api/client/servers/$n/resources" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.current_state'
     )
     if [ "$ServerState" = "offline" ]; then
        ServerState="OFFLINE"
     elif [ "$ServerState" = "running" ]; then
        ServerState="ONLINE"
     elif [ "$ServerState" = "starting" ]; then
        ServerState="STARTING"
     fi
}

function GetSuspensionStatus {
    SuspensionStatus==$( curl -s "$HOST/api/client/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET | jq -r '.attributes' | jq -r '.is_suspended'
     )
     if [ "$SuspensionStatus" = "=false" ]; then
        SuspensionStatus="false"
     elif [ "$SuspensionStatus" = "=true" ]; then
        SuspensionStatus="true"
     fi
}

function GetSuspensionStatusByID {
    SuspensionStatus==$( curl -s "$HOST/api/application/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$applicationKey'' \
     -X GET | jq -r '.attributes' | jq -r '.suspended'
     )
     if [ "$SuspensionStatus" = "=false" ]; then
        SuspensionStatus="false"
     elif [ "$SuspensionStatus" = "=true" ]; then
        SuspensionStatus="true"
     fi
} 

function GetAllServers {
    AllServers=()
    AllServers=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r .data[].attributes | jq -r '.uuid')
    )
}

function GetAllServersByID {
    AllServersByID=()
    AllServersByID=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r .data[].attributes | jq -r '.id')
    )
}

function GetAllNodes {
    AllNodes=()
    AllNodes=($( curl -s "$HOST/api/application/nodes" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET \
    -b 'pterodactyl_session'='eyJpdiI6InhIVXp5ZE43WlMxUU1NQ1pyNWRFa1E9PSIsInZhbHVlIjoiQTNpcE9JV3FlcmZ6Ym9vS0dBTmxXMGtST2xyTFJvVEM5NWVWbVFJSnV6S1dwcTVGWHBhZzdjMHpkN0RNdDVkQiIsIm1hYyI6IjAxYTI5NDY1OWMzNDJlZWU2OTc3ZDYxYzIyMzlhZTFiYWY1ZjgwMjAwZjY3MDU4ZDYwMzhjOTRmYjMzNDliN2YifQ%3D%3D' | jq -r .data[].attributes | jq -r '.id')
    )
}

# Pulls every server associated with the node you pass through
function GetAllServersByNode {
    AllServersByNode=()
    AllServersByNode=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r ".data[].attributes | select(.node=="$1")" | jq -r '.uuid')
    )
}

function GetPaperServers {
    PaperServers=()
    PaperServers=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r ".data[].attributes | select(.egg=="$paperEggID")" | jq -r '.uuid')
    )
}

function GetSnapshotServers {
    SnapshotServers=()
    SnapshotServers=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r ".data[].attributes | select(.egg=="$snapshotEggID")" | jq -r '.uuid')
    )
}

function GetPaperGeyserServers {
    PaperGeyserServers=()
    PaperGeyserServers=($( curl -s "$HOST/api/application/servers" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r ".data[].attributes | select(.egg=="$paperGeyserEggID")" | jq -r '.uuid')
    )
}

function GetFriendlyNodeName {
    FriendlyNodeName=$( curl -s "$HOST/api/application/nodes/$n" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$applicationKey'' \
    -X GET | jq -r '.attributes' | jq -r '.name'
    )
}

function GetAllUpdateServers {
    GetPaperServers
    GetPaperGeyserServers
    GetSnapshotServers
    AllUpdateServers=()
    AllUpdateServers+=(${PaperServers[@]})
    AllUpdateServers+=(${PaperGeyserServers[@]})
    AllUpdateServers+=(${SnapshotServers[@]})
}

function SuspensionToggle {
    GetSuspensionStatusByID
    GetFriendlyNameByID
    if [ "$SuspensionStatus" = "true" ]; then
        echo "Unsuspending $FriendlyName"
        curl -s "$HOST/api/application/servers/$n/unsuspend" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$applicationKey'' \
        -X POST
    else
        echo "Suspending $FriendlyName"
        curl -s "$HOST/api/application/servers/$n/suspend" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '$applicationKey'' \
        -X POST
    fi

}

# Menu
choice=$(whiptail --title "$companyName Management Tool v4.1" --fb --menu "Select an option" 18 100 10 \
    "1." "Update" \
    "2." "Start" \
    "3." "Stop" \
    "4." "Restart" \
    "5." "Start All" \
    "6." "Stop All" \
    "7." "Restart All" \
    "8." "Backup" \
    "9." "Send Message" \
    "10." "Check for Failed Backups" \
    "11." "Toggle Suspensions" \
    "12." "Check Server Status" \
    "13." "Exit" 3>&1 1>&2 2>&3)

case $choice in
    1.)
        # Update
        Update=$(whiptail --title "$companyName" --radiolist "Which servers would you like to update?" --separate-output 20 78 4 \
        "1." "Paper Servers" OFF \
        "2." "Paper + Geyser Servers" OFF \
        "3." "Snapshot Server" OFF \
        "4." "All Servers" OFF 3>&1 1>&2 2>&3)
        case $Update in
            1.)
                # Paper Server Update
                GetPaperServers
                clear
                echo "Starting update on all Paper based servers..."
                for n in "${PaperServers[@]}"; do
                AnnounceDowntimeUpdate; done
                ServerInstallBuffer
                clear
                for n in "${PaperServers[@]}"; do
                ServerInstall; done
                for n in "${PaperServers[@]}"; do
                ServerInstallWait; done
                clear
                for n in "${RunningServers[@]}"; do
                ServerStart; done

            ;;
            2.)
                # Paper + Geyser Server Update
                GetPaperGeyserServers
                clear
                echo "Starting update on all Paper + Geyser based servers..."
                for n in "${PaperGeyserServers[@]}"; do
                AnnounceDowntimeUpdate; done
                ServerInstallBuffer
                clear
                for n in "${PaperGeyserServers[@]}"; do
                ServerInstall; done
                for n in "${PaperGeyserServers[@]}"; do
                ServerInstallWait; done
                clear
                for n in "${RunningServers[@]}"; do
                ServerStart; done
                
            ;;
            3.)
                # Snapshot Server Update
                GetSnapshotServers
                clear
                for n in "${SnapshotServers[@]}"; do
                AnnounceDowntimeUpdate; done
                ServerInstallBuffer
                clear
                for n in "${SnapshotServers[@]}"; do
                SnapshotVariableChange; done
                for n in "${SnapshotServers[@]}"; do
                ServerInstall; done
                for n in "${SnapshotServers[@]}"; do
                ServerInstallWait; done
                clear
                for n in "${RunningServers[@]}"; do
                ServerStart; done
            ;;
            4.)
                # All Server Update
                GetAllUpdateServers
                clear
                for n in "${AllUpdateServers[@]}"; do
                AnnounceDowntimeUpdate; done
                ServerInstallBuffer
                clear
                for n in "${SnapshotServers[@]}"; do
                SnapshotVariableChange; done
                echo "Starting update on all Servers..."
                for n in "${AllUpdateServers[@]}"; do
                ServerInstall; done
                for n in "${AllUpdateServers[@]}"; do
                ServerInstallWait; done
                clear
                for n in "${RunningServers[@]}"; do
                ServerStart; done
            ;;
        esac
    ;;
    2.)
        # Start
        declare -a args=(
                --title "$companyName" \
                --checklist "Which servers would you like to start?" --separate-output 20 78 4 \
        )
        GetAllServers
        for n in "${AllServers[@]}"; do
                GetFriendlyName
                args+=("$n" "$FriendlyName" '\')
        done
        Start=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        StartArray=($Start)
        clear
        echo -e "Starting selected servers..."
        for n in "${StartArray[@]}"
        do
        ServerStart
        done
    ;;
    3.)
        # Stop
        declare -a args=(
                --title "$companyName" \
                --checklist "Which servers would you like to stop?" --separate-output 20 78 4 \
        )
        GetAllServers
        for n in "${AllServers[@]}"; do
                GetFriendlyName
                args+=("$n" "$FriendlyName" '\')
        done
        Stop=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        StopArray=($Stop)
        clear
        if DowntimePrompt; then
            clear
            ANNOUNCE_MESSAGE=$(whiptail --inputbox "What would you like your message to be?" 8 78 3>&1 1>&2 2>&3)
            for n in "${StopArray[@]}"
            do
            AnnounceMessage
            done
            clear
            echo "Making sure selected servers are turned off..."
            for n in "${StopArray[@]}"
            do
            ServerStop
            done
            clear
            echo "Selected servers have been stopped successfully"
        else
            clear
            for n in "${StopArray[@]}"
            do
            AnnounceMessage
            done
            clear
            echo "Making sure selected servers are turned off..."
            for n in "${StopArray[@]}"
            do
            ServerStop
            done
            clear
            echo "Selected servers have been stopped successfully"
        fi
    ;;
    4.)
        # Restart
        declare -a args=(
                --title "$companyName" \
                --checklist "Which servers would you like to restart?" --separate-output 20 78 4 \
        )
        GetAllServers
        for n in "${AllServers[@]}"; do
                GetFriendlyName
                args+=("$n" "$FriendlyName" '\')
        done
        Restart=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        RestartArray=($Restart)
        clear
        if DowntimePrompt; then
            clear
            ANNOUNCE_MESSAGE=$(whiptail --inputbox "What would you like your message to be?" 8 78 3>&1 1>&2 2>&3)
            for n in "${RestartArray[@]}"
            do
            AnnounceMessage
            done
            clear
            echo "Restarting selected servers..."
            for n in "${RestartArray[@]}"
            do
            ServerRestart
            done
            clear
            echo "Selected servers have been restarted successfully"
        else
            clear
            for n in "${RestartArray[@]}"
            do
            AnnounceMessage
            done
            clear
            echo "Restarting selected servers..."
            for n in "${RestartArray[@]}"
            do
            ServerRestart
            done
            clear
            echo "Selected servers have been restarted successfully"
        fi
    ;;
    5.)
        # Start All
        clear
        declare -a args=(
                --title "$companyName" \
                --checklist "Which node would you like to start?" --separate-output 20 78 4 \
        )
        GetAllNodes
        for n in "${AllNodes[@]}"; do
                GetFriendlyNodeName
                args+=("$n" "$FriendlyNodeName" '\')
        done
        NodeStart=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        NodeStartArray=($NodeStart)
        for NodeStart in "${NodeStartArray[@]}"; do
            GetAllServersByNode $NodeStart
            for n in "${AllServersByNode[@]}"; do
            ServerStart; done
            clear
            echo "Starting all servers on Node $NodeStart"
        done
        if [ "${#NodeStartArray[@]}" -gt 1 ]; then
            echo "All servers have been started on selected nodes"
        else
            echo "All servers have been started on Node $NodeStart"
        fi
    ;;
    6.)
        # Stop All
        clear
        declare -a args=(
                --title "$companyName" \
                --checklist "Which node would you like to stop?" --separate-output 20 78 4 \
        )
        GetAllNodes
        for n in "${AllNodes[@]}"; do
                GetFriendlyNodeName
                args+=("$n" "$FriendlyNodeName" '\')
        done
        NodeStop=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        NodeStopArray=($NodeStop)
        if DowntimePrompt; then
            DowntimeMessageInput
        fi
        for NodeStop in "${NodeStopArray[@]}"; do
            GetAllServersByNode $NodeStop
            for n in "${AllServersByNode[@]}"; do
            AnnounceMessage; done
            for n in "${AllServersByNode[@]}"; do
            ServerStop; done
            clear
            echo "Stopping all servers on Node $NodeStop"
        done
        if [ "${#NodeStopArray[@]}" -gt 1 ]; then
            echo "All servers have been stopped on selected nodes"
        else
            echo "All servers have been stopped on Node $NodeStop"
        fi
    ;;
    7.)
        # Restart All
        clear
        declare -a args=(
                --title "$companyName" \
                --checklist "Which node would you like to restart?" --separate-output 20 78 4 \
        )
        GetAllNodes
        for n in "${AllNodes[@]}"; do
                GetFriendlyNodeName
                args+=("$n" "$FriendlyNodeName" '\')
        done
        NodeRestart=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        NodeRestartArray=($NodeRestart)
        if DowntimePrompt; then
            DowntimeMessageInput
        fi
        for NodeRestart in "${NodeRestartArray[@]}"; do
            GetAllServersByNode $NodeRestart
            for n in "${AllServersByNode[@]}"; do
            AnnounceMessage; done
            for n in "${AllServersByNode[@]}"; do
            ServerRestart; done
            clear
            echo "Restarting all servers on Node $NodeRestart"
        done
        if [ "${#NodeRestartArray[@]}" -gt 1 ]; then
            echo "All servers have been restarted on selected nodes"
        else
            echo "All servers have been restarted on Node $NodeRestart"
        fi
    ;;
    8.)
        # Backup
        if (whiptail --title "Warning" --yesno "Backing up takes up considerable resources and may cause lag. Are you sure you want to continue?" 8 78); then
            ANNOUNCE_MESSAGE="This server is starting a backup that may cause small occasional lag spikes. This process is automated and is estimated to take around 20 minutes with no downtime expected."
            declare -a args=(
                --title "$companyName" \
                --checklist "Which servers would you like to backup?" --separate-output 20 78 4 \
            )
            GetAllServers
            for n in "${AllServers[@]}"; do
                GetFriendlyName
                args+=("$n" "$FriendlyName" '\')
            done
            Backup=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
            BackupArray=($Backup)
            clear
            for n in "${BackupArray[@]}"
            do
            AnnounceMessage
            done
            clear
            for n in "${BackupArray[@]}"
            do
            Backup
            done
            clear
            echo "Selected servers have been backed up successfully"
        else
            clear
            exit
        fi
    ;;
    9.)
        # Send Message
        ANNOUNCE_MESSAGE=$(whiptail --inputbox "What would you like your message to be?" 8 78 3>&1 1>&2 2>&3)
        declare -a args=(
            --title "$companyName" \
            --checklist "Which servers would you like to send the message to?" --separate-output 20 78 4 \
        )
        GetAllServers
        for n in "${AllServers[@]}"; do
            GetFriendlyName
            args+=("$n" "$FriendlyName" '\')
        done
        SendMessage=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        SendMessageArray=($SendMessage)
        clear
        for n in "${SendMessageArray[@]}"
        do
        AnnounceMessage
        done
    ;;
    10.)
        # Failed Backup Check
        GetAllServers
        clear
        if [ "${#AllServers[@]}" = 0 ]; then
            echo "There aren't yet any servers linked with this account."
        fi
        for n in "${AllServers[@]}";do
        HandleFailedBackup;done
    ;;
    11.)
        # Suspension Toggle
        declare -a args=(
                --title "$companyName" \
                --checklist "Which servers would you like to toggle their suspension status?" --separate-output 20 78 4 \
        )
        GetAllServersByID
        for n in "${AllServersByID[@]}"; do
                GetFriendlyNameByID
                args+=("$n" "$FriendlyName" '\')
        done
        Suspend=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3)
        SuspendArray=($Suspend)
        clear
        echo -e "Toggling suspension status on selected servers..."
        for n in "${SuspendArray[@]}"
        do
        SuspensionToggle
        done
    ;;
    12.)
        # Server Status
        GetAllServers
        clear
        if [ "${#AllServers[@]}" = 0 ]; then
            echo "There aren't yet any servers linked with this account."
        fi
        for n in "${AllServers[@]}"; do
        GetServerStatus; done
    ;;
    13.) # Exit
        exit
    ;;
esac