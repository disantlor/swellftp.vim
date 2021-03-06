swellftp.vim
==============

##Description:
This plugin makes it easier to save a file to a remote server (ftp/sftp).

It takes a similar approach to the dirsettings plugin and searches upwards through the directory tree
for a "connection file" named ".swellftp-connection". The connection file is read as a vimscript and 
specifies the server connection settings in the following format:

    let b:swellftp = {
    \     'mode': '',
    \     'user': '',
    \     'hostname': '',
    \     'port': '',
    \     'localroot': '',
    \     'remoteroot': '' 
    \}

__WARNING: ^---don't commit this file!__

Note that `mode` has to be either `ftp` or `sftp`. The paths to localroot and remoteroot must be absolute (start with /) and may not end with a trailing /. For example, `~/website/` is invalid in both ways, the correct path would be `/home/user/website`.

The plugin exposes the command :Up which, when run, compares the location of the current file against
the 'localroot' to determine where to save it on the server. It uses the built in Vim plugin netrw to
actually perform the transfer.

##Notes:
If you're using ssh you'll want to install your key on the server so you don't have to enter your
login info for every command (see :help netrw-ssh-hack) 

##Known Issues:
In sftp mode, the plugin will automatically create any directories it needs in order to save the file. It's not
currently possible to do this using ftp and netrw, so if the folder doesn't exist on the server already the
transfer will fail. Currently trying to work around this. Considering maybe have the plugin require and use lftp.

##TODO:
-Only try to mkdir once (cache mkdir command and check cache on subsequent attempts?)

Also, this is my first Vim plugin (just switched to using Vim and found the save to ftp feature missing), so any
improvements are appreciated.
