//
//  BPFileStream.h
//  Ringtone
//
//  Created by destman on 8/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef PBFileStream_h
#define PBFileStream_h

#import <google/protobuf/io/zero_copy_stream.h>

class PBFileInputStream:public google::protobuf::io::ZeroCopyInputStream 
{
public:
    PBFileInputStream();
    virtual ~PBFileInputStream();
    
    bool    open(const char *fileName);
    
    bool    Next(const void** data, int* size);
    void    BackUp(int count);
    bool    Skip(int count);
    int64_t ByteCount() const;
    
private:
    int         _fd;
    int64_t     _fileSize;
    char        _buff[1024];
};

class PBFileOutputStream:public google::protobuf::io::ZeroCopyOutputStream 
{
public:
    PBFileOutputStream();
    virtual ~PBFileOutputStream();
    
    bool    open(const char *fileName);

    bool    Next(void** data, int* size);
    void    BackUp(int count);
    int64_t ByteCount() const;
    
private:
    int         _fd;
    int64_t     _fileSize;
    bool        _haveData;
    char        _buff[1024];
};


#endif
