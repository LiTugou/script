#!/bin/python3
from pyrclonerc import rclonerc,filerename
import sys
import re
import os

gid=sys.argv[1]
filenum=int(sys.argv[2])
filepath=sys.argv[3] # 如果有多个文件仅给一个文件的位置

if filenum<=0:
    exit(1)

user="rclone"
passwd="971d30fd-b5cb-4979-a95c-15f65a69a024"
rclient=rclonerc(user=user,passwd=passwd)

if filenum==1:
    dstFs,dstRemote,upload_flag=filerename(filepath)
    if upload_flag:    
        dstpath=dstFs+dstRemote
        rclient.move(filepath,dstpath)
else:
    rootfolder=os.path.dirname(filepath)
    for item in os.walk(rootfolder):
        filelist=item[2] # item[0] :the folder, item[1]: folder/folder, item[2]: folder/file
        srcFs=os.path.abspath(item[0])
        for file in filelist:
            dstFs,dstRemote,upload_flag=filerename(file)
            if upload_flag:
                rclient._cpapi(op="move",srcFs=srcFs,srcRemote=file,dstFs=dstFs,dstRemote=dstRemote)
            #rclient.move(file,dstFs+dstRemote)
