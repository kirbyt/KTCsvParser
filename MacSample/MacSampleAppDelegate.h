//
//  MacSampleAppDelegate.h
//  MacSample
//
//  Created by Kirby Turner on 1/8/11.
//  Copyright 2011 White Peak Software Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MacSampleAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
