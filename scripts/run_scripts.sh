#!/usr/bin/sh

# Script to run updates and auto commit/push to GitHub 
Rscript dfw_historical_weather.R
git add ../data/dfw_historical_weather.csv
today=$(date -u +'%Y-%m-%d')
message="Update $today"
git commit -m "$message"
git push origin

