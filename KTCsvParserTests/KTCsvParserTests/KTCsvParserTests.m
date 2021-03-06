//
//  KTCsvParserTestCases.m
//  MacTests
//
//  Created by Kirby Turner on 1/22/11.
//  Copyright 2011 White Peak Software Inc. All rights reserved.
//

#import "KTCsvParserTests.h"
#import "KTCsvParser.h"


@implementation KTCsvParserTestCases

- (void)testSimpleLineParse
{
   NSString *csvString = @"a, b, c";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@","];
   STAssertTrue([values count] == 3, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@" b"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@" c"], @"Unexpected value.");
}

- (void)testIgnoreLeadingWhitespaces
{
   NSString *csvString = @"a, b, c ";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@"," quoteCharacter:nil ignoreLeadingWhitespaces:YES];
   STAssertTrue([values count] == 3, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@"b"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@"c "], @"Unexpected value.");
}

- (void)testEmbeddedQuotes
{
   // Test reading a single line.
   NSString *csvString;
   csvString = @"a,\"\"\"b\"\"\",c\r1,2,3";
   NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
   
   // Simulate reading a file.
   NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
   KTCsvParser *parser = [[KTCsvParser alloc] initWithInputStream:inputStream];
   while ([parser readLine]) {
      NSLog (@"values: %@", [parser values]);
   }
}

- (void)testExcelEllipsisBug
{
   // Test reading a single line.
   NSString *csvString;
   csvString = @"…This is…a test.,another field";
   NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
   
   // Simulate reading a file.
   NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
   KTCsvParser *parser = [[KTCsvParser alloc] initWithInputStream:inputStream];
   while ([parser readLine]) {
      NSArray *values = [parser values];
      STAssertTrue([values count] == 2, @"Unexpected value count.");
      STAssertTrue([[values objectAtIndex:0] isEqualToString:@"…This is…a test."], @"Unexpected value.");
      STAssertTrue([[values objectAtIndex:1] isEqualToString:@"another field"], @"Unexpected value.");
      NSLog (@"values: %@", [parser values]);
   }
}

- (void)testSimpleQuoteCharacter
{
   NSString *csvString = @"a,\"b,c\",d";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@"," quoteCharacter:@"\""];
   STAssertTrue([values count] == 3, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@"b,c"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@"d"], @"Unexpected value.");
}

- (void)testQuoteCharacter
{
   NSString *csvString = @"a,b,\"This is fun, ain't it.\",c";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@"," quoteCharacter:@"\""];
   STAssertTrue([values count] == 4, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@"b"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@"This is fun, ain't it."], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:3] isEqualToString:@"c"], @"Unexpected value.");
}

- (void)testQuoteCharacterAsLastField
{
   NSString *csvString = @"a,b,\"This is fun, ain't it.\"";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@"," quoteCharacter:@"\""];
   STAssertTrue([values count] == 3, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@"b"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@"This is fun, ain't it."], @"Unexpected value.");
}

- (void)testQuoteCharacterAsLastFieldAndIgnoringLeadingWhitespaces
{
   NSString *csvString = @"a,b, \"This is fun, ain't it.\"";
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@"," quoteCharacter:@"\"" ignoreLeadingWhitespaces:YES];
   STAssertTrue([values count] == 3, @"Unexpected count.");
   STAssertTrue([[values objectAtIndex:0] isEqualToString:@"a"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:1] isEqualToString:@"b"], @"Unexpected value.");
   STAssertTrue([[values objectAtIndex:2] isEqualToString:@"This is fun, ain't it."], @"Unexpected value.");
}

@end
