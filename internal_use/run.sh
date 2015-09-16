#!/bin/bash

run_assignment() {
	if [ -n "$verbose" ]; then
		set -x  # echo all commands in this script
	fi
	echo "${yellow}	Compile the Code${reset}"
	cp $1.java $PREFIX/
	rm -rf $PREFIX/build
	mkdir -p $PREFIX/build
	hadoop com.sun.tools.javac.Main -source 1.7 -target 1.7 $PREFIX/$1.java -d $PREFIX/build 
	jar -cvf $PREFIX/$1.jar -C $PREFIX/build/ . 

	echo "${yellow}	Run${reset}"
	yarn jar $PREFIX/$1.jar $1 $2 $HDFS_HOME/$1-output 

	echo "${yellow}	Collect the Output${reset}"
	hdfs dfs -cat $HDFS_HOME/$1-output/* > $PREFIX/output-$1.txt

	echo "${yellow}	House Keeping${reset}"
	hdfs dfs -rm -r -f $HDFS_HOME/$1-output

	echo "${yellow}	Post Processing${reset}"
	sort $3 $PREFIX/output-$1.txt -o $PREFIX/output-tmp.txt
	head -n 100 $PREFIX/output-tmp.txt > $PREFIX/$1.output
	rm $PREFIX/output-tmp.txt
	
	if command -v md5sum > /dev/null; then
		# Linux (use md5sum from GNU coreutils):
		md5sum $PREFIX/$1.output  > $PREFIX/$1.hash
		# md5sum $PREFIX/output-TitleCount.txt | awk '{ print $1 }' >> $PREFIX/results.txt
	else
		# BSD (use md5 from OpenSSL):
		# WARNING: md5 output is not the same as md5sum output.
		md5 $PREFIX/$1.output  > $PREFIX/$1.hash
		# md5 -q $PREFIX/output-TitleCount.txt >> $PREFIX/results.txt
	fi

	if [ -n "$verbose" ]; then
		set +x  # back to silence
	fi
}

if [ -z "$PREFIX" ]; then;
	echo "${green}PREFIX is not set. source settings.sh before executing $0.${reset}"
	exit 64; # EX_USAGE
if
if [ -z "HDFS_HOME" ]; then;
	echo "${green}HDFS_HOME is not set. source settings.sh before executing $0.${reset}"
	exit 64; # EX_USAGE
if
if [ -z "$DATASET_N" ]; then;
	echo "${green}$DATASET_N is unset. source user_settings.sh before executing $0.${reset}"
	exit 64; # EX_USAGE
if


if [ "$1" = "-v" ]; then
    verbose=1
    shift # remove option from argument list
fi

if [ $# -eq 0 ]; then
	set A B C D E F   # Run all tests
fi

for test in "$@"; do
case $test in
	"A")
		echo "${green}Running Assingment A: Title Count${reset}"
		run_assignment TitleCount "-D stopwords=$HDFS_HOME/misc/stopwords.txt -D delimiters=$HDFS_HOME/misc/delimiters.txt  $HDFS_HOME/titles" "-n -k2 -r"
	;;
	"B")
		echo "${green}Running Assingment B: Top Titles${reset}"
		run_assignment TopTitles "-D stopwords=$HDFS_HOME/misc/stopwords.txt -D delimiters=$HDFS_HOME/misc/delimiters.txt -D iochainpath=$HDFS_HOME/tmp -D N=$DATASET_N  $HDFS_HOME/titles" "-n -k2 -r"
	;;
	"C")
		echo "${green}Running Assingment C: Top Title Statistics${reset}"
		run_assignment TopTitleStatistics "-D stopwords=$HDFS_HOME/misc/stopwords.txt -D delimiters=$HDFS_HOME/misc/delimiters.txt -D iochainpath=$HDFS_HOME/tmp -D N=$DATASET_N $HDFS_HOME/titles" "-k1"
	;;
	"D")
		echo "${green}Running Assingment D: Orphan Pages${reset}"
		run_assignment OrphanPages "$HDFS_HOME/links"  "-n -k1"
	;;
	"E")
		echo "${green}Running Assingment E: Top Popular Links${reset}"
		run_assignment TopPopularLinks "-D iochainpath=$HDFS_HOME/tmp -D N=$DATASET_N $HDFS_HOME/links"  "-n -k2 -r"
	;;
	"F")
		echo "${green}Running Assingment F: Popularity League${reset}"
		run_assignment PopularityLeague "-D league=$HDFS_HOME/misc/league.txt -D iochainpath=$HDFS_HOME/tmp $HDFS_HOME/links"  "-n -k2 -r"
	;;
	*)
		echo "${green}Skip unknown assignment $test${reset}"
	;;
esac
done
