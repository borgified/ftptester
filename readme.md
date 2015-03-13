##get average upload/download speed of an ftp server using sftp

###usage
```
./run_ftptest
```
this is an expect script that calls the `save_output` bash script
all expect does is to interactively provide the sftp password when prompted


####save_output

runs `script` to save the stdout of the sftp command into `output.log`


####sftp_commands

actual sftp commands to issue in order to upload / download something
in order to generate some output
