#!/bin/ash
# Server Management Tool for TheWrightServer
# Todo
# - Cancel in sub menu take you back to menu
# - Ask if user wants to update all before stopping servers
# - Dockerize
# - Add GUI to the new backup functions
# - Change Start/Restart/Stop All to a checklist instead of a radio list

HOST=$(jq -r '.host' config.json)
APIKEY=$(jq -r '.apikey' config.json)
ANNOUNCE_MESSAGE="This server is going down momentarily. This process is automated, and the server will be returning soon."
PASS=`echo "CXuTeSJ6rZN1cpYdn1WqmA=="  | openssl enc -base64 -d -aes-256-cbc -pbkdf2 -nosalt -pass pass:garbageKey`

# List of Servers running on the Paper egg
PaperServers=(
    '941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2' 
    'b20a74c4-0e64-4a51-af4d-2a964a41207b'
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
    '3c8b3001-1182-433f-8aec-af21a56b422c'
    'df35478a-b8d8-4c55-84cd-aef2e40893bf'
)

# List of Servers running on the Paper + Geyser egg
PaperGeyserServers=(
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
)

# List of Servers for Update ALL function
AllServers=(
    '941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2' 
    'b20a74c4-0e64-4a51-af4d-2a964a41207b'
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
    '9dfb8354-67a6-4a9e-9447-965c939e7ceb'
    '3c8b3001-1182-433f-8aec-af21a56b422c'
    'df35478a-b8d8-4c55-84cd-aef2e40893bf'
)

# List of Servers for the ALL Power / ALL Restart functions
AllAllServers=(
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    '941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
    'b20a74c4-0e64-4a51-af4d-2a964a41207b'
    '9dfb8354-67a6-4a9e-9447-965c939e7ceb'
    '29248816-96e7-4c20-ae88-5d8e90334f94'
    '2efe6e55-8b98-4cba-942a-564d584623ae'
    'c4fdb228-457d-4537-9200-f6ba33bb8b5b'
    '699e30b5-e824-48a8-a0bc-41daf9e7f50e'
    'bf8e8bc0-de79-456d-9bde-8a72274c1785'
    '3c8b3001-1182-433f-8aec-af21a56b422c'
    'df35478a-b8d8-4c55-84cd-aef2e40893bf'
)

# List of Node 1 Servers
Node1Servers=(
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    'b20a74c4-0e64-4a51-af4d-2a964a41207b'
    '9dfb8354-67a6-4a9e-9447-965c939e7ceb'
)

# List of Node 2 Servers
Node2Servers=(
    '941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
    '29248816-96e7-4c20-ae88-5d8e90334f94'
    '2efe6e55-8b98-4cba-942a-564d584623ae'
    'c4fdb228-457d-4537-9200-f6ba33bb8b5b'
    '699e30b5-e824-48a8-a0bc-41daf9e7f50e'
    'bf8e8bc0-de79-456d-9bde-8a72274c1785'
    '3c8b3001-1182-433f-8aec-af21a56b422c'
    'df35478a-b8d8-4c55-84cd-aef2e40893bf'
)

# List of Snapshot Servers
SnapshotServers=(
    '9dfb8354-67a6-4a9e-9447-965c939e7ceb'
)

# List of Update-able Node 1 Servers
Node1UpdateServers=(
    '068416f4-ea04-4b41-8fe9-ecad94000059'
    '9dfb8354-67a6-4a9e-9447-965c939e7ceb'
    'b20a74c4-0e64-4a51-af4d-2a964a41207b'
)

# List of Update-able Node 2 Servers
Node2UpdateServers=(
    '941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2'
    '0de1c057-d48c-45f5-9280-849aa664c92a'
    '3c8b3001-1182-433f-8aec-af21a56b422c'
    'df35478a-b8d8-4c55-84cd-aef2e40893bf'
)

# API call to request server install and then wait 10 seconds
function ServerInstall {
    GetSuspensionStatus
    if [ "$SuspensionStatus" = "true" ]; then
        return
    fi
    GetFriendlyName
    GetServerState 
    if [ $ServerState = "OFFLINE" ]; then
        StoppedServers+=("$n")
    fi
    curl -s "$HOST/api/client/servers/$n/settings/reinstall" > /dev/null \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer '$APIKEY'' \
  -X POST \
  -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' 
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
            -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
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
            -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
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
            -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
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
        -X POST \
        -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' 
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
        -X POST \
        -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' 
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
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
      -d '{
      "key": "WHITELIST",
      "value": "true"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
      -d '{
      "key": "CURRENT_VERSION",
      "value": "CLOSED // NO SNAPSHOT"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
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
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
      -d '{
      "key": "WHITELIST",
      "value": "false"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
      -d '{
      "key": "CURRENT_VERSION",
      "value": "'"$LATEST_VERSION"'"
    }'

    curl -s "$HOST/api/client/servers/$n/startup/variable" > /dev/null \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer '$APIKEY'' \
      -X PUT \
      -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' \
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
    # API GET List Backups and use JQ to pull UUIDs of all the backups and then use variable filtering to remove the first (and therefore oldest) backup
    OldestBackup=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.data[].attributes' | jq -r '.uuid'
     )
    echo  Removing Backup: ${OldestBackup:0:36}
    curl -s "$HOST/api/client/servers/$n/backups/${OldestBackup:0:36}" > /dev/null \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X DELETE \
    -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D'
}

function GetFailedBackup {
    # Pulls the UUID of any backup(s) that has the key is_successful = false 
    FailedBackup=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r ".data[].attributes | select((.uuid) and .is_successful=="false")" | jq -r '.uuid'
     )
}

function DeleteFailedBackup {
    GetFailedBackup
    # This uses the first 36 characters of the FailedBackup list to ensure that only one is fed through at a time
    curl -s "$HOST/api/client/servers/$n/backups/${FailedBackup:0:36}" > /dev/null \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X DELETE \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.data[].attributes' | jq -r '.uuid'
     )
     LatestBackupUUID="${LatestBackupUUID: -36}"

}

function GetBackupStatus {
    GetLatestBackupUUID
    BackupStatus=$( curl -s "$HOST/api/client/servers/$n/backups/$LatestBackupUUID" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.completed_at'
     )
    
}

function GetFriendlyName {
     FriendlyName=$( curl -s "$HOST/api/client/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.name'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.data[].attributes' | jq -r '.completed_at'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.data[].attributes | select(.name=="playerdata")' | jq -r '.modified_at'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.[0].name'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.feature_limits' | jq -r '.backups'
     )
}

# API GET List Backups and use JQ to pull object total to set that as BackupCount
function GetBackupCount {
     BackupCount=$( curl -s "$HOST/api/client/servers/$n/backups" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.meta' | jq -r '.pagination' | jq -r '.total' 
     )
}

# Calls the server details list with egg parameter and filters it down to the egg name with JQ
function GetServerEgg {
    ServerEgg=$( curl -s "$HOST/api/client/servers/$n?include=egg" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.relationships' | jq -r '.egg' | jq -r '.attributes' | jq -r '.name'
     )
}

function GetMCWorld {
    MCWorld=$( curl -s "$HOST/api/client/servers/$n/files/contents?file=server.properties" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | grep -w "level-name"
     )
    MCWorld=${MCWorld:11}
}

function DowntimePrompt {
    whiptail --title "TheWrightServer" --yesno "Do you want to announce a custom downtime message?" --defaultno 8 78 
}

function DowntimeMessageInput {
    ANNOUNCE_MESSAGE=$(whiptail --inputbox "What would you like your message to be?" 8 78 3>&1 1>&2 2>&3)
}

function CheckServerInstallStatus {
    InstallStatus=$( curl -s "$HOST/api/client/servers/$n" \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$APIKEY'' \
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.is_installing'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.current_state'
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
     -X GET \
     -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D' | jq -r '.attributes' | jq -r '.is_suspended'
     )
     if [ "$SuspensionStatus" = "=false" ]; then
        SuspensionStatus="false"
     elif [ "$SuspensionStatus" = "=true" ]; then
        SuspensionStatus="true"
     fi
} 

function GetAllServers {
    curl -s "$HOST/api/client/" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$APIKEY'' \
    -X GET \
    -b 'pterodactyl_session'='eyJpdiI6IndMaGxKL2ZXanVzTE9iaWhlcGxQQVE9PSIsInZhbHVlIjoib0ovR1hrQlVNQnI3bW9kbTN0Ni9Uc1VydnVZQnRWMy9QRnVuRFBLMWd3eFZhN2hIbjk1RXE0ZVdQdUQ3TllwcSIsIm1hYyI6IjQ2YjUzMGZmYmY1NjQ3MjhlN2FlMDU4ZGVkOTY5Y2Q4ZjQyMDQ1MWJmZTUxYjhiMDJkNzQzYmM3ZWMyZTMxMmUifQ%3D%3D'

}

# Menu
choice=$(whiptail --title "TheWrightServer Management Tool v3.16" --fb --menu "Select an option" 18 100 10 \
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
    "11." "Check Server Status" \
    "12." "Exit" 3>&1 1>&2 2>&3)

case $choice in
    1.)
        # Update
        Update=$(whiptail --title "TheWrightServer" --radiolist "Which servers would you like to update?" --separate-output 20 78 4 \
        "1." "Paper Servers" OFF \
        "2." "Paper + Geyser Servers" OFF \
        "3." "Snapshot Server" OFF \
        "4." "All Servers" OFF 3>&1 1>&2 2>&3)
        case $Update in
            1.)
                # Paper Server Update
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
                for n in "${PaperServers[@]}"; do
                ServerStart; done
                if [ ${#StoppedServers[@]} -gt 0 ]; then
                    for n in "${PaperServers[@]}"; do
                    ServerStartWait; done
                    for n in "${StoppedServers[@]}"; do
                    ServerStop; done
                fi
            ;;
            2.)
                # Paper + Geyser Server Update
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
                for n in "${PaperGeyserServers[@]}"; do
                ServerStart; done
                if [ ${#StoppedServers[@]} -gt 0 ]; then
                    for n in "${PaperGeyserServers[@]}"; do
                    ServerStartWait; done
                    for n in "${StoppedServers[@]}"; do
                    ServerStop; done
                fi
                
            ;;
            3.)
                # Snapshot Server Update
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
                for n in "${SnapshotServers[@]}"; do
                ServerStart; done
                if [ ${#StoppedServers[@]} -gt 0 ]; then
                    for n in "${SnapshotServers[@]}"; do
                    ServerStartWait; done
                    for n in "${StoppedServers[@]}"; do
                    ServerStop; done
                fi
            ;;
            4.)
                # All Server Update
                clear
                for n in "${AllServers[@]}"; do
                AnnounceDowntimeUpdate; done
                ServerInstallBuffer
                clear
                for n in "${SnapshotServers[@]}"; do
                SnapshotVariableChange; done
                echo "Starting update on all Servers..."
                for n in "${AllServers[@]}"; do
                ServerInstall; done
                for n in "${AllServers[@]}"; do
                ServerInstallWait; done
                clear
                for n in "${AllServers[@]}"; do
                ServerStart; done
                if [ ${#StoppedServers[@]} -gt 0 ]; then
                    for n in "${AllServers[@]}"; do
                    ServerStartWait; done
                    for n in "${StoppedServers[@]}"; do
                    ServerStop; done
                fi
            ;;
        esac
    ;;
    2.)

        # Start
        Start=$(whiptail --title "TheWrightServer" --checklist "Which servers would you like to start?" --separate-output 20 78 4 \
        "068416f4-ea04-4b41-8fe9-ecad94000059" "Legion for Vendetta" OFF \
        "b20a74c4-0e64-4a51-af4d-2a964a41207b" "The Homies" OFF \
        "9dfb8354-67a6-4a9e-9447-965c939e7ceb" "Snapshot" OFF \
        "29248816-96e7-4c20-ae88-5d8e90334f94" "Pixelmon Reforged" OFF \
        "2efe6e55-8b98-4cba-942a-564d584623ae" "Skyblock Randomizer" OFF \
        "c4fdb228-457d-4537-9200-f6ba33bb8b5b" "MineColonies" OFF \
        "699e30b5-e824-48a8-a0bc-41daf9e7f50e" "RAD" OFF \
        "941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2" "Survival" OFF \
        "0de1c057-d48c-45f5-9280-849aa664c92a" "Tomas" OFF \
        "bf8e8bc0-de79-456d-9bde-8a72274c1785" "Demon Slayers Unleashed" OFF \
        "3c8b3001-1182-433f-8aec-af21a56b422c" "Wittenberg XC" OFF \
        "df35478a-b8d8-4c55-84cd-aef2e40893bf" "Cribo" OFF \
        3>&1 1>&2 2>&3)
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
        Stop=$(whiptail --title "TheWrightServer" --checklist "Which servers would you like to stop?" --separate-output 20 78 4 \
        "068416f4-ea04-4b41-8fe9-ecad94000059" "Legion for Vendetta" OFF \
        "b20a74c4-0e64-4a51-af4d-2a964a41207b" "The Homies" OFF \
        "9dfb8354-67a6-4a9e-9447-965c939e7ceb" "Snapshot" OFF \
        "29248816-96e7-4c20-ae88-5d8e90334f94" "Pixelmon Reforged" OFF \
        "2efe6e55-8b98-4cba-942a-564d584623ae" "Skyblock Randomizer" OFF \
        "c4fdb228-457d-4537-9200-f6ba33bb8b5b" "MineColonies" OFF \
        "699e30b5-e824-48a8-a0bc-41daf9e7f50e" "RAD" OFF \
        "941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2" "Survival" OFF \
        "0de1c057-d48c-45f5-9280-849aa664c92a" "Tomas" OFF \
        "bf8e8bc0-de79-456d-9bde-8a72274c1785" "Demon Slayers Unleashed" OFF \
        "3c8b3001-1182-433f-8aec-af21a56b422c" "Wittenberg XC" OFF \
        "df35478a-b8d8-4c55-84cd-aef2e40893bf" "Cribo" OFF \
        3>&1 1>&2 2>&3)
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
        Restart=$(whiptail --title "TheWrightServer" --checklist "Which servers would you like to restart?" --separate-output 20 78 4 \
        "068416f4-ea04-4b41-8fe9-ecad94000059" "Legion for Vendetta" OFF \
        "b20a74c4-0e64-4a51-af4d-2a964a41207b" "The Homies" OFF \
        "9dfb8354-67a6-4a9e-9447-965c939e7ceb" "Snapshot" OFF \
        "29248816-96e7-4c20-ae88-5d8e90334f94" "Pixelmon Reforged" OFF \
        "2efe6e55-8b98-4cba-942a-564d584623ae" "Skyblock Randomizer" OFF \
        "c4fdb228-457d-4537-9200-f6ba33bb8b5b" "MineColonies" OFF \
        "699e30b5-e824-48a8-a0bc-41daf9e7f50e" "RAD" OFF \
        "941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2" "Survival" OFF \
        "0de1c057-d48c-45f5-9280-849aa664c92a" "Tomas" OFF \
        "bf8e8bc0-de79-456d-9bde-8a72274c1785" "Demon Slayers Unleashed" OFF \
        "3c8b3001-1182-433f-8aec-af21a56b422c" "Wittenberg XC" OFF \
        "df35478a-b8d8-4c55-84cd-aef2e40893bf" "Cribo" OFF \
        3>&1 1>&2 2>&3)
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
        NodeStart=$(whiptail --title "TheWrightServer" --checklist "Which node would you like to start?" --separate-output 20 78 4 \
        "1." "Node 1" OFF \
        "2." "Node 2" OFF \
        3>&1 1>&2 2>&3)
        NodeStartArray=($NodeStart)
        for NodeStart in "${NodeStartArray[@]}"; do
            case $NodeStart in
                1.)
                    # Node 1 Start All
                    clear
                    echo "Starting all servers on Node 1..."
                    for n in "${Node1Servers[@]}"
                    do
                    ServerStart
                    done
                    if [ ${#NodeStartArray[@]} -gt 1 ]; then
                            :
                        else
                            clear
                            echo "All servers have been started on Node 1"
                        fi
                ;;
                2.)
                    # Node 2 Start All
                    clear
                    echo "Starting all servers on Node 2..."
                    for n in "${Node2Servers[@]}"
                    do
                    ServerStart
                    done
                    if [ ${#NodeStartArray[@]} -gt 1 ]; then
                            clear
                            echo "All servers have been started on selected nodes"
                        else
                            clear
                            echo "All servers have been started on Node 2"
                        fi
                ;;
            esac
        done
    ;;
    6.)
        # Stop All
        clear
        passinput=$(whiptail --passwordbox "Enter Admin Password" 8 78 3>&1 1>&2 2>&3)
        if [ $PASS == $passinput ]; then
            NodeStop=$(whiptail --title "TheWrightServer" --checklist "Which node would you like to stop?" --separate-output 20 78 4 \
            "1." "Node 1" OFF \
            "2." "Node 2" OFF \
            3>&1 1>&2 2>&3)
            NodeStopArray=($NodeStop)
            if DowntimePrompt; then
                DowntimeMessageInput
            fi
            if (whiptail --title "TheWrightServer" --yesno "Would you like to update before stopping?" 8 78); then
                updateBeforeStop=true
            else
                updateBeforeStop=false
            fi
            for NodeStop in "${NodeStopArray[@]}"; do
                case $NodeStop in
                    1.)
                        # Node 1 Stop All
                        clear
                        if [ $updateBeforeStop ]; then
                            echo "Starting update on all updateable based servers before stopping..."
                            for n in "${SnapshotServers[@]}"; do
                            SnapshotVariableChange; done
                            for n in "${Node1UpdateServers[@]}"; do
                            AnnounceDowntimeUpdate; done
                            ServerInstallBuffer
                            clear
                            for n in "${Node1UpdateServers[@]}"; do
                            ServerInstall; done
                            for n in "${Node1UpdateServers[@]}"; do
                            ServerInstallWait; done
                            clear
                        fi
                        echo "Stopping all servers on Node 1..."
                        for n in "${Node1Servers[@]}"
                        do
                        AnnounceMessage
                        done
                        for n in "${Node1Servers[@]}"
                        do
                        ServerStop
                        done
                        if [ ${#NodeStopArray[@]} -gt 1 ]; then
                            :
                        else
                            clear
                            echo "All servers have been stopped on Node 1"
                        fi
                    ;;
                    2.)
                        # Node 2 Stop All
                        clear
                        if [ $updateBeforeStop ]; then
                            echo "Starting update on all updateable servers before stopping..."
                            for n in "${Node2UpdateServers[@]}"; do
                            AnnounceDowntimeUpdate; done
                            ServerInstallBuffer
                            clear
                            for n in "${Node2UpdateServers[@]}"; do
                            ServerInstall; done
                            for n in "${Node2UpdateServers[@]}"; do
                            ServerInstallWait; done
                            clear
                        fi
                        echo "Stopping all servers on Node 2..."
                        for n in "${Node2Servers[@]}"
                        do
                        AnnounceMessage
                        done
                        for n in "${Node2Servers[@]}"
                        do
                        ServerStop
                        done
                        if [ ${#NodeStopArray[@]} -gt 1 ]; then
                            clear
                            echo "All servers have been stopped on selected nodes"
                        else
                            clear
                            echo "All servers have been stopped on Node 2"
                        fi
                    ;;
                esac
            done
        else
            clear
            echo "Incorrect admin password."
            exit
        fi
    ;;
    7.)
        # Restart All
        clear
        passinput=$(whiptail --passwordbox "Enter Admin Password" 8 78 3>&1 1>&2 2>&3)
        if [ $PASS == $passinput ]; then
            NodeRestart=$(whiptail --title "TheWrightServer" --checklist "Which node would you like to restart?" --separate-output 20 78 4 \
            "1." "Node 1" OFF \
            "2." "Node 2" OFF \
            3>&1 1>&2 2>&3)
            NodeRestartArray=($NodeRestart)
            if DowntimePrompt; then
                DowntimeMessageInput
            fi
            for NodeRestart in "${NodeRestartArray[@]}"; do
                case $NodeRestart in
                    1.)
                        # Node 1 Restart All
                        clear
                        echo "Restarting all servers on Node 1..."
                        for n in "${Node1Servers[@]}"
                        do
                        AnnounceMessage
                        done
                        for n in "${Node1Servers[@]}"
                        do
                        ServerRestart
                        done
                        if [ ${#NodeRestartArray[@]} -gt 1 ]; then
                            :
                        else
                            clear
                            echo "All servers have been restarted on Node 1"
                        fi
                    ;;
                    2.)
                        # Node 2 Restart All
                        clear
                        echo "Restarting all servers on Node 2..."
                        for n in "${Node2Servers[@]}"
                        do
                        AnnounceMessage
                        done
                        for n in "${Node2Servers[@]}"
                        do
                        ServerRestart
                        done
                        if [ ${#NodeRestartArray[@]} -gt 1 ]; then
                            clear
                            echo "All servers have been restarted on selected nodes"
                        else
                            clear
                            echo "All servers have been restarted on Node 2"
                        fi
                    ;;
                esac
            done
        else
            clear
            echo "Incorrect admin password."
            exit
        fi
    ;;
    8.)
        # Backup
        if (whiptail --title "Warning" --yesno "Backing up takes up considerable resources and may cause lag. Are you sure you want to continue?" 8 78); then
            ANNOUNCE_MESSAGE="This server is starting a backup that may cause small occasional lag spikes. This process is estimated to take around 20 minutes, and no downtime is expected."
            Backup=$(whiptail --title "TheWrightServer" --checklist "Which servers would you like to backup?" --separate-output 20 78 4 \
            "068416f4-ea04-4b41-8fe9-ecad94000059" "Legion for Vendetta" OFF \
            "b20a74c4-0e64-4a51-af4d-2a964a41207b" "The Homies" OFF \
            "9dfb8354-67a6-4a9e-9447-965c939e7ceb" "Snapshot" OFF \
            "29248816-96e7-4c20-ae88-5d8e90334f94" "Pixelmon Reforged" OFF \
            "2efe6e55-8b98-4cba-942a-564d584623ae" "Skyblock Randomizer" OFF \
            "c4fdb228-457d-4537-9200-f6ba33bb8b5b" "MineColonies" OFF \
            "699e30b5-e824-48a8-a0bc-41daf9e7f50e" "RAD" OFF \
            "941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2" "Survival" OFF \
            "0de1c057-d48c-45f5-9280-849aa664c92a" "Tomas" OFF \
            "bf8e8bc0-de79-456d-9bde-8a72274c1785" "Demon Slayers Unleashed" OFF \
            "3c8b3001-1182-433f-8aec-af21a56b422c" "Wittenberg XC" OFF \
            "df35478a-b8d8-4c55-84cd-aef2e40893bf" "Cribo" OFF \
            3>&1 1>&2 2>&3)
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
        SendMessage=$(whiptail --title "TheWrightServer" --checklist "Which servers would you like to send the message to?" --separate-output 20 78 4 \
        "068416f4-ea04-4b41-8fe9-ecad94000059" "Legion for Vendetta" ON \
        "b20a74c4-0e64-4a51-af4d-2a964a41207b" "The Homies" ON \
        "9dfb8354-67a6-4a9e-9447-965c939e7ceb" "Snapshot" ON \
        "29248816-96e7-4c20-ae88-5d8e90334f94" "Pixelmon Reforged" ON \
        "2efe6e55-8b98-4cba-942a-564d584623ae" "Skyblock Randomizer" ON \
        "c4fdb228-457d-4537-9200-f6ba33bb8b5b" "MineColonies" ON \
        "699e30b5-e824-48a8-a0bc-41daf9e7f50e" "RAD" ON \
        "941a2eb9-e2a2-42ae-9e80-c8e4c8fcf5d2" "Survival" ON \
        "0de1c057-d48c-45f5-9280-849aa664c92a" "Tomas" ON \
        "bf8e8bc0-de79-456d-9bde-8a72274c1785" "Demon Slayers Unleashed" ON \
        "3c8b3001-1182-433f-8aec-af21a56b422c" "Wittenberg XC" ON \
        "df35478a-b8d8-4c55-84cd-aef2e40893bf" "Cribo" ON \
        3>&1 1>&2 2>&3)
        SendMessageArray=($SendMessage)
        clear
        for n in "${SendMessageArray[@]}"
        do
        AnnounceMessage
        done
    ;;
    10.)
        # Failed Backup Check
        clear
        for n in "${AllAllServers[@]}";do
        HandleFailedBackup;done
    ;;
    11.)
        # Server Status
        clear
        for n in "${AllAllServers[@]}"; do
        GetServerStatus; done
    ;;
    12.)
        # Exit
        exit
    ;;   
esac
