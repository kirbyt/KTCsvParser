/*
//
//  KTBufferedStreamReader.m
//
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//
//  The MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
*/

#import "KTBufferedStreamReader.h"



@implementation KTBufferedStreamReader

@synthesize inputStream = _inputStream;

- (void)dealloc
{
   [_inputStream release], _inputStream = nil;
   [super dealloc];
}

- (void)setup
{
   _isInputStreamOpen = NO;
   _position = -MAX_BUFFER_SIZE;
   _bufferLength = 0;
}

- (id)initWithInputStream:(NSInputStream *)inputStream
{
   self = [super init];
   if (self) {
      [self setInputStream:inputStream];
      [self setup];
   }
   return self;
}

- (void)open
{
   if (_isInputStreamOpen == NO) {
      [_inputStream open];
      _isInputStreamOpen = YES;
   }
}

- (void)close
{
   if (_isInputStreamOpen == YES) {
      [_inputStream close];
      _isInputStreamOpen = NO;
   }
}

- (BOOL)fillInternalBuffer
{
   BOOL success = NO;
   memset(_buffer, 0, sizeof(uint8_t) * MAX_BUFFER_SIZE);
   if ([_inputStream hasBytesAvailable] == YES) {
      _bufferLength = [_inputStream read:_buffer maxLength:MAX_BUFFER_SIZE];
      _position = 0;
      success = (_bufferLength > 0);
   }
   return success;
}

- (BOOL)read:(NSString **)text maxLength:(NSUInteger)length
{
   NSAssert(length < MAX_BUFFER_SIZE, @"This function is not designed to retrieve data bigger than the maximum buffer size.");
   
   BOOL success = NO;
   if (length > 0 && text != NULL) {
      // Copy the buffer data into the string.
      NSMutableData *data = [[NSMutableData alloc] init];
      NSInteger bytesLeft = length;
      
      // Try reading what's left in the internal buffer.
      NSInteger firstBufferRead = MAX_BUFFER_SIZE - _position;
      if (firstBufferRead < 0 || firstBufferRead > MAX_BUFFER_SIZE) {
         firstBufferRead = 0;
      }
      firstBufferRead = (firstBufferRead < bytesLeft) ? firstBufferRead : bytesLeft;
      if (firstBufferRead > 0) {
         if (_position < _bufferLength) {
            [data appendBytes:&_buffer[_position] length:firstBufferRead];
         }
         bytesLeft -= firstBufferRead;
      }
      
      if (bytesLeft > 0) {
         // If the request is to NOT advance the buffer pointer
         // then we must pre-fill the buffer.
         if ([self fillInternalBuffer]) {
            [data appendBytes:&_buffer[_position] length:bytesLeft];
         }
      }

      *text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
      [data release];
      _position += length;
      success = YES;
   }
   
   return success;
}

- (BOOL)isOpen
{
   return _isInputStreamOpen;
}

- (BOOL)isAtEnd
{
   if (_position > _bufferLength) return YES;
   
   return NO;
}


@end
