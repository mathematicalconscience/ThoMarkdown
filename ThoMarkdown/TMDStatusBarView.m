//
//  TMDStatusBarView.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 20.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDStatusBarView.h"

@implementation TMDStatusBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
//	NSImage *statusBg = [NSImage imageNamed:@"statusFill.png"];
//	self.layer.contents = statusBg;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.

	NSGradient *g = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor windowFrameColor]];
	
	[g drawInRect:self.bounds angle:270.0];
	
	[[NSColor darkGrayColor] setStroke];
	
	NSBezierPath *topLine = [NSBezierPath bezierPath];

	[topLine moveToPoint:NSMakePoint(0, self.bounds.size.height)];
	[topLine lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
	
	[topLine stroke];
}

@end
