/*
 //
 //  KTCsvParser.m
 //  KTCsvParser
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

#import "KTCsvParser.h"
#import "KTBufferedStreamReader.h"


#define STATE_UNKNOWN 0
#define STATE_CONTINUE_WITH_REGULAR_FIELD 1
#define STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS 2
#define STATE_BEGINNING_OF_EMBEDDED_QUOTES 3


@interface KTCsvParser ()
@property (nonatomic, copy) NSString *nextCharacter;
@property (nonatomic, strong) KTBufferedStreamReader *reader;
@property (nonatomic, strong) NSMutableArray *mutableValues;
@end

@implementation KTCsvParser

- (void)commonInit
{
   [self setValueSeparator:@","];
   [self setQuoteCharacter:@"\""];
   [self setTrimValues:NO];
}

- (id)initWithData:(NSData *)data
{
   self = [super init];
   if (self) {
      NSInputStream *inputStream = [[NSInputStream alloc] initWithData:data];
      KTBufferedStreamReader *reader = [[KTBufferedStreamReader alloc] initWithInputStream:inputStream];
      [self setReader:reader];
      [self commonInit];
   }
   return self;
}

- (id)initWithFileAtPath:(NSString *)path
{
   self = [super init];
   if (self) {
      NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
      KTBufferedStreamReader *reader = [[KTBufferedStreamReader alloc] initWithInputStream:inputStream];
      [self setReader:reader];
      [self commonInit];
   }
   return self;
}

- (id)initWithInputStream:(NSInputStream *)inputStream
{
   self = [super init];
   if (self) {
      KTBufferedStreamReader *reader = [[KTBufferedStreamReader alloc] initWithInputStream:inputStream];
      [self setReader:reader];
      [self commonInit];
   }
   return self;
}

- (id)initWithURL:(NSURL *)url
{
   self = [super init];
   if (self) {
      NSInputStream *inputStream = [[NSInputStream alloc] initWithURL:url];
      KTBufferedStreamReader *reader = [[KTBufferedStreamReader alloc] initWithInputStream:inputStream];
      [self setReader:reader];
      [self commonInit];
   }
   return self;
}

- (BOOL)readNextCharacter:(NSString **)character
{
   // Retrieve the next character. Note that the
   // next character maybe queued. This allows
   // us to peek at the next character without
   // moving forward through the buffer.
   
   BOOL success = YES;
   if ([self nextCharacter]) {
      *character = [self nextCharacter];
      [self setNextCharacter:nil];
   } else {
      success = [[self reader] read:character maxLength:1];
   }
   return success;
}

- (BOOL)isAtEnd
{
   // We are at the end when we have no next character queued
   // up and the input stream reader is at it's end.
   BOOL isAtEnd = (![self nextCharacter] && [[self reader] isAtEnd]);
   return isAtEnd;
}

- (BOOL)isEndOfLine
{
   if ([self isAtEnd]) {
      return YES;
   }
   
   // We need to check the next character but we do not
   // want to advance the buffer pointer. Unfortunately
   // NSInputStream is forward-only, so we queue up the
   // next character.
   BOOL endOfLine = YES;
   NSString *character = nil;
   BOOL success = [self readNextCharacter:&character];
   if (success) {
      [self setNextCharacter:character];
      
      if ([character isEqualToString:@"\r"] || [character isEqualToString:@"\n"]) {
         endOfLine = YES;
      } else {
         endOfLine = NO;
      }
   }
   
   return endOfLine;
}

- (void)skipNewLineCharacters
{
   KTBufferedStreamReader *reader = [self reader];
   if ([reader isAtEnd] == NO) {
      NSString *character = nil;
      [self readNextCharacter:&character];
      if ([reader isAtEnd] == NO) {
         NSString *nextCharacter = nil;
         [self readNextCharacter:&nextCharacter];
         [self setNextCharacter:nextCharacter];
         if ([character isEqualToString:@"\r"] && [nextCharacter isEqualToString:@"\n"]) {
            [self readNextCharacter:&character];
         }
      }
   }
}

- (void)readLineFromReader
{
   int state = STATE_UNKNOWN;
   NSMutableString *value;
   while ([self isAtEnd] == NO && ([self isEndOfLine] == NO || state == STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS)) {
      
      NSString *character = nil;
      [self readNextCharacter:&character];
      
      switch (state) {
         case STATE_UNKNOWN:
         {
            value = [NSMutableString string];
            if ([character isEqualToString:[self quoteCharacter]]) {
               state = STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS;
            } else if ([character isEqualToString:[self valueSeparator]]) {
               // Empty field value.
               [self addValue:value];
               if ([self isEndOfLine]) {
                  [self addValue:@""];
               }
            } else {
               // Start of regular field value.
               [value appendString:character];
               state = STATE_CONTINUE_WITH_REGULAR_FIELD;
               if ([self isEndOfLine]) {
                  [self addValue:value];
               }
            }
            break;
         }
            
         case STATE_CONTINUE_WITH_REGULAR_FIELD:
         {
            if ([character isEqualToString:[self valueSeparator]]) {
               [self addValue:value];
               if ([self isEndOfLine]) {
                  [self addValue:@""];
               } else {
                  state = STATE_UNKNOWN;
               }
            } else {
               [value appendString:character];
               if ([self isEndOfLine]) {
                  [self addValue:value];
               }
            }
            break;
         }
            
         case STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS:
         {
            if ([character isEqualToString:_quoteCharacter]) {
               if ([self isEndOfLine] == NO) {
                  if ([self nextCharacter] && [[self nextCharacter] isEqualToString:[self valueSeparator]]) {
                     // End of embedded comma value.
                     state = STATE_CONTINUE_WITH_REGULAR_FIELD;
                  } else {
                     state = STATE_BEGINNING_OF_EMBEDDED_QUOTES;
                  }
               } else {
                  // End of value since we're at the end of the line.
                  [self addValue:value];
                  state = STATE_UNKNOWN;
               }
            } else {
               [value appendString:character];
            }
            break;
         }
            
         case STATE_BEGINNING_OF_EMBEDDED_QUOTES:
         {
            if ([character isEqualToString:[self quoteCharacter]]) {
               [value appendString:character];
               state = STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS;
            } else {
               // The value has a set of embedded quotes but the entire
               // value is NOT enclosed in quotes. Put the quotes back
               // on the current value and continue processing as if a
               // regular value.
               if ([self isEndOfLine] == NO) {
                  state = STATE_CONTINUE_WITH_REGULAR_FIELD;
                  [value appendFormat:@"%@%@%@%@", [self quoteCharacter], value, [self quoteCharacter], character];
               }
            }
            break;
         }
            
      } // End switch (state)
   } // End whilte ([_reader isAtEnd]...)
   
   [self skipNewLineCharacters];
}

- (BOOL)readLine
{
   // Clear existing values.
   [self setMutableValues:nil];
   [self setMutableValues:[[NSMutableArray alloc] init]];
   
   // Make sure the reader is open.
   KTBufferedStreamReader *reader = [self reader];
   if ([reader isOpen] == NO) {
      [reader open];
   }
   
   BOOL success = NO;
   if ([self isAtEnd] == NO) {
      [self readLineFromReader];
      success = YES;
   }
   
   return success;
}

- (void)addValue:(NSString *)value
{
   NSMutableArray *values = [self mutableValues];

   if ([self trimValues]) {
      NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      [values addObject:trimmed];
   } else {
      [values addObject:value];
   }
}

- (NSArray *)values
{
   return [[self mutableValues] copy];
}

#pragma mark - Class Methods

+ (NSArray*)valuesFromCsvLine:(NSString *)csvLineString withValueSeparator:(NSString *)valueSeparator
{
   return [self valuesFromCsvLine:csvLineString withValueSeparator:valueSeparator trimmed:NO];
}

+ (NSArray*)valuesFromCsvLine:(NSString *)csvLineString withValueSeparator:(NSString *)valueSeparator trimmed:(BOOL)trim
{
   NSArray *values = nil;
   
   NSData *data = [csvLineString dataUsingEncoding:NSUTF8StringEncoding];
   NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
   
   KTCsvParser *parser = [[KTCsvParser alloc] initWithInputStream:inputStream];
   [parser setValueSeparator:valueSeparator];
   [parser setTrimValues:trim];
   if ([parser readLine]) {
      values = [parser values];
   }
   
   return values;
}


@end
