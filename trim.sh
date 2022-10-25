#!/bin/bash
### ===== ffmpeg COMMAND USAGE =====
### PART OF FILE
### $ ffmpeg -ss 00:00:00 -i input.mp4 -to 01:42:40 -c copy output1.mp4
### $ 
### $ ffmpeg -ss 01:44:40 -i input.mp4 -to 02:42:40 -c copy output2.mp4
### $ 
### LAST PART OF FILE
### $ ffmpeg -ss 02:43:07 -i input.mp4 -c copy output3.mp4
### $ 
### $ CONCAT ALL PARTS OF FILE
### $ cat concat.txt 
### file output1.mp4
### file output2.mp4
### file output3.mp4
### $ 
### $ ffmpeg -f concat -safe 0 -i concat.txt -c copy output.mp4
### $ 
### ===== trim.sh SCRIPT USAGE =====
### (1)
### PUT TIMESTAMPS TO TRIM IN TXT FILE (MAKE SURE TO MAINTAIN THE SEQUENCE)
### EXAMPLE:
### Create trim.txt file as below for three cuts in the file at given timestamp:
### $ cat trim.txt 
### 0:15:05 0:15:15
### 0:36:48 0:36:59
### 01:29:04 01:31:12
###
### (2)
### RUN SCRIPT
### $ trim.sh file.mp4
### (3)
### TRIMED OUTPUT IN aks-file.mp4
### ===== HOW SCRIPT WORKS =====
### trim.sh reads timestamps to be cur from trim.txt
### It creates new timestamp file trim-new.txt for timestamps to be preserved
### It the creates trimcmds.sh file with the commands to be run in file.mp4 to cut it in parts as per trim-new.txt
### It also creates  concat.txt file with the parts of the trimmed files
### Finally it concats all the parts and creates aks-file.mp4


function PrintUsage()
{
echo -e "PREREQUISITE:
Timestamps to cut in trim.txt file
Example:
cat trim.txt
0:15:05 0:15:15
0:36:48 0:36:59
01:29:04 01:31:12
"

echo -e "USAGE:
echo -e "$0 file.mp4"

echo -e "OUTPUT:
echo -e "Trimed contents in aks-file.mp4"
}

function GenerateTrimFile()
{
:> trim-new.txt
echo -e "Generating actual trim file"
while read line
do
  echo "DEBUG: Line $line"
  tf=$(echo $line | cut -d ' ' -f1)
  tt=$(echo $line | cut -d ' ' -f2)
  echo -e "DEBUG: Processing trim no: $i of cuts: $cuts"
  echo -e "DEBUG: Trimming from $tf to $tt"
  if [[ $i -eq 1 ]]
  then
    trimf="00:00:00"
    trimt=$tf
  fi
  trimt=$tf
  echo "$trimf $trimt" >> trim-new.txt
  if [[ "$i" == "$cuts" ]]
  then
      ##echo -e "END"
      echo -e "$tt" >> trim-new.txt
  fi
  ((i=i+1))
  trimf=$tt

done < trim.txt
}

GenerateTrimCmdsFile()
{
:> trimcmds.sh
:> concat.txt
echo -e "Grnerating trim commands file"
while read line
do
  echo -e "DEBUG: Processing trim no: $i"
  echo -e "DEBUG: Processing line: $line"
  
  s=$(echo "$line" | cut -d ' ' -f1)
  t=$(echo "$line" | cut -d ' ' -f2)
  if [[ "$i" != "$cuts" ]]
  then
    echo -e "DEBUG: Trimming from $s to $t"
    cmd=$(echo -e "ffmpeg -loglevel quiet -y -i $file.$extn -ss $s -to $t -c copy $file-$i.$extn")
    ##echo "RUNNING: $cmd"
    echo $cmd >> trimcmds.sh
    echo -e "file $file-$i.$extn" >> concat.txt
  fi

  if [[ "$i" == "$cuts" ]]
  then
    ##echo -e "LAST"
    cmd=$(echo -e "ffmpeg -loglevel quiet -y -i $file.$extn -ss $s -c copy $file-$i.$extn")
    ##echo "RUNNING: $cmd"
    echo $cmd >> trimcmds.sh
    echo -e "file $file-$i.$extn" >> concat.txt
  fi
  ((i=i+1))
done < trim-new.txt
}

if [[ $# -ne 1 ]]
then
PrintUsage
exit 1
fi

if [[ ! -f trim.txt ]] ; then
echo 'File "trim.txt" does not exist, aborting.'
PrintUsage
exit 1
fi

if [[ ! -f $1 ]] ; then
echo 'File "$1" does not exist, aborting.'
PrintUsage
exit 1
fi

file=$(echo $1 | rev | awk -F. '{print $2}' | rev)
extn=$(echo $1 | rev | awk -F. '{print $1}' | rev)

echo -e "DEBUG: File name: $file"
echo -e "DEBUG: Extension: $extn"

i=1
cuts=$(wc -l trim.txt| cut -d ' ' -f1)
echo -e "DEBUG: Number of cuts: $cuts"

GenerateTrimFile


i=1
cuts=$(wc -l trim-new.txt| cut -d ' ' -f1)
echo -e "DEBUG: Number of cuts: $cuts"

GenerateTrimCmdsFile

echo -ne "Running trim commands . . . "
sh trimcmds.sh
echo -e "done"

echo -ne "Concating files . . . "
ffmpeg -y -loglevel quiet -f concat -safe 0 -i concat.txt -c copy aks-$file.$extn
echo -e "done"


echo -ne "Cleaning temporary files . . . "
rm -f $file-*.$extn
rm trimcmds.sh
echo -e "done"
