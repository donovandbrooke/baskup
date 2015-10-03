#!/bin/sh

#  backUpMessages.sh
#  
#
#  Created by Peter Kaminski on 7/17/15.
# Main code can be found at https://github.com/kyro38/MiscStuff/blob/master/OSXStuff/.bashrc
# However I have tweaked it a bit to optimize the result

#Read all information that our python script dug up
while IFS='' read -r line || [[ -n $line ]]; do

#replace your name here
yourname=me

#other vars
contact=$line
arrIN=(${contact//;/ })
contactNumber=${arrIN[2]}

# ddb: if you know the name of the contact number, you can tell this script to only get that info:
if [ "$contactNumber" == "blahblah.com" ] || [ "$contactNumber" == "+10000000000" ]
then

#Get to the home directory
cd
#This path should be the same as the path you use in baskup.sh
# note: ddb: if you change these paths, attachments has a bug where it puts it in ~ directory
cd ./Downloads/baskup-master
#Make a directory specifically for this folder
mkdir $contactNumber
#Now get into the directory
cd $contactNumber
#Perform SQL operations
# ddb: do some basic formatting
sqlite3 -line ~/Library/Messages/chat.db "
select is_from_me,datetime(date + strftime('%s', '2001-01-01 00:00:00'),'unixepoch', 'localtime') as date,datetime(date_read + strftime('%s', '2001-01-01 00:00:00'),'unixepoch', 'localtime') as date_read,text from message where handle_id=(
select handle_id from chat_handle_join where chat_id=(
select ROWID from chat where guid='$line')
)" | sed "s/is_from_me \= 0/$(echo $contactNumber): /g;s/is_from_me \= 1/$(echo $yourname): /g"> $line.txt

cd
cd ./Downloads/baskup-master/$contactNumber
mkdir "Attachments"
cd "Attachments"
#Retrieve the attached stored in the local cache

sqlite3 ~/Library/Messages/chat.db "
select filename from attachment where rowid in (
select attachment_id from message_attachment_join where message_id in (
select rowid from message where cache_has_attachments=1 and handle_id=(
select handle_id from chat_handle_join where chat_id=(
select ROWID from chat where guid='$line')
)))" | cut -c 2- | awk -v home=$HOME '{print home $0}' | tr '\n' '\0' | xargs -0 -t -I fname cp fname .
$line

# end if you know the name of the contact number
fi

done < "$1"
