#!/bin/bash

output=markdown.html
criteria=$(find . -name "[0-9][!0].*.md")

rm -f $output

for file in $criteria; do
    sed '/### Quick Access/,$d' $file >> $output
done

# convert < > &
sed -i -e 's/&/\&amp;/' -e 's/</\&lt;/' -e 's/>/\&gt;/' $output
# convert ~ "
sed -i -e 's/~/\&tilde;/' -e 's/"/\&quot;/' $output

# convert code end of line
sed -i '/^```[a-z]*$/,/^```$/{s/$/<br\/>/}' $output

# convert markdown code section to HTML code section
sed -i -e 's/```[a-z].*/<figure><pre><code>/' -e 's/```[<].*$/<\/code><\/pre><\/figure>/' $output

# remove empty breaks
sed -i '/^<br\/>$/d' $output

# H1
#sed -ri 's/^# (.*)$/<h1>\1<\/h1>/' $output

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

# bold
sed -ri 's/\*\*(.*)\*\*/<b>\1<\/b>/' $output
sed -ri 's/__(.*)__/<b>\1<\/b>/' $output

# italic
sed -ri 's/\*(.*)\*/<i>\1<\/i>/' $output
sed -ri 's/_(.*)_/<i>\1<\/i>/' $output
