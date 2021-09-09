#!/bin/bash
TMPDIR=/tmp
PUB=/var/www/fs.mightful-noobs.de/teamspeak_badges
OWNER="www-data"

# download
echo "Downloading the link list"
curl https://badges-content.teamspeak.com/list > "$TMPDIR"/teamspeak_badges_downloader

# grab downloadlinks
echo "Grabbing Download links"
grep -oP 'http.?://\S+\"' "$TMPDIR"/teamspeak_badges_downloader | sed 's/.$//' | sed -e 's/$/.svg/' | tr -d '"' > "$TMPDIR"/teamspeak_badges_downloadlist.txt
grep -oP 'http.?://\S+\"' "$TMPDIR"/teamspeak_badges_downloader | sed 's/.$//' | sed -e 's/$/_details.svg/' | tr -d '"' > "$TMPDIR"/teamspeak_badges_details_downloadlist.txt

# genereate csv
echo "Generating CSV files"

# Part 1
echo "id;filename;downloadlink" > "$PUB"/id_filelist.csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$TMPDIR"/teamspeak_badges_downloadlist.txt |sed 's/\//;/g' > "$TMPDIR"/id_filelist.txt
paste -d ";" "$TMPDIR"/id_filelist.txt "$TMPDIR"/teamspeak_badges_downloadlist.txt > "$TMPDIR"/id_filelist.csv
cat "$TMPDIR"/id_filelist.csv >> "$PUB"/id_filelist.csv
[ -z "$(tail -c1 "$PUB"/id_filelist.csv)" ] && truncate -s -1 "$PUB"/id_filelist.csv

# Part 2
echo "id;filename;downloadlink" > "$PUB"/id_filelist_details.csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$TMPDIR"/teamspeak_badges_details_downloadlist.txt | sed 's/\//;/g' > "$TMPDIR"/id_filelist_details.txt
paste -d ";" "$TMPDIR"/id_filelist_details.txt "$TMPDIR"/teamspeak_badges_details_downloadlist.txt > "$TMPDIR"/id_filelist_details.csv
cat "$TMPDIR"/id_filelist_details.txt >> "$PUB"/id_filelist_details.csv
[ -z "$(tail -c1 "$PUB"/id_filelist_details.csv)" ] && truncate -s -1 "$PUB"/id_filelist_details.csv

# generate json
echo "Generating JSON files"
jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1],
        "downloadlink": .[2]})' \
        "$PUB"/id_filelist.csv > "$PUB"/id_filelist.json

jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1]})' \
        "$PUB"/id_filelist_details.csv > "$PUB"/id_filelist_details.json

# actual download of files
cd "$PUB"/badges  || exit
truncate -s 0 "$TMPDIR"/filelist.txt
truncate -s 0 "$TMPDIR"/filelist_details.txt

echo "Downloading Images..."
while read url; do
  echo "${url##*/}" >> "$TMPDIR"/filelist.txt
  curl -sL -O "$url"
done < "$TMPDIR"/teamspeak_badges_downloadlist.txt

while read url; do
  echo "${url##*/}" >> "$TMPDIR"/filelist_details.txt
  curl -sL -O "$url"
done < "$TMPDIR"/teamspeak_badges_details_downloadlist.txt

# right owner
chown -R "$OWNER": "$PUB"
