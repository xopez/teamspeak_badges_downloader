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
# get IDs and filelist for csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$TMPDIR"/teamspeak_badges_downloadlist.txt |sed 's/\//;/g' > "$TMPDIR"/id_filelist.txt
# add own domain
awk '{$0=$0";https://fs.mightful-noobs.de/teamspeak_badges/badges/"}1' "$TMPDIR"/id_filelist.txt > "$TMPDIR"/tmp.txt
paste -d "" "$TMPDIR"/tmp.txt "$TMPDIR"/filelist.txt > "$TMPDIR"/id_filelist.txt
# add original download link
paste -d ";" "$TMPDIR"/id_filelist.txt "$TMPDIR"/teamspeak_badges_downloadlist.txt > "$TMPDIR"/id_filelist.csv
# make public and combine csv
echo "id;filename;downloadlink;original_file" > "$PUB"/id_filelist.csv
cat "$TMPDIR"/id_filelist.csv >> "$PUB"/id_filelist.csv
[ -z "$(tail -c1 "$PUB"/id_filelist.csv)" ] && truncate -s -1 "$PUB"/id_filelist.csv

# Part 2
# get IDs and filelist for csv
sed 's/https:\/\/badges-content.teamspeak.com\///' "$TMPDIR"/teamspeak_badges_details_downloadlist.txt |sed 's/\//;/g' > "$TMPDIR"/id_filelist_details.txt
# add own domain
awk '{$0=$0";https://fs.mightful-noobs.de/teamspeak_badges/badges/"}1' "$TMPDIR"/id_filelist_details.txt > "$TMPDIR"/tmp.txt
paste -d "" "$TMPDIR"/tmp.txt "$TMPDIR"/filelist_details.txt > "$TMPDIR"/id_filelist_details.txt
# add original download link
paste -d ";" "$TMPDIR"/id_filelist_details.txt "$TMPDIR"/teamspeak_badges_details_downloadlist.txt > "$TMPDIR"/id_filelist_details.csv
# make public and combine csv
echo "id;filename;downloadlink;original_file" > "$PUB"/id_filelist_details.csv
cat "$TMPDIR"/id_filelist_details.csv >> "$PUB"/id_filelist_details.csv
[ -z "$(tail -c1 "$PUB"/id_filelist_details.csv)" ] && truncate -s -1 "$PUB"/id_filelist_details.csv

# generate json
echo "Generating JSON files"
jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1],
        "download": .[2],
        "original_file": .[3]})' \
        "$PUB"/id_filelist.csv > "$PUB"/id_filelist.json

jq --slurp --raw-input --raw-output \
    'split("\n") | .[1:] | map(split(";")) |
        map({"id": .[0],
        "filename": .[1],
        "download": .[2],
        "original_file": .[3]})' \
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
