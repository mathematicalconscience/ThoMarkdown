//
//  TMDDocument.h
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface TMDDocument : NSDocument <NSTextDelegate, NSTextStorageDelegate>
@property (unsafe_unretained) IBOutlet NSTextView *MarkdownTextView;
@property (weak) IBOutlet WebView *OutputView;

@end
