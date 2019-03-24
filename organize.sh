#!/bin/bash

PRIMARY_EXTENSION=js
ADDITIONAL_EXTENSIONS="md comment.txt input.txt output.txt md5sum.txt title.txt"
MAX_DIR_LEVEL=3
VERBOSE=false;
VVERBOSE=false;
FORCE=false;

while [[ $# -gt 0 ]]; do
    case $1 in
    "-v") VERBOSE=true ;;
    "-vv") VVERBOSE=true; VERBOSE=true ;;
    "-f") FORCE=true;;
    *) echo "unknown argument"
    esac
    shift
done

create_list() {
    if $VERBOSE; then echo "creating list file"; fi
	find . -name "*\.$PRIMARY_EXTENSION" -o -name "00\.README\.md" | sort > list.txt

    if $VERBOSE; then echo "creating List file"; fi
    echo -e "# Verbose Table of Content\n" > List.md
    for filename in $(cat list.txt); do
        rawname=$(echo $filename | sed 's/\.[a-z]*$//');
        filenumber=$(echo $filename | sed -e 's/.*\///' -e 's/\..*//' -e 's/\..*//')
        title=$(cat $rawname.title.txt 2>/dev/null);
        level=$(echo $filename | grep -o "/" | wc -l);
		filenumber=$(echo $rawname | grep -oe "[0-9][0-9]" | xargs | sed 's/ 00$//' | cut -d" " -f 1-$(expr $level + 1) | tr " " ".")

        if [[ $title == "" ]]; then title="no title"; fi

        if [[ $(echo $filename | grep -o "README") == "README" ]]; then
            level=$(expr $level - 3);
        else
            level=$(expr $level - 2);
        fi

        link="";
        for index in $(seq 0 $level); do
            link=$(echo "$link  ") ;
        done;

        if [[ $(echo $filename | grep -o "README") == "README" ]]; then
            link=$(echo "$link* [$filenumber. $title]($filename)");
        else
            link=$(echo "$link* [$filenumber. $title]($rawname.md)");
        fi
        echo "$link" >> List.md;
    done
    sed -e '/^    \*/d' List.md -e 's/Verbose/Brief/' > Brief.md
}

is_directory_organized() {
    index=0
    for file in $(cat "$directory/.list"); do
        index=$(expr $index + 1)
        index=$(printf "%02d" $index)
        if [[ -d "$directory/$file" ]] || [[ -f "$directory/$file" ]]; then
            if $VERBOSE; then echo "$directory/$file contains new file, needs indexing"; fi
            ORGANIZED=false; break
        elif ! [[ -d "$directory/$index.$file" ]] && ! [[ -f "$directory/$index.$file" ]]; then
            if $VERBOSE; then echo "$directory/$file has broken indexing, needs update"; fi
            ORGANIZED=false; break
        else
            if $VVERBOSE; then echo "$directory/$file is updated"; fi
            ORGANIZED=true
        fi
    done
}

organize_extensions() {
    for extension in $ADDITIONAL_EXTENSIONS; do
        rawname=$(echo $filename | sed 's/\..*$//')
        rootextension=$(ls -d $directory/*$rawname.$extension 2>/dev/null)
        if [[ -f $rootextension ]]; then
            if $VVERBOSE; then echo "$extension extension found for $filename"; fi
            mv $rootextension $directory/$index.$rawname.$extension 2>/dev/null
        fi
    done
}

organize_directory() {
    if $VERBOSE; then echo "organizing $directory"; fi
    index=0
    for file in $(cat "$directory/.list"); do
        index=$(expr $index + 1)
        index=$(printf "%02d" $index)
        filename=$(echo $file | sed 's/.*\/[0-9]*\.//')
        filenumber=$(echo $file | sed 's/.*\/\..*//')
        rootname=$(ls -d $directory/*$file 2>/dev/null)
        if [[ -d $rootname ]]; then
            if $VVERBOSE; then echo "moving $rootname to $directory/$index.$filename"; fi
            mv $rootname $directory/$index.$filename 2>/dev/null
        elif [[ -f $rootname ]]; then
            if $VVERBOSE; then echo "moving $rootname to $directory/$index.$rawname.$PRIMARY_EXTENSION"; fi
            rawname=$(echo $filename | sed 's/\..*$//')
            mv $rootname $directory/$index.$rawname.$PRIMARY_EXTENSION 2>/dev/null
            organize_extensions
        else
            echo "WARNING! file does not exist: $directory/$file"
        fi
    done
    total=$(expr $total + 1)
}

total=0
for level in $(seq $MAX_DIR_LEVEL -1 1); do
    for list in $(find . -mindepth $level -maxdepth $level -name ".list"); do
        directory=$(echo $list | sed 's/\/\.list$//')
        if $VVERBOSE; then echo "checking if $directory is organized"; fi
        is_directory_organized
        if ! $ORGANIZED; then organize_directory; fi
    done
done

if [[ $total -eq 0 ]]; then
    echo "all organized";
else
    echo "$total directories organized";
    create_list
fi

if $FORCE; then
	echo "forcing list creation"
    create_list
fi
