#!/bin/bash

projects=$(curl "https://git.csclub.uwaterloo.ca/public/mirror-checker/raw/branch/ng/data/mirrors.json" -s |
                 jq -r 'keys | join("\n")' | tr '[:upper:]' '[:lower:]')

failfile=$(mktemp)
emailfile=$(mktemp)
failedProjects=""
failcount=0

function cleanup {
  exitcode=$?

  rm $failfile
  rm $emailfile
  rm -f attachment.txt

  exit $exitcode
}

trap cleanup EXIT

for project in $projects; do
  output=$(./mirror-checker2 c $project)
  stripped=$(echo "$output" | sed -e 's/\x1b\[[0-9;]*m//g')
  fail=$(echo "$stripped" | grep -F "final_status=fail")

  if [ ${#fail} -gt 1 ]; then
     failcount=$(($failcount+1))
     echo "Mirror checker failed for $project"
     failedProjects="$failedProjects $project"

     echo -e "$project failure logs:\n" "$stripped" "\n\n\n\n" >> "$failfile"
  fi
done


# The following variables should be set in the environment
# RECIPIENT = comma separated list of emails
# SENDER = from email address

if [ $failcount -ge 1 ]; then
  echo -e "To: $RECIPIENT\nFrom: $SENDER" > $emailfile
  echo "Subject: Mirror Checker Failure" >> $emailfile

  echo "Mirror checker has failed for $failcount mirrors." >> $emailfile
  echo "The following projects are not passing:" >> $emailfile

  for project in $failedProjects; do
    echo "  - $project" >> $emailfile
  done

  echo -e "\nLogs are attached." >> $emailfile
  echo -e "\nMirror-Checker@Citric-Acid" >> $emailfile

  uuencode $failfile failurelogs.txt > attachment.txt
  cat $emailfile attachment.txt | sendmail -i -t -F $SENDER_ALIAS

  echo -e "\nMirror checker has failed for $failcount mirrors.\nLogs are as follows...\n\n\n"
  cat $failfile
  exit 1
fi