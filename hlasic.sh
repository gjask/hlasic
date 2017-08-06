#!/bin/bash

#
# Hlasic Vavrinecky potok (2014)
#
# pouziti: ./hlasic.sh
#	defaultni chovani, zacne startovat od cisla 1 v case v promene first
# pouziti: ./hlasic.sh 9:45:30 10
#	posune nastaveni casu tak, aby v 9:45:30 startovalo 10. cislo
#	dopocitava obema smery casovou osu, pri zadani prosleho casu bude
# 	pokracovat odpovidajicim budoucim cislem
#	pokud se zada budouci cas, zacne hlasit odpovidajici predchazejici
# 	cisla pouze s tretim argumentem -x


first=$( date +%s -d '9:30:00' )	# cas prvniho startu "HH:MM:SS"
step=30					# rozestup mezi cisly v sekundach
tts=10					# delka stopy do odstartovani
speaker='mplayer'			# prikaz prehravajici mp3 stopy
log='/dev/null'				# soubor na chybove hlasky prehravace
samples="$( dirname $0 )/zvuk"		# slozka se zvukovymi stopami


if [ -n "$1" -a -n "$2" ]; then
	number=$2
	stime=$( date +%s -d "$1" )
	first=$(( $stime - ( ( $number - 1 ) * $step ) ))
fi
now=$( date +%s )
number=$(( ($now - $first) / $step + 2 )) # (+1) v nultem case startuje uz 1. cislo, (+1) zaokrouhleni na budouci start

[ -n "$2" ] && [ "$3" != '-x' -a -n "$2" -a $number -lt "$2" ] && number=$2	# defaultne omezena flexibilita casove osy
[ $number -lt 1 ] && number=1	# odchytava negativni startovni cisla

echo "Cas prvniho cisla:  $( date +%T -d @$first )"
echo "Pokracuje cislo $number"
echo

# command running the speaker
cmd(){
	$speaker $@ >/dev/null 2>$log &
}

# fce sestavujici zvukove stopy
compose(){
	n=$(( $1 + 1 ))
	[ $n -gt 999 ] && exit 999
	files=""
	x=$( echo $n | rev )
	x0=$( echo $x | cut -c 1 )
	x1=$( echo $x | cut -c 2 )
	x2=$( echo $x | cut -c 3 )

	[ -n "$x2" ] && files="$files $samples/${x2}00.mp3"
	if [ -n "$x1" ] && [ "$x1" -gt 0 ]; then
		if [ $x1 -eq 1 ]; then
			echo $files "$samples/1${x0}.mp3"
			return
		fi
		files="$files $samples/${x1}0.mp3"
	fi
	[ -n "$x0" -a "$x0" -gt 0 ] && files="$files $samples/${x0}.mp3"
	echo $files
}

# pripravne hlaseni pred prvnim cislem
play=$(( $first + ($number - 2) * $step ))
now=$( date +%s )
if [ $play -gt $now ]; then
	playlist=$( compose $(( $number - 1 )) )
	sleep $(( $play - $now ))
	cmd $samples/pripravit.mp3 $playlist
fi

# Startovaci smycka
while true; do
	next=$(( $first + ($number - 1) * $step ))
	play=$(( $next - $tts ))
	playlist=$( compose $number )
	now=$( date +%s )
	[ $now -lt $play ] && sleep $(( $play - $now ))
	cmd $samples/start.mp3 $playlist
	echo "Start cisla $number za 10s ($( date +%T -d @$next ))"
	number=$(($number + 1))
done
