##get average upload/download speed of an ftp server using sftp

###usage
```
./run_ftptest
(generates output.log)
./parse_log.pl > a.html
(generates a.html to open in browser)
```
this is an expect script that calls the `save_output` bash script
all expect does is to interactively provide the sftp password when prompted


or

```
./go.pl
```

link this to your cgi-bin/ to run the script from a web browser





####save_output

runs `script` to save the stdout of the sftp command into `output.log`


####sftp_commands

actual sftp commands to issue in order to upload / download something
in order to generate some output



###notes
generate random files to upload/download with
`dd if=/dev/urandom of=a.random bs=1M count=50`
to get a 50MB file

###todo
* ~~extract data from `output.log` and graph using [google charts](https://google-developers.appspot.com/chart/)~~
* ~~turn this into a cgi program~~

###additional reading
* http://stackoverflow.com/questions/8849240/why-when-i-transfer-a-file-through-sftp-it-takes-longer-than-ftp
* http://www.psc.edu/index.php/hpn-ssh
* https://spoutcraft.org/threads/blazing-fast-sftp-ssh-transfer.7682/
