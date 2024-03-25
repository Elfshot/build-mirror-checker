projects=$(curl "https://git.csclub.uwaterloo.ca/public/mirror-checker/raw/branch/ng/data/mirrors.json" -s |
                 jq -r 'keys | join("\n")' | tr '[:upper:]' '[:lower:]')

failfile=$(mktemp)
failcount=0

for project in $projects; do
  output=$(./mirror-checker2 c $project)
  stripped=$(echo "$output" | sed -e 's/\x1b\[[0-9;]*m//g')
  fail=$(echo "$stripped" | grep -F "final_status=fail")

  if [ ${#fail} -gt 1 ]; then
     failcount=$(($failcount+1))
     echo "Mirror checker failed for $project"
     echo "$project failure logs:\n$output\n\n" >> "$failfile" #This contains ANSI colouring which may or may not appea>     #echo "$project failure logs:\n$stripped\n\n" >> "$failfile"
  fi
done

if [ $failcount -ge 1 ]; then
  echo "\nMirror checker has failed for $failcount mirrors.\nLogs are as follows...\n\n\n"
  cat $failfile
  rm $failfile
  exit 1
fi