//
//  TMDDocument.h
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface TMDDocument : NSDocument <NSTextDelegate, NSTextStorageDelegate, NSTextViewDelegate>
@property (weak) IBOutlet NSView *exportAccessoryView;
@property (unsafe_unretained) IBOutlet NSTextView *MarkdownTextView;		// LEO: why unsafe_unretained?
@property (weak) IBOutlet WebView *OutputView;
@property (assign) NSUInteger wordCount;
@property (weak) IBOutlet NSDictionaryController *themesDictionaryController;

- (IBAction)copyToClipboardClicked:(id)sender;

- (IBAction)exportStyledDoc:(id)sender;


@end
