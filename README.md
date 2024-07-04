# Overview

This script enables the creation of local and cloud backups of files and directories and allows for their restoration when needed. It includes functions to encrypt the data for secure storage and provides an easy way to manage and secure backups.

## Youtube Video
https://youtu.be/XCC8TcOrr4I

## Features

### Backup Creation

- **Local Backup:** Creates an encrypted backup on local storage.
- **Cloud Backup:** Copies the encrypted backup to cloud storage (supported by `rclone`).

### Data Encryption

- The data to be backed up is encrypted with a password of your choosing to prevent unauthorized access.

### Backup Restoration

- **Local Restoration:** Decrypts and restores data from a local backup.
- **Cloud Restoration:** Decrypts and restores data from a cloud backup.

# Setup

### Clone the repo into your desired folder

```powershell
cd path/to/folder
git clone https://github.com/Ghrf6/M122-Backup.git
```

💡 Only for Windows users

### Install WSL (Windows Subsystem for Linux) on your machine

```powershell
wsl --install
```

When WSL is run for the first time, you will be asked to create a user account for the Linux distribution:

- Enter a username.
- Enter a password and confirm it.

### Open a new WSL command interface by searching for Ubuntu

💡 Only for Windows users end

## Install rclone in the shell

```bash
sudo apt install rclone
```

### Connect your desired cloud provider (in this case, Microsoft OneDrive)

```bash
rclone config
```

### This will be asked, type ‘n’ and press enter

```bash
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
```

### For the name, type ‘onedrive’. Be careful, it's case-sensitive.

```bash
name> onedrive
```

### Then it will ask you which type of storage you want to use. Select Microsoft OneDrive by typing the number next to your desired cloud provider.

```bash
Type of storage to configure.
Choose a number from below, or type in your own value
n  / Microsoft OneDrive
   \ "onedrive"
Storage> n
```

### Leave the next two fields empty by pressing enter

```bash
Enter a string value. Press Enter for the default ("").
client_id>
Enter a string value. Press Enter for the default ("").
client_secret>
```

### Do not edit the advanced config

```bash
Edit advanced config? (y/n)
y) Yes
n) No
y/n> n
```

### Use the auto config

```bash
Use auto config?
y) Yes
n) No
y/n> y
```

### Then your browser should open, and you can sign in to your OneDrive account. After that, choose your OneDrive type. We use OneDrive Personal or Business, so type ‘1’.

```bash
Choose a number from below, or type in an existing value
 1 / OneDrive Personal or Business
   \ "onedrive"
Your choice> 1
```

### Select your specific drive

```bash
Found 1 drives, please select the one you want to use:
0: OneDrive (business) id=xy
Choose drive to use:> 0
```

### Confirm the next two prompts

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

### Then you should see your current remotes and the option on what to do next. The setup is now finished, and you can quit by typing ‘q’.

```bash
Current remotes:
Name                 Type
====                 ====
onedrive             onedrive
e/n/d/r/c/s/q> q
```

# Backup

### There are three variables that you can change in the `backup.sh` file

- `default_local_backup_base` —> This is the folder path where your local backup is going to be stored.
- `default_cloud_backup_base` —> This is the folder path where your cloud backup is going to be stored.
- `root_folder` —> This is the root folder, and every subfolder will be backed up if they contain a `backup.txt` file.

### If you want a backup to be created from a folder, add a `backup.txt` file.

### Run the script in the shell. You can also change the path to your backup and leave a descriptive message for the backup.

```bash
./backup.sh [options] [message]
```

Options:

- `-l`: Specify the local backup directory (default: /mnt/c/Backup)
- `-c`: Specify the cloud backup directory (default: onedrive:/Backup)
- `-h, --help`: Show the help message

### You have created a backup of the folder locally and in the cloud. In the `backup.txt` file, there will be the commands on how to properly restore your data.

# Restoring your data

### First you need to change the RCLONE_CONFIG variabel to the correct path you can do that by typing in this command:

```bash
rclone config file
```
### Then change to value of the variabel to the shown path

### If you want to restore the data, go to `backup.txt` in your backup folder. It will be structured something like this:

```
Timestamp, message

To restore local data, run:
	./restore_backup.sh <path to backup> <target_directory> local

To restore data from the cloud, run:
	./restore_backup.sh <path to backup> <target_directory> cloud
```

### You can simply change the `<target_directory>` to an existing local directory where you want your data to be stored and then run the command again:

```bash
./restore_backup.sh <path to backup> <target_directory> local
# or
./restore_backup.sh <path to backup> <target_directory> cloud
```

# Automate the backup

### To automate a task you can use a cron job
### Open up the crontab file with the following command: 

```bash
crontab -e
```
### Then select your prefered file editor and in the file add the following

```bash
30 11 * * * /path/to/backup.sh
30 16 * * * /path/to/backup.sh
```

### This will make it so that everyday at 11:30 AM and 4:30 PM it will execute the script and create a backup

### Save and exit the editor
- For vim, save and exit by typing :wq and pressing Enter.
- For nano, save and exit by pressing Ctrl+X, then Y, and then Enter.
