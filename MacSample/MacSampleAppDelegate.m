//
//  MacSampleAppDelegate.m
//  MacSample
//
//  Created by Kirby Turner on 1/8/11.
//  Copyright 2011 White Peak Software Inc. All rights reserved.
//

#import "MacSampleAppDelegate.h"
#import "KTCsvParser.h"

@implementation MacSampleAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
   
   // Test reading a single line.
   NSString *csvString;
   csvString = @"a,\"\"\"b\"\"\",c\r1,2,3";
   NSData *data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
   NSLog(@"%@", data);
   
   NSArray *values = [KTCsvParser valuesFromCsvLine:csvString withValueSeparator:@","];
   NSLog(@"values: %@", values);
   
   // Simulate reading a file.
   NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
   KTCsvParser *parser = [[KTCsvParser alloc] initWithInputStream:inputStream];
   while ([parser readLine]) {
      NSLog (@"values: %@", [parser values]);
   }
   [parser release];
}

@end
