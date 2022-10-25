# trim
script to trim viode file

## ffmpeg COMMAND USAGE

TRIM PART OF FILE
```
$ ffmpeg -ss 00:00:00 -i input.mp4 -to 01:42:40 -c copy output1.mp4
$ ffmpeg -ss 01:44:40 -i input.mp4 -to 02:42:40 -c copy output2.mp4
```
TRIM LAST PART OF FILE
```
$ ffmpeg -ss 02:43:07 -i input.mp4 -c copy output3.mp4
```
CONCAT PARTS OF FILE
```
$ cat concat.txt 
file output1.mp4
file output2.mp4
file output3.mp4
$ 
$ ffmpeg -f concat -safe 0 -i concat.txt -c copy output.mp4
```
## trim.sh SCRIPT USAGE
(1)
PUT TIMESTAMPS TO TRIM IN TXT FILE (MAKE SURE TO MAINTAIN THE SEQUENCE)
EXAMPLE:
Create trim.txt file as below for three cuts in the file at given timestamp:
```
$ cat trim.txt 
0:15:05 0:15:15
0:36:48 0:36:59
01:29:04 01:31:12
```
(2)
RUN SCRIPT
```
$ trim.sh file.mp4
```
(3)
TRIMED OUTPUT IN aks-file.mp4

## HOW SCRIPT WORKS
- trim.sh reads timestamps to be cur from trim.txt
- It creates new timestamp file trim-new.txt for timestamps to be preserved
- It the creates trimcmds.sh file with the commands to be run in file.mp4 to cut it in parts as per trim-new.txt
- It also creates  concat.txt file with the parts of the trimmed files
- Finally it concats all the parts and creates aks-file.mp4

