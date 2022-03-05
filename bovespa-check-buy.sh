#!/bin/bash
config=$(cat bovespa-check-buy.conf)
companyTotal=$(echo $config | jq '.companys | length')

for i in $(seq 0 $(($companyTotal-1)));
do
	company=$(echo $config | jq -r '.companys['$i']')
	priceMin=$(echo $config | jq '."'$company'".priceMin')
	priceMax=$(echo $config | jq '."'$company'".priceMax')
	price=$(curl "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$company&apikey=AHBD0XN0YJWBSXTU" | jq -r '."Global Quote"."05. price"')
	notification="$company se encontra entre os valores $priceMin - $priceMax"

	if (( $(echo "$price >= $priceMin" | bc -l) )); then
		if (( $(echo "$price <= $priceMax" | bc -l) )); then
			termux-notification -c "$notification"
        fi
    fi
done
