#!/bin/bash

SCRIPTNAME=`basename "$0"`

print_help() {
	cat << EOF
Usage: $SCRIPTNAME filename.tex
Uses 'sleep-until-modified.sh' to watch a given LaTeX file, compiling it and its bibliography when the .tex file is modified.
If the --git flag is used, the program will attempt to create a git commit every 10th modification. Use --git-immediate to create a commit at every modification.
EOF
}

# check dependencies
if ! type sleep-until-modified.sh &>/dev/null ; then
	echo "You are missing the sleep-until-modified.sh dependency. Find it at https://github.com/dave-woods/sleep-until-modified"
	exit 1
fi

do_git=false
mod_count=9
SLEEPER=sleep-until-modified.sh

# parse_parameters:
while [[ "$1" == -* ]] ; do
	case "$1" in
		-h|-help|--help)
			print_help
			exit
			;;
		-g|--git)
			do_git=true
			shift
			break
			;;
		-gg|--git-immediate)
			do_git=true
			mod_count=0
			shift
			break
			;;
		*)
			echo "Invalid parameter: '$1'"
			exit 1
			;;
	esac
done

if [ "$#" != 1 ] ; then
	echo "Incorrect parameters. Use --help for usage instructions."
	exit 1
elif [ "`file --mime-type -b \"$1\"`" != "text/x-tex" ] || [ ${1: -4} != ".tex" ]; then
	echo "File must be a valid LaTeX file. Use --help for usage instructions."
	exit 1
fi

f=${1%.tex}
BIB=$f.aux
TEX=$f.tex

echo "Watching $TEX for changes. Press Ctrl+C to stop."

i=0
while $SLEEPER $TEX;
do
	bibtex $BIB;
	pdflatex $TEX;
	((i++))
	if [ "$do_git" = true ] && (($i > $mod_count));
	then
		git add .;
		git commit -m "Auto-commit: stashing most recent changes.";
		echo "Most recent changes have been committed, but not pushed.";
		((i = 0));
  fi
done
