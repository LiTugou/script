#!/bin/python3
import requests
import json
import os
import re

def filerename(filepath):
    upload_flag=True
    basename=os.path.basename(filepath)
    if basename[:9].lower()=="[gm-team]":
        reg=r"\[[^\[]*\]"
        reginfo=r"\[([^\[]*)\]"
        regex=re.compile(reg*2+reginfo+".*"+reginfo*2+reg+reginfo+"(\..*)")
        title,episod,cfmt,clarity,suffix=re.search(regex,basename).groups()
        remote=f"动漫/{title}/{clarity}-{cfmt}/{episod}{suffix}"
        fs="onedrive:"
    else:
        fs=""
        remote=""
        upload_flag=False
    return fs,remote,upload_flag

def parsercpath(rcpath):
    index=rcpath.find(":")+1
    if index!=0:
        fs=rcpath[:index]
        remote=rcpath[index:]
    else:
        fs=os.path.dirname(os.path.abspath(rcpath))
        remote=os.path.basename(rcpath)
    return fs,remote

class rclonerc():
    def __init__(self,addr="127.0.0.1:5572",user=None,passwd=None):
        self.server=f"http://{addr}/"
        self.auth=(user,passwd)
        
    def copy(self,srcpath,dstpath):
        srcFs,srcRemote=parsercpath(srcpath)
        dstFs,dstRemote=parsercpath(dstpath)
        jsdata={
            "srcFs":srcFs,
            "srcRemote":srcRemote,
            "dstFs":dstFs,
            "dstRemote":dstRemote,
            "_async":True
        }
        url=self.server+"operations/copyfile"
        req=requests.post(url,auth=self.auth,json=jsdata)
        jobid=req.json()["jobid"]
        # err=self.status(jobid)["error"]
        # if err:print(err)
        return jobid
    
    def move(self,srcpath,dstpath):
        srcFs,srcRemote=parsercpath(srcpath)
        dstFs,dstRemote=parsercpath(dstpath)
        jsdata={
            "srcFs":srcFs,
            "srcRemote":srcRemote,
            "dstFs":dstFs,
            "dstRemote":dstRemote,
            "_async":True,
        }
        url=self.server+"operations/movefile"
        req=requests.post(url,auth=self.auth,json=jsdata)
        jobid=req.json()["jobid"]
        print(jobid)
        return jobid
    
    def _cpapi(self,srcFs,srcRemote,dstFs,dstRemote,op="copy"):
        assert(op=="copy" or op=="move")
        url=self.server+f"operations/{op}file"
        jsdata={
            "srcFs":srcFs,
            "srcRemote":srcRemote,
            "dstFs":dstFs,
            "dstRemote":dstRemote,
            "_async":True,
        }
        req=requests.post(url,auth=self.auth,json=jsdata)
        jobid=req.json()
        return jobid

    def copyurl(self,url,dstpath):
        dstFs,dstRemote=parsercpath(dstpath)
        jsdata={
            "fs":dstFs,
            "remote":dstRemote,
            "url":url,
            "autoFilename":True,
            "_async":True
        }
        url=self.server+"operations/copyurl"
        req=requests.post(url,auth=self.auth,json=jsdata)
        jobid=req.json()["jobid"]
        return jobid
    
    def delfile(self,path):
        fs,remote=parsercpath(path)
        jsdata={
            "fs":fs,
            "remote":remote,
        }
        url=self.server+"operations/deletefile"
        req=requests.post(url,auth=self.auth,json=jsdata)
        return req.json()
    
    def purge(self,path):
        fs,remote=parsercpath(path)
        jsdata={
            "fs":fs,
            "remote":remote,
        }
        url=self.server+"operations/purge"
        req=requests.post(url,auth=self.auth,json=jsdata)
        return req.json()
    
    def checkstatus(self,jobid):
        st=self.status(jobid)
        if st['finished']:
            if st['success']:
                print("success")
            else:
                print(st['error'])
        else:
            print("runing")

    def status(self,jobid):
        jsdata={"jobid":jobid}
        url=self.server+"job/status"
        req=requests.post(url,auth=self.auth,json=jsdata)
        return req.json()
