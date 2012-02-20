//
//  TMDDocument.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDDocument.h"

@interface TMDDocument ()
@property (strong) NSAttributedString *content;
- (void)convertMarkdownToWebView;
@end

@implementation TMDDocument
{
	NSAttributedString *content;
}

@synthesize MarkdownTextView;
@synthesize OutputView;
@synthesize content;

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		// If an error occurs here, return nil.
		if (!content) {
			self.content = [[NSAttributedString alloc] initWithString:@""];
		}
    }
    return self;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"TMDDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
	[self.MarkdownTextView setRichText:NO];
	[self.MarkdownTextView setUsesFontPanel:NO];
	[[self.MarkdownTextView textStorage] setAttributedString:self.content];
	NSFont *fixedWidthFont = [NSFont userFixedPitchFontOfSize:12.0];
	[self.MarkdownTextView setFont:fixedWidthFont];
	[[self.MarkdownTextView textStorage] setDelegate:self];
	[self convertMarkdownToWebView];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	/*
	 Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	*/
	
	NSData *data;
    self.content = [self.MarkdownTextView textStorage];
    [self.MarkdownTextView breakUndoCoalescing];
	
	NSString *plainString = [self.content string];
	data = [plainString dataUsingEncoding:NSUTF8StringEncoding];
	
    return data;
	
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	/*
	Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	*/
	
	NSAttributedString *fileContents = [[NSAttributedString alloc] initWithData:data options:nil documentAttributes:nil error:outError];
	
	if (fileContents) 
	{
		self.content = fileContents;
		return YES;
	}
	else
		return NO;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}
			
#pragma mark -
#pragma mark private methods

- (void)convertMarkdownToWebView;
{
	NSTask *mmd = [[NSTask alloc] init];
	NSString *launchPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"multimarkdown"];
	[mmd setLaunchPath:launchPath];
	
	//	NSArray *arguments;
	//	arguments = [NSArray arrayWithObject:[self.content string]];
	//	[mmd setArguments: arguments];
	
	NSPipe *outPipe;
	outPipe = [NSPipe pipe];
	[mmd setStandardOutput: outPipe];
	NSPipe *inPipe;
	inPipe = [NSPipe pipe];
	[mmd setStandardInput:inPipe];
	
	NSFileHandle *inFile;
	inFile = [inPipe fileHandleForWriting];
	
	NSFileHandle *outFile;
	outFile = [outPipe fileHandleForReading];
	
	
	[mmd launch];
	
	[inFile writeData:[self dataOfType:@"markdown" error:NULL]];
	[inFile closeFile];
	
	
	NSData *data;
	data = [outFile readDataToEndOfFile];
	
	NSMutableString *htmlString = [NSMutableString string];
	// add css to html
	[htmlString appendString:@"<link rel=\"stylesheet\" href=\"style.css\">"];
	
	[htmlString appendString:[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]];
	
	[[self.OutputView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
}

#pragma mark -
#pragma mark NSTextDelegate
							  
- (void)textDidChange:(NSNotification *)notification
{
	self.content = [self.MarkdownTextView textStorage];
	
	[self convertMarkdownToWebView];
}

@end
