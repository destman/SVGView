//
//  BPFileStream.cpp
//  Ringtone
//
//  Created by destman on 8/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include <unistd.h>
#include <sys/fcntl.h>
#include <sys/stat.h>

#include "PBFileStream.h"

#pragma mark Input

PBFileInputStream::PBFileInputStream()
{
    _fd = -1;
    _fileSize = 0;
}

PBFileInputStream::~PBFileInputStream()
{
    if(_fd)
    {
        ::close(_fd);
    }
}

bool PBFileInputStream::open(const char *fileName)
{
    struct stat fileInfo; 
    
    if(::stat(fileName,&fileInfo)==0) 
    { 
        _fileSize = fileInfo.st_size;
        _fd = ::open(fileName,O_RDONLY);
        return _fd!=-1;
    } 
    
    _fd = -1;
    return false;
}


bool    PBFileInputStream::Next(const void** data, int* size)
{
    int rv = ::read(_fd, _buff, sizeof(_buff));
    if(rv>0)
    {
        *size = rv;
        *data = _buff;
        return true;
    }
    *size = 0;
    *data = 0;
    return false;
}

void    PBFileInputStream::BackUp(int count)
{
    ::lseek(_fd,-count,SEEK_CUR);
}

bool    PBFileInputStream::Skip(int count)
{
    return ::lseek(_fd,count,SEEK_CUR)>0;
}

int64_t PBFileInputStream::ByteCount() const
{
    return _fileSize;
}


#pragma mark Ouput


PBFileOutputStream::PBFileOutputStream()
{
    _fd = -1;
    _fileSize = 0;
    _haveData = false;
}

PBFileOutputStream::~PBFileOutputStream()
{
    if(_fd)
    {
        if(_haveData)
        {
            ::write(_fd, _buff, sizeof(_buff));
        }
        ::close(_fd);
    }    
}
    
bool    PBFileOutputStream::open(const char *fileName)
{
    ::remove(fileName);
    _haveData = false;
    _fileSize = 0;
    _fd = ::open(fileName, O_WRONLY|O_CREAT,0644);
    return _fd>=0;
}
    
bool    PBFileOutputStream::Next(void** data, int* size)
{
    if(_fd<0)
        return false;
    
    if(_haveData)
    {
        int rv = ::write(_fd, _buff, sizeof(_buff));
        if(rv!=sizeof(_buff))
        {
            return false;
        }
        _fileSize += rv;
    }else
    {
        _haveData = true;
    }
    *data = _buff;
    *size = sizeof(_buff);
    return true;
}

void    PBFileOutputStream::BackUp(int count)
{
    if(_fd<0)
        return;
    int bytesToWrite = sizeof(_buff)-count;
    int rv = write(_fd, _buff, bytesToWrite);
    if(rv!=bytesToWrite)
    {
        return;
    }
    _haveData = false;
    _fileSize+=rv;
}

int64_t PBFileOutputStream::ByteCount() const
{
    return _fileSize;
}
    


