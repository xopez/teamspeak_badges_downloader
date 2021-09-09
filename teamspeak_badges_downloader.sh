#!/bin/bash
DIR=/root/teamspeak_tmp
PUB=/var/www/fs.mightful-noobs.de/teamspeak_badges

# download
curl https://badges-content.teamspeak.com/list > "$DIR"/teamspeak_badges_downloader

# grep downloadlinks
grep -oP 'http.?://\S+\"' "$DIR"/teamspeak_badges_downloader | sed 's/.$//' | sed -e 's/$/.svg/' | tr -d '"' | tee "$PUB"/teamspeak_badges_downloader.list
grep -oP 'http.?://\S+\"' "$DIR"/teamspeak_badges_downloader | sed 's/.$//' | sed -e 's/$/_details.svg/' | tr -d '"' | tee "$PUB"/teamspeak_badges_downloader_details.list

# genereate csv
echo "id;filename" | tee "$PUB"/id_filelist.csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$PUB"/teamspeak_badges_downloader.list |sed 's/\//;/g' | tee -a "$PUB"/id_filelist.csv
[ -z "$(tail -c1 "$PUB"/id_filelist.csv)" ] && truncate -s -1 "$PUB"/id_filelist.csv
echo "id;filename" | tee "$PUB"/id_filelist_details.csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$PUB"/teamspeak_badges_downloader_details.list | sed 's/\//;/g' | tee -a "$PUB"/id_filelist_details.csv
[ -z "$(tail -c1 "$PUB"/id_filelist_details.csv)" ] && truncate -s -1 "$PUB"/id_filelist_details.csv

# generate json
jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1]})' \
        "$PUB"/id_filelist.csv > "$PUB"/id_filelist.json

jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1]})' \
        "$PUB"/id_filelist_details.csv > "$PUB"/id_filelist_details.json

# actual download of files
cd "$PUB"/badges  || exit
truncate -s 0 "$PUB"/filelist.txt
truncate -s 0 "$PUB"/filelist_details.txt

while read url; do
  echo "$url"
  echo "${url##*/}" | tee -a "$PUB"/filelist.txt
  curl -sL -O "$url"
done < "$PUB"/teamspeak_badges_downloader.list

while read url; do
  echo "$url"
  echo "${url##*/}" | tee -a "$PUB"/filelist_details.txt
  curl -sL -O "$url"
done < "$PUB"/teamspeak_badges_downloader_details.list

# right owner
chown -R www-data: "$PUB"
