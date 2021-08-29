#!/bin/bash 

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36'
User="584544"
EXT="75e07"
Link="https://t66y.com/index.php?u=${User}&ext=${EXT}"
echo "Link===============${Link}"

Vcencode=`curl -sf -A "${UA}" ${Link} | egrep -o "vcencode=[0-9]*"`
echo "Vcencode============${Vcencode}"

NewLink="https://t66y.com/index.php?u=${User}&${Vcencode}"
echo "NewLink=======${NewLink}"

curl -sf -A "$UA" -d "url=&ext=&adsaction=userads1010" ${NewLink} > /dev/null
