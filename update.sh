#!/bin/bash

source config.sh

while [[ $# -gt 0 ]]; do
    case $1 in
    "-v") VERBOSE=true; options=$(echo "$options -v") ;;
    "-vv") VVERBOSE=true; VERBOSE=true; options=$(echo "$options -vv"); options=$(echo "$options -v") ;;
    "-f") FORCE=true; options=$(echo "$options -f") ;;
    *) echo "unknown argument"
    esac
    shift
done

find . -name "practice*" | xargs rm -f

# organize repository
./organize.sh $options

create_relative_list() {
    relative_root=$1
    relative_level=$2
    if $VVERBOSE; then echo "creating relative list for $relative_root"; fi
    find $relative_root -name "*\.$PRIMARY_EXTENSION" -o -name "00\.README\.md" | sort > relative_list.txt
    target_file=$(head -n1 relative_list.txt)
    sed -i '1d' relative_list.txt

    for filename in $(cat relative_list.txt); do
        rawname=$(echo $filename | sed 's/\.[a-z]*$//');
        level=$(echo $filename | grep -o "/" | wc -l);
        level=$(expr $level - 1);
        if [ $level -gt 2 ]; then break; fi

        if ! [ -f $rawname.title.txt ]; then echo "Warning: title file not found for $filename"; fi
        title=$(cat $rawname.title.txt 2>/dev/null);

        filenumber=$(echo $rawname | grep -oe "[0-9][0-9]" | xargs | sed 's/ 00$//' | cut -d" " -f 1-$(expr $level + 1) | tr " " ".")

        if [[ $(echo $filename | grep -o "README") == "README" ]]; then
            relative_name="./"$(echo $filename | cut -d "/" -f "$relative_level-")
            level=$(echo $relative_name | grep -o "/" | wc -l);
            level=$(expr $level - 2);
            link=""; while [[ $level -gt 0 ]]; do link=$(echo "$link  "); level=$(expr $level - 1); done
            link=$(echo "$link* [$filenumber. $title]($relative_name)")
        else
            relative_name="./"$(echo $rawname | cut -d "/" -f "$relative_level-")".md"
            level=$(echo $relative_name | grep -o "/" | wc -l);
            level=$(expr $level - 1);
            link=""; while [[ $level -gt 0 ]]; do link=$(echo "$link  "); level=$(expr $level - 1); done
            link=$(echo "$link* [$filenumber. $title]($relative_name)")
        fi
        echo "$link" >> $target_file
    done

    rm relative_list.txt
}

# create README table of contents
find . -name "00.README.md" > readme.list
for readme in $(cat readme.list); do
    readme_path=$(echo $readme | sed -e 's/00\.README\.md$//' -e 's/README\.md$//')
    sed -i '/# Table of Content/,$ d' $readme
    sed -i '/# Quick Access/,$ d' $readme
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' $readme
    echo -e "\n### Table of Content\n" >> $readme
    relative_level=$(echo $readme_path | grep -o "/" | wc -l);
    relative_level=$(expr $relative_level + 1);
    create_relative_list $readme_path $relative_level
done

# source codes should be represented in markdown syntax with proper syntax highlighting
if $VERBOSE; then echo "listing source code files"; fi
sed -n "/\.md)$/p" List.md | sed -r 's/.*\[.*\. (.*)\]\((.*)\).*/\1|\2/' | tr " " "~" > files.list

if $VERBOSE; then echo "inserting header and trailer"; fi
for pair in $(cat files.list)
do
    sourceHeader=$(echo $pair | cut -d"|" -f1 | tr "~" " ") # header in first pair
    sourceMD=$(echo $pair | cut -d"|" -f2 | tr "~" " ") # file path in second pair
    if [[ $(echo $sourceMD | grep -o "README") == "README" ]]; then
        continue
    else
        sourcePath=$(echo $sourceMD | sed "s/\.md$/\.$PRIMARY_EXTENSION/")
    fi

    if [[ -f $sourcePath ]]; then
        echo -e "# $numbering $sourceHeader\n" > $sourceMD # header of the file
        echo -e "\`\`\`$PRIMARY_EXTENSION" >> $sourceMD # markdown syntax highlighting
        cat $sourcePath >> $sourceMD # append source code text to md file
        echo -e "\n\`\`\`" >> $sourceMD # end of the markdown syntax
    else
        echo "${LINENO}: WARNING: $sourcePath does not exist"
    fi
done

if $EXECUTABLE; then
if [[ -n $COMPILER ]]; then
if $VERBOSE; then echo "compiling files and generating results..."; fi
for pair in $(cat files.list)
do
    sourceMD=$(echo $pair | cut -d"|" -f2 | tr "~" " ") # file path in second pair
    if [[ $(echo $sourceMD | grep -o "README") == "README" ]]; then
        continue
    else
        sourcePath=$(echo $sourceMD | sed "s/\.md$/\.$PRIMARY_EXTENSION/")
    fi
    sourceInput=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.input\.txt/" | tr "~" " ") # input text
    sourceFlags=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.flags\.txt/" | tr "~" " ") # input text
    sourceOutput=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.output\.txt/" | tr "~" " ") # input text
    sourceSign=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.md5sum.txt/" | tr "~" " ") # input text
    if [ -f $sourceFlags ]; then
        sourceFlags=$(cat $sourceFlags)
    else
        sourceFlags=""
    fi

    md5sum --quiet --ignore-missing --check $sourceSign &>/dev/null
    if [[ $? -eq 0 ]]; then signed=true; else signed=false; fi

    if [[ -f $sourcePath ]]; then
        if [[ -f $sourceInput ]]; then
            echo -e "\n## Input\n" >> $sourceMD
            echo -e "\`\`\`txt" >> $sourceMD
            cat $sourceInput >> $sourceMD
            echo -e "\n\`\`\`" >> $sourceMD
        fi

        echo -e "\n## Output\n" >> $sourceMD
        echo -e "\`\`\`txt" >> $sourceMD

        if ! $signed || ! [[ -f $sourceOutput ]] || $FORCE; then
            if $VVERBOSE; then echo "compiling" $sourcePath; fi

            if $EXECUTABLE_MODE; then
                if [[ -n $PKG_CFLAGS ]] && [[ -n $PKG_LIBS ]]; then
                    $COMPILER $(pkg-config --cflags $PKG_CFLAGS) $sourceFlags $COMPILER_OPTIONS $sourcePath -o practice $(pkg-config --libs $PKG_LIBS)
                elif [[ -n $PKG_LIBS ]]; then
                    $COMPILER $COMPILER_OPTIONS $sourceFlags $sourcePath -o practice $(pkg-config --libs $PKG_LIBS)
                elif [[ -n $PKG_CFLAGS ]]; then
                    $COMPILER $(pkg-config --cflags $PKG_CFLAGS) $COMPILER_OPTIONS $sourceFlags $sourcePath -o practice
                else
                    $COMPILER $COMPILER_OPTIONS $sourceFlags $sourcePath -o practice
                fi

                if ! [ -f practice ]; then
                    echo "no output" >> $sourceMD
                elif [[ -f $sourceInput ]]; then
                    cat $sourceInput | ./practice >> $sourceMD
                    cat $sourceInput | ./practice > $sourceOutput
                else
                    ./practice >> $sourceMD
                    ./practice > $sourceOutput
                fi
            else
                $COMPILER $COMPILER_OPTIONS $sourcePath > $sourceOutput
                cat $sourceOutput >> $sourceMD
            fi

            if $VVERBOSE; then echo "signing" $sourcePath; fi
            md5sum $sourcePath > $sourceSign
        elif [[ -f $sourceOutput ]]; then
            cat $sourceOutput >> $sourceMD
        fi
    else
        echo "WARNING: $sourcePath does not exist"
    fi

    # check if output is empty
    if [[ $(grep -A 1 "\`\`\`txt" $sourceMD | grep -v "\`\`\`txt" | wc -c) -lt 2 ]]; then
        sed -i '$ d' $sourceMD; sed -i '$ d' $sourceMD
        echo -ne "\n" >> $sourceMD
        echo "no output provided" >> $sourceMD
    else
        echo -e "\`\`\`" >> $sourceMD # end of the markdown syntax
    fi

    if [ -f practice ]; then
        rm practice
    fi
done
fi
fi

if $COMMENTS; then
if $VERBOSE; then echo "appending comments..."; fi
for pair in $(cat files.list)
do
    markdownSrc=$(echo $pair | cut -d"|" -f2 | tr "~" " ") # file path in second pair
    if [[ $(echo $markdownSrc | grep -o "README") == "README" ]]; then
        continue
    else
        sourcePath=$(echo $markdownSrc | sed "s/\.md$/\.$PRIMARY_EXTENSION/")
    fi
    commentSrc=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.comment\.txt/" | tr "~" " ") # comment source path
    verification=$(echo $sourcePath | sed "s/\.$PRIMARY_EXTENSION$/\.reference\.txt/" | tr "~" " ") # comment source path

    if [[ -f $commentSrc ]] && [[ -f $markdownSrc ]] && $REFERENCE_VALIDITY && [[ -f $verification ]]; then
        echo -e "\n## Comments\n" >> $markdownSrc # append comments to md file
        cat $commentSrc >> $markdownSrc
    elif [[ -f $commentSrc ]] && [[ -f $markdownSrc ]]; then
        if $REFERENCE_VALIDITY; then
            echo -e "\n## Comments *[not verified]*\n" >> $markdownSrc # append comments to md file
        else
            echo -e "\n## Comments\n" >> $markdownSrc # append comments to md file
        fi
        cat $commentSrc >> $markdownSrc
    else
        echo -e "\n## Comments\n" >> $markdownSrc # append comments to md file
        echo "no comments" >> $markdownSrc
    fi
    verification=""
done
fi

# all md files should be linked by pagination for ease of moving through pages
if $VERBOSE; then echo "listing markdown files"; fi
grep "* \[" List.md | sed -r 's/.*\[(.*)\]\((.*)\).*/\1|\2/' | tr " " "~" > pair.list

if $VERBOSE; then echo "inserting pagination"; fi
for pair in $(cat pair.list)
do
    current=$(echo $pair | cut -d"|" -f2 | sed 's/\.\///') # current file in iteration
    previousTopic="$(grep -B 1 "$current" pair.list | grep -v "$current" | cut -d"|" -f1 | tr "~" " ")" # previous page header
    previousPath=$(grep -B 1 "$current" pair.list | grep -v "$current" | cut -d"|" -f2 | sed 's/\.\///') # previous page file path
    nextTopic="$(grep -A 1 "$current" pair.list | grep -v "$current" | cut -d"|" -f1 | tr "~" " ")" # next page header
    nextPath=$(grep -A 1 "$current" pair.list | grep -v "$current" | cut -d"|" -f2 | sed 's/\.\///') # next page file path

    occurance=$(echo "$current" | awk -F "/" '{print NF-1}') # distance of current file from repository root directory
    base=$(printf %$(echo $occurance)s |tr " " "~" | sed 's/~/\.\.\//g') # number of ../ string based on distance

    # previous pagination lines should be removed to prevent duplication
    sed -i '/### Quick Access/,$ d' $current

    # preventing two or more empty lines because it makes markdown syntax warnings
    if [[ $(tail -n1 $current) > "" ]]; then
        echo "" >> $current
    fi

    # this line should be added with no any condition
    echo "### Quick Access" >> $current

    # empty page directions would be avoided as they can make markdown syntax warnings
    if ! [[ -z $previousPath ]]; then
        echo "" >> $current
        echo "#### &#8592; Previous Page" >> $current
        echo "" >> $current
        echo "* [$previousTopic](./$base$previousPath)" >> $current
    fi

    if ! [[ -z $nextPath ]]; then
        echo "" >> $current
        echo "#### &#8594; Next Page" >> $current
        echo "" >> $current
        echo "* [$nextTopic](./$base$nextPath)" >> $current
    fi
done

# count directory levels
grep "README.md" List.md | sed -r 's/.*\((.*)\).*/\1/' | awk -F '/' '{print NR, NF-1}' > count.list
# number lines
grep "README.md" List.md | nl > addr.list
# join two previous files
join count.list addr.list | cut -d" " -f 2- > readme.list
# remove created files
rm -f count.list addr.list
# separate data (number of occurances, title, address)
cat readme.list | sed -r 's/([0-9]).*\[(.*)\]\((.*)\).*/\1|\2|\3/' | tr " " "~" > sections.list

if $VERBOSE; then echo "creating next chapter shortcuts"; fi
for pair in $(cat sections.list | sed -n '/^3.*/p')
do
    current=$(echo $pair | cut -d"|" -f3 | sed 's/\.\///') # current file in iteration
    occurance=$(echo $pair | cut -d"|" -f1) # distance of current file from repository root directory
    nextCname=$(cat sections.list | sed -n '/^3.*/p' | grep -A 1 "$current" | tail -n1 | cut -d"|" -f2 | tr "~" " ")
    nextChapter="$(cat sections.list | sed -n '/^3.*/p' | grep -A 1 "$current" | tail -n1 | cut -d"|" -f3 | sed 's/\.\///')"
    prevCname=$(cat sections.list | sed -n '/^3.*/p' | grep -B 1 "$current" | head -n1 | cut -d"|" -f2 | tr "~" " ")
    prevChapter="$(cat sections.list | sed -n '/^3.*/p' | grep -B 1 "$current" | head -n1 | cut -d"|" -f3 | sed 's/\.\///')"

    level=$(echo "${current}" | awk -F "/" '{print NF-1}') # distance of current file from repository root directory
    base=$(printf %$(echo $level)s |tr " " "~" | sed 's/~/\.\.\//g') # number of ../ string based on distance

    if ! [[ -z $prevCname ]]; then
        sed -i "/# Quick Access/a \\\n#### &#8647; Previous Chapter\n\n* [$prevCname](./$base$prevChapter)" $current
    fi

    if ! [[ -z $nextCname ]]; then
        echo "" >> $current
        echo "#### &#8649; Next Chapter" >> $current
        echo "" >> $current
        echo "* [$nextCname](./$base$nextChapter)" >> $current
    fi
done

if $VERBOSE; then echo "creating section shortcuts"; fi
for pair in $(cat sections.list | sed -n '/^2.*/p')
do
    current=$(echo $pair | cut -d"|" -f3 | sed 's/\.\///') # current file in iteration
    occurance=$(echo $pair | cut -d"|" -f1) # distance of current file from repository root directory
    nextSname=$(cat sections.list | sed -n '/^2.*/p' | grep -A 1 "$current" | tail -n1 | cut -d"|" -f2 | tr "~" " ")
    nextSection="$(cat sections.list | sed -n '/^2.*/p' | grep -A 1 "$current" | tail -n1 | cut -d"|" -f3 | sed 's/\.\///')"
    prevSname=$(cat sections.list | sed -n '/^2.*/p' | grep -B 1 "$current" | head -n1 | cut -d"|" -f2 | tr "~" " ")
    prevSection="$(cat sections.list | sed -n '/^2.*/p' | grep -B 1 "$current" | head -n1 | cut -d"|" -f3 | sed 's/\.\///')"

    level=$(echo "${current}" | awk -F "/" '{print NF-1}') # distance of current file from repository root directory
    base=$(printf %$(echo $level)s |tr " " "~" | sed 's/~/\.\.\//g') # number of ../ string based on distance

    if ! [[ -z $prevSname ]]; then
        sed -i "/# Quick Access/a \\\n#### &#11057; Previous Section\n\n* [$prevSname](./$base$prevSection)" $current
    fi

    if ! [[ -z $nextSname ]]; then
        echo "" >> $current
        echo "#### &#8694; Next Section" >> $current
        echo "" >> $current
        echo "* [$nextSname](./$base$nextSection)" >> $current
    fi
done

echo "numbering markdown headers"
sed -n "/\.md)$/p" List.md | sed -r 's/.*\[(.*)\. .*\]\((.*)\).*/\1 \2/' > head.list
markdown_list=$(sed -n "/\.md)$/p" List.md | sed -r 's/.*\((.*)\).*/\1/')
for mfile in $markdown_list; do
    numbering=$(awk -v filename="$mfile" '$2 == filename {print $1}' head.list)
    sed -i -r "1s/# [0-9. ]*(.*)/# $numbering \1/" $mfile
done

echo "creating single HTML page"
echo '<head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>' > markdown.html
cat README.md >> markdown.html
sed -i 's/  $/<\/br>/' markdown.html
cat List.md | sed -r -n 's/.*\[(.*)\].*$/\1/p' > tboc.list
sed -i -r 's/([0-9.]*)\. (.*)$/\* <a href="#\1">\1 \2<\/a>/' tboc.list
sed -i 'N;/# Table of Content/ r tboc.list' markdown.html
sed -i -e '/\.\/Brief.md/d' -e '/\.\/List.md/d' markdown.html
./markdown2html.sh -e markdown.html
files=$(sed -r -n 's/.*\[.*]\((.*)\)$/\1/p' List.md | sort | xargs)
./markdown2html.sh -a markdown.html $files
sed -i -r 's/href=".*">([0-9.]*)\. (.*)<\/a>/href="#\1">\1 \2<\/a>/' markdown.html

# clean up temp file
find . -name practice | xargs rm -f
rm -f pair.list
rm -f files.list
rm -f file.temp
rm -f readme.list
rm -f sections.list
rm -f tboc.list
rm -r head.list
if $VERBOSE; then echo "junk files removed"; fi
echo "repository refreshed"
