#!/bin/bash

tmp=$(tempfile)
outfile=$(tempfile)

curl -v -A "clemo's iCal-script" "https://segvault.space/events.html" > $tmp 2>$outfile

tmp2=$(tempfile)
cat $tmp | tr " \n\r\f\t" " " | sed -r 's/ +/ /g' | sed 's/<h3>Upcoming Events<\/h3>/\n&/g' | tail -n 1 | sed 's/div class="entry clearfix">/\n&/g' | sed 's/<div class="entry-date"><span>/<div class="entry-date">??<span>/g' | sed -r 's/<div class="entry-date">([0-9])\./<div class="entry-date">0\1\./g' | grep -v "</section>\|<h3>" > $tmp2

rm $tmp

currentYear=$(date '+%Y')

cat $tmp2 | sed -r "s/.*<div class=\"entry-date\">([^\.]+)\.*-*([0-9]*)\.*<span>(.*)<\/span><\/div> +<\/a>.*<h2><a href=\"#\">(.*)<\/a><\/h2>.*<span class=\"label label-.*\">(.*)<\/span><\/li>.*<i class=\"icon-time\"><\/i>[ab ]*([0-9 ]*):*([0-9 ]*).*<\/a><\/li> <li><a href=\"#\">.*class=\"icon-map-marker2\"><\/i>(.*)<\/a><\/li> <\/ul.*<div class=\"entry-content\"> <p>(.*)<\/p> <\/div> <\/div> <\/div.*/BEGIN:VEVENT\nUID:SEGVAULT$currentYear\3\1T\6\700\nSUMMARY:\4\nDTSTART;TZID=Europe\/Vienna:$currentYear\3\1T\6\7ZEROZERO\nDTEND;TZID=Europe\/Vienna:$currentYear\3\2T\6\759\nDTSTAMP:$currentYear\3\1T\6\700Z\nCATEGORIES:\5\nLOCATION:\8\nDESCRIPTION:\9\nEND:VEVENT/g" | sed 's/\\nBinary file \(standard input\) matches//g' > $tmp

cat $tmp | sed 's/�/ä/g' | sed 's/Mai/05/g' | sed 's/M�rz/03/g' | sed 's/März/03/g' | sed 's/Jänner/01/g'  | sed 's/April/04/g' | sed 's/Februar/02/g' | sed 's/J<C3><A4>nner/01/g' | sed 's/Juni/06/g' | sed -r 's/ *ZERO/0/g' | sed 's/Juli/07/g' | sed 's/August/08/g' | sed 's/September/09/g' | sed 's/Septemeber/09/g' | sed 's/Oktober/10/g' | sed 's/November/11/g' | sed 's/Dezember/12/g' >  $tmp2

cat $tmp2 | sed 's/00 00$/0000/g' | sed -r 's/[ \t\f]$//g' | sed 's/$/<br>/' | sed 's/\.$//g' | sed 's/??/01/g'  | pandoc -f html -t plain | sed -r 's/:([0-9]{6})([0-9])$/:\10\2/g' |  sed -r 's/:([0-9]{6})([0-9])T/:\10\2T/g'| sed -r 's/([0-9]) 59/\159/g' | sed 's/T00$/T235959/g' | sed "s/$(echo '&#223;' | pandoc -f html -t plain)/ss/g" | sed "s/$(echo '&ouml;' | pandoc -f html -t plain)/oe/g" | sed "s/$(echo '&auml;' | pandoc -f html -t plain)/ae/g" | sed "s/$(echo '&uuml;' | pandoc -f html -t plain)/ue/g" | sed "s/$(echo '&Ouml;' | pandoc -f html -t plain)/Oe/g" | sed "s/$(echo '&Auml;' | pandoc -f html -t plain)/Ae/g" | sed "s/$(echo '&Uuml;' | pandoc -f html -t plain)/Ue/g"  > $tmp


incremented=$(tempfile)
last_hour="19"
last_start_line=""
while read line; do
	if [[ "$line" == "DTSTART"* ]]; then 
		last_hour="$(echo -e \"$line\" | sed -r 's/.*T([0-9][0-9])[0-9][0-9][0-9][0-9].*/\1/g')"
		last_start_line="$line"
		echo "$line" >> $incremented
	else
		if [[ "$line" == "DTEND"* ]]; then
			if [[ "$line" =~ ^.*:[0-9]{6}T.*$ ]]; then
				#echo "DEBUG $line matches; $last_start_line"
				line=$(echo "$last_start_line" | sed 's/DTSTART/DTEND/g')
				#echo "line is now: $line"
			fi
			echo "$line" | sed -r "s/([0-9]{8})T([0-9]{2})([0-9]{4})/\1T$(($last_hour+2))\3/g"  >> $incremented
		else
			echo $line | sed 's/,/\\,/g' >> $incremented
		fi
	fi
done <$tmp

echo "BEGIN:VCALENDAR" > $tmp2
echo "VERSION:2.0" >> $tmp2
echo "PRODID:SegvaultSpace" >> $tmp2
echo "BEGIN:VTIMEZONE" >> $tmp2
echo "TZID:Europe/Vienna" >> $tmp2
#echo "X-LIC-LOCATION:Europe/Vienna" >> $tmp2
echo "BEGIN:DAYLIGHT" >> $tmp2
echo "TZOFFSETFROM:+0100" >> $tmp2
echo "TZOFFSETTO:+0200" >> $tmp2
echo "TZNAME:Europe/Vienna" >> $tmp2
echo "DTSTART:19700329T020000" >> $tmp2
echo "RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3" >> $tmp2
echo "END:DAYLIGHT" >> $tmp2
echo "BEGIN:STANDARD" >> $tmp2
echo "TZOFFSETFROM:+0200" >> $tmp2
echo "TZOFFSETTO:+0100" >> $tmp2
echo "TZNAME:Europe/Vienna" >> $tmp2
echo "DTSTART:19701025T030000" >> $tmp2
echo "RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10" >> $tmp2
echo "END:STANDARD" >> $tmp2
echo "END:VTIMEZONE" >> $tmp2




cat $incremented | sed 's/T00Z/T000000Z/g' | sed 's/T59$/T235959/g' | sed 's/00 00/0000/g' | sed -r 's/(DTSTART;.*T)235959/\1000000/g' | tr "\n" "\r" | sed -r 's/(DTSTAMP:[0-9]{8}T[0-9]{6})\r/\1Z/g' | sed 's/\r\r*/\r/g'| sed -r 's/ \r/\r/g'| sed -r 's/\r([A-Z][A-Z][A-Z])/\n\1/g' | sed 's/\r$//g' | sed 's/\r/\\n/g' | sed 's/  */ /g' | iconv -c -t ascii >> $tmp2
rm $incremented

echo "\n" >> $tmp2

curl -A "clemo's iCal-script" -s "https://segvault.space/js/events-data.js" | grep ":" | sed -r "s/^.*'([0-9][0-9])-([0-9][0-9])-([0-9][0-9][0-9][0-9])'\s*:\s*'[^>]*>([^<]*).*$/BEGIN:VEVENT\nUID:SEGVAULT\3\1\2T180000\nSUMMARY:\4\nDTSTART;TZID=Europe\/Vienna:\3\1\2T180000\nDTEND;TZID=Europe\/Vienna:\3\1\2T220000\nDTSTAMP:\3\1\2T180000Z\nCATEGORIES:Public\nLOCATION:Kremsergasse 11\\\, St. Poelten\\\, Austria\nDESCRIPTION: \4\\\nfrom https:\/\/segvault.space\/js\/events-data.js\nEND:VEVENT/g" | sed "s/$(echo '&#223;' | pandoc -f html -t plain)/ss/g" | sed "s/$(echo '&ouml;' | pandoc -f html -t plain)/oe/g" | sed "s/$(echo '&auml;' | pandoc -f html -t plain)/ae/g" | sed "s/$(echo '&uuml;' | pandoc -f html -t plain)/ue/g" | sed "s/$(echo '&Ouml;' | pandoc -f html -t plain)/Oe/g" | sed "s/$(echo '&Auml;' | pandoc -f html -t plain)/Ae/g" | sed "s/$(echo '&Uuml;' | pandoc -f html -t plain)/Ue/g" | sed 's/: */:/g'| iconv -c -t ascii  >> $tmp2


echo -e "\nEND:VCALENDAR" >> $tmp2

cat $tmp2 | sed 's/Binary file.*$//g' | sed 's/END:VEVENT.*/END:VEVENT/g' | sed '/^\s*$/d' > $tmp 2>>$outfile

cat $tmp | grep "^UID:" | sort | uniq -c | sed 's/^\s*//g'| grep -v "^1 "|cut -d ' ' -f2 | while read ui #replace duplicate (2 times semae) ID
do
	rnd=$( printf "%02d" $(( RANDOM % 60 )))
	rep="$(echo "$ui" | sed -r "s/^(.*)(..)\$/\1$rnd/g")"
	echo "uid='$ui' rep='$rep'"
	sed -i -r "0,/$ui/ s//$rep/g" $tmp
done

cat $tmp | perl -pe 's/\n/\r\n/' > $tmp2
cat $tmp2 > $tmp

mv $tmp /var/www/html/segVaultCal/current.ics
rm $tmp2

cat $outfile
rm $outfile
echo "completed $(date)"
