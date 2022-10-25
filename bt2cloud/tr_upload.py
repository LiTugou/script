#!/bin/python3
from pyrclonerc import rclonerc,filerename
import re
import os

rootfolder=os.environ["TR_TORRENT_DIR"] #
# label=os.environ["TR_TORRENT_LABELS"]

user="rclone"
passwd="971d30fd-b5cb-4979-a95c-15f65a69a024"
rclient=rclonerc(user=user,passwd=passwd)

rootfolder=os.path.abspath(rootfolder)
for item in os.walk(rootfolder):
    filelist=item[2] # item[0] :the folder, item[1]: folder/folder, item[2]: folder/file
    srcFs=item[0]
    for file in filelist:
        dstFs,dstRemote,upload_flag=filerename(file)
        if upload_flag:
            rclient._cpapi(op="move",srcFs=srcFs,srcRemote=file,dstFs=dstFs,dstRemote=dstRemote)

