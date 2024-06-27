# Setup

### Clone the repo into your desired Folder

```powershell
cd path/to/folder
git clone https://github.com/Ghrf6/M122-Backup.git
```

💡 only for Windows user

### Install WSL (**Windows-Subsystem for Linux) on your mashine**

```powershell
wsl --install
```

When WSL is run for the first time, you will be asked to create a user account for the Linux distribution:

- Enter a username.
- Enter a password and confirm it.

### Open a new WSL command interface you can do that by searching for Ubuntu

💡 only for Windows user end

## Install rclone in the shell

```bash
sudo apt install rclone
```

### Connect your desired Cloud provider in this case Microsoft OneDrive it

```bash
rclone config
```

### This will be asked type ‘n’ and press enter

```bash
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
```

### For the name type ‘onedrive’ be carefull its case sensitiv

```bash
name> onedrive
```

### Then it will ask you which type of starage you want to use select Microsoft OneDrive by typing ‘21’

```bash
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / 1Fichier
   \ "fichier"
 2 / Alias for an existing remote
   \ "alias"
 3 / Amazon Drive
   \ "amazon cloud drive"
 4 / Amazon S3 Compliant Storage Provider (AWS, Alibaba, Ceph, Digital Ocean, Dreamhost, IBM COS, Minio, etc)
   \ "s3"
 5 / Backblaze B2
   \ "b2"
 6 / Box
   \ "box"
 7 / Cache a remote
   \ "cache"
 8 / Citrix Sharefile
   \ "sharefile"
 9 / Dropbox
   \ "dropbox"
10 / Encrypt/Decrypt a remote
   \ "crypt"
11 / FTP Connection
   \ "ftp"
12 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
13 / Google Drive
   \ "drive"
14 / Google Photos
   \ "google photos"
15 / Hubic
   \ "hubic"
16 / JottaCloud
   \ "jottacloud"
17 / Koofr
   \ "koofr"
18 / Local Disk
   \ "local"
19 / Mail.ru Cloud
   \ "mailru"
20 / Microsoft Azure Blob Storage
   \ "azureblob"
21 / Microsoft OneDrive
   \ "onedrive"
22 / OpenDrive
   \ "opendrive"
23 / Openstack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
24 / Pcloud
   \ "pcloud"
25 / Put.io
   \ "putio"
26 / SSH/SFTP Connection
   \ "sftp"
27 / Transparently chunk/split large files
   \ "chunker"
28 / Union merges the contents of several remotes
   \ "union"
29 / Webdav
   \ "webdav"
30 / Yandex Disk
   \ "yandex"
31 / http Connection
   \ "http"
32 / premiumize.me
   \ "premiumizeme"
Storage> 21
```

### Leave the next two empty by pressing enter

```bash
** See help for onedrive backend at: https://rclone.org/onedrive/ **

Microsoft App Client Id
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_id>
Microsoft App Client Secret
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_secret>
```

### Dont edit the advanced config

```bash
Edit advanced config? (y/n)
y) Yes
n) No
y/n> n
```

### We will use the remote config

```bash
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes
n) No
y/n> y
```

### Then your browser should open up an you can sign in to youre OneDrive account after that chosse your Onedrive type we use OneDrive Personal or Business so type ‘1’

```bash
Choose a number from below, or type in an existing value
 1 / OneDrive Personal or Business
   \ "onedrive"
 2 / Root Sharepoint site
   \ "sharepoint"
 3 / Type in driveID
   \ "driveid"
 4 / Type in SiteID
   \ "siteid"
 5 / Search a Sharepoint site
   \ "search"
Your choice> 1
```

### Select your specific drive

```bash
Found 1 drives, please select the one you want to use:
0: OneDrive (business) id=xy
Chose drive to use:> 0
```

### Confirm the next two

```bash
Found drive 'root' of type 'business', URL: https://some/url
Is that okay?
y) Yes
n) No
y/n> y
--------------------
[onedrive]
token = {foo, bar}
drive_id = foo
drive_type = business
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y
```

### Then you should see your current remotes and the option on what to do next the setup is now finished and you can quit with typing ‘q’

```bash
Current remotes:

Name                 Type
====                 ====
onedrive             onedrive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q
```

# Backup

### There are three variabels that you can change in the backup.sh file

- local_backup_base —> This is the folder path where your local backup is going to be stored
- cloud_backup_base —> This is the folder path where your cloud backup is going to be stored
- root_folder —> this is the root folder and every sub folder will be able to be backuped if they contain a backup.txt file

### If you want a backup to be created from a folder add a backup.txt file

### Run the Script in the Shell

```bash
./backup.sh "backup message"
```

### You have created a backup of the folder localy and in the cloud in the backup.txt file there will be the commands on how to properly restore your data

# Restoring your data

### If you want to restore the Data go to backup.txt in your backup folder, it will be structured something like this

```
Timestamp, data size, message

To restore local data, run:
	./restore_backup.sh <path to backup> <target_directory> local

To restore data from the cloud, run:
	./restore_backup.sh <path to backup> <target_directory> cloud
```

### You can simply change the <target_directory> to an existing local directory where you want  your data to get stored and then run the command again

```bash
./restore_backup.sh /home/backup/demo/10_27-2024.06.27 /home/projects/demo local
# or
./restore_backup.sh onedrive:/backup/demo/10_27-2024.06.27 /home/projects/demo cloud
```
