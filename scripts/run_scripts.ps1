# Script to run updates and auto commit/push to GitHub 
cd C:\Users\victor.faner\Documents\datasets\scripts

rscript .\dfw_historical_weather.R
git add ..\data\dfw_historical_weather.csv
$today = Get-Date -Format "yyyy/MM/dd"
$message = -join("Update ", $today)
git commit -m $message

