#!/bin/bash

output=markdown.html
temp=markdown.tmp
readme=readme.tmp
links=links.tmp
criteria=$(find . -name "[0-9][!0].*.md" | sort)

rm -f $output

# include README page
cat README.md > $readme

# links on readme
sed -rn 's/^\[([0-9]*)\]: (.*)$/\1 \2/p' $readme > $links

# H1 only for readme
sed -ri 's/^# (.*)$/<h1>\1<\/h1>/' $readme

# make newlines
sed -i 's/$/<br\/>/' $readme
sed -i 's/^<br\/>$//' $readme

# unordered lists
sed -ri 's/^\* (.*)<br\/>$/<li>\1<\/li>/' $readme
sed -i '/^$/,/^<li>/ s/<li>/<ul><li>/' $readme
awk 'NR==1 {line=$0} /^$/ {gsub(/<\/li>/,"</li></ul>",line)} {print line; line=$0} END {print line}' $readme > $temp
sed -i '1d' $temp

# remove links
sed -i '/^\[[0-9]*\]: /d' $temp

cat $temp > $readme
rm -f $temp
for file in $criteria; do
    sed '/### Quick Access/,$d' $file >> $temp
    # links on each practice page
    sed -rn 's/^\[([0-9]*)\]: (.*)$/\1@\2/p' $temp >> $links
    # remove links
    sed -i '/^\[[0-9]*\]: /d' $temp
done

# convert &
sed -i -e 's/&/\&amp;/'g $temp
# convert < >
sed -i -e 's/</\&lt;/'g -e 's/>/\&gt;/'g $temp
# convert ~ "
sed -i -e 's/~/\&tilde;/'g -e 's/"/\&quot;/'g $temp
# convert _
sed -i -e 's/_/\&lowbar;/'g $temp

cat $readme >> $output
#cat Brief.md >> $output
cat $temp >> $output
rm -f $readme $temp $links

# convert code end of line
sed -i '/^```[a-z]*$/,/^```$/{s/$/<br\/>/}' $output

# convert markdown code section to HTML code section
sed -i -e 's/```[a-z].*/<figure><pre><code>/' -e 's/```[<].*$/<\/code><\/pre><\/figure>/' $output

# remove empty breaks
sed -i '/^<br\/>$/d' $output

# make breaks for double spaces
sed -i 's/  $/<br\/>/' $output

# H2
sed -ri 's/^# (.*)$/<h2>\1<\/h2>/' $output

# H3
sed -ri 's/^## (.*)$/<h3>\1<\/h3>/' $output

# H4
sed -ri 's/^### (.*)$/<h4>\1<\/h4>/' $output

# H5
sed -ri 's/^#### (.*)$/<h5>\1<\/h5>/' $output

# H6
sed -ri 's/^##### (.*)$/<h6>\1<\/h6>/' $output 

# unordered list
sed -i -r 's/^\* (.*)$/<li>\1<\/li>/' $output

# bold
sed -ri 's/\*\*([0-9a-zA-Z. -"]*)\*\*/<b>\1<\/b>/'g $output
sed -ri 's/__([0-9a-zA-Z. -"]*)__/<b>\1<\/b>/'g $output

# italic
sed -ri 's/\*([0-9a-zA-Z. -"]*)\*/<i>\1<\/i>/'g $output
sed -ri 's/_([0-9a-zA-Z. -"]*)_/<i>\1<\/i>/'g $output

# convert _
sed -i -e 's/_/\&lowbar;/' $output
