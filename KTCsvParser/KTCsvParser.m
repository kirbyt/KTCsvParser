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
@end

@implementation KTCsvParser

@synthesize valueSeparator = _valueSeparator;
@synthesize quoteCharacter = _quoteCharacter;
@synthesize nextCharacter = _nextCharacter;

- (void)dealloc
{
   [_reader close];
   [_reader release], _reader = nil;

   [_values release], _values = nil;
   [_valueSeparator release], _valueSeparator = nil;
   [_quoteCharacter release], _quoteCharacter = nil;
   [_nextCharacter release], _nextCharacter = nil;
   
   [super dealloc];
}

- (void)setup
{
   [self setValueSeparator:@","];
   [self setQuoteCharacter:@"\""];
}

- (id)initWithInputStream:(NSInputStream *)inputStream
{
   self = [super init];
   if (self) {
      _reader = [[KTBufferedStreamReader alloc] initWithInputStream:inputStream];
      [self setup];
   }
   return self;
}

- (NSString *)getNextCharacterWithAdvancePosition:(BOOL)advancePosition
{
   NSString *character = nil;
   BOOL success = [_reader read:&character maxLength:1];
   NSLog(@"success: %i", success);
   
   return character;
}

- (BOOL)readNextCharacter:(NSString **)character
{
   // Retrieve the next character. Note that the
   // next character maybe queued. This allows
   // us to peek at the next character without
   // moving forward through the buffer.
   
   BOOL success = YES;
   if (_nextCharacter) {
      *character = [[_nextCharacter copy] autorelease];
      [self setNextCharacter:nil];
   } else {
      success = [_reader read:character maxLength:1];
   }
   return success;
}

- (BOOL)isAtEnd
{
   // We are at the end when we have no next character queued
   // up and the input stream reader is at it's end.
   BOOL isAtEnd = (!_nextCharacter && [_reader isAtEnd]);
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
   if ([_reader isAtEnd] == NO) {
      NSString *character = nil;
      [self readNextCharacter:&character];
      if ([_reader isAtEnd] == NO) {
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
   while ([self isAtEnd] == NO && [self isEndOfLine] == NO || state == STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS) {
      
      NSString *character = nil;
      [self readNextCharacter:&character];
      
      switch (state) {
         case STATE_UNKNOWN:
         {
            value = [NSMutableString string];
            if ([character isEqualToString:_quoteCharacter]) {
               state = STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS;
            } else if ([character isEqualToString:_valueSeparator]) {
               // Empty field value.
               [_values addObject:value];
               if ([self isEndOfLine]) {
                  [_values addObject:@""];
               }
            } else {
               // Start of regular field value.
               [value appendString:character];
               state = STATE_CONTINUE_WITH_REGULAR_FIELD;
               if ([self isEndOfLine]) {
                  [_values addObject:value];
               }
            }
            break;
         }
            
         case STATE_CONTINUE_WITH_REGULAR_FIELD:
         {
            if ([character isEqualToString:_valueSeparator]) {
               [_values addObject:value];
               if ([self isEndOfLine]) {
                  [_values addObject:@""];
               } else {
                  state = STATE_UNKNOWN;
               }
            } else {
               [value appendString:character];
               if ([self isEndOfLine]) {
                  [_values addObject:value];
               }
            }
            break;
         }
            
         case STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS:
         {
            if ([character isEqualToString:_quoteCharacter]) {
               if ([self isEndOfLine] == NO) {
                  if (_nextCharacter && [_nextCharacter isEqualToString:_valueSeparator]) {
                     // End of embedded comma value.
                     state = STATE_CONTINUE_WITH_REGULAR_FIELD;
                  } else {
                     state = STATE_BEGINNING_OF_EMBEDDED_QUOTES;
                  }
               } else {
                  // End of value since we're at the end of the line.
                  [_values addObject:value];
                  state = STATE_UNKNOWN;
               }
            } else {
               [value appendString:character];
               if ([self isEndOfLine]) {
                  [_values addObject:value];
                  state = STATE_UNKNOWN;
               }
            }
            break;
         }
            
         case STATE_BEGINNING_OF_EMBEDDED_QUOTES:
         {
            if ([character isEqualToString:_quoteCharacter]) {
               [value appendString:character];
               state = STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS;
            } else {
               // The value has a set of embedded quotes but the entire
               // value is NOT enclosed in quotes. Put the quotes back
               // on the current value and continue processing as if a 
               // regular value.
               if ([self isEndOfLine] == NO) {
                  state = STATE_CONTINUE_WITH_REGULAR_FIELD;
                  [value appendFormat:@"%@%@%@%@", _quoteCharacter, value, _quoteCharacter, character];
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
   if (_values) {
      [_values release];
   }
   _values = [[NSMutableArray alloc] init];
   
   // Make sure the reader is open.
   if ([_reader isOpen] == NO) {
      [_reader open];
   }
   
   BOOL success = NO;
   if ([self isAtEnd] == NO) {
      [self readLineFromReader];
      success = YES;
   }
   
   return success;
}

- (NSArray *)values
{
   NSArray *values = [NSArray arrayWithArray:_values];
   return values;
}

#pragma mark -
#pragma mark Class Methods

+ (NSArray*)valuesFromCsvLine:(NSString *)csvLineString withValueSeparator:(NSString *)valueSeparator
{
   NSArray *values = nil;
   
   NSData *data = [csvLineString dataUsingEncoding:NSUTF8StringEncoding];
   NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
   
   KTCsvParser *parser = [[KTCsvParser alloc] initWithInputStream:inputStream];
   [parser setValueSeparator:valueSeparator];
   if ([parser readLine]) {
      values = [parser values];
   }
   [parser release];
   
   return values;
}


@end
