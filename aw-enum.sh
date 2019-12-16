#!/bin/sh

export DOMAIN=$1
export URL=$2
export RANDHEX=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random | tr '[:upper:]' '[:lower:]')
cat request1.txt | sed "s/DOMAIN/$DOMAIN/" | sed "s/RANDHEX/$RANDHEX/"| sed "s/RANDHEX/$RANDHEX/" > request1.dat
export REQUEST=$(curl -s --data @request1.dat https://$URL/deviceservices/enrollment/airwatchenroll.aws/validategroupidentifier > request1result.dat)
export POLICY=$(cat request1result.dat | jq .NextStep | jq .SettingsPayload |tr -d \")
echo $POLICY | base64 -d
rm *.dat
