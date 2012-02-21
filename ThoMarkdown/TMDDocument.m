//
//  TMDDocument.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDDocument.h"

@interface TMDDocument ()
@property (strong) NSAttributedString *markdownContent;
@property (strong) NSString *htmlContent;
- (void)convertMarkdownToWebView;
-(void)updateSyntaxHighlighting; 
@end

@implementation TMDDocument
{
	NSAttributedString *markdownContent;
	NSString *htmlContent;
}

@synthesize MarkdownTextView;
@synthesize OutputView;
@synthesize markdownContent, htmlContent;
@synthesize wordCount;
@synthesize themesDictionaryController;

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		// If an error occurs here, return nil.
			self.markdownContent = [[NSAttributedString alloc] initWithString:@""];
			self.htmlContent = [[NSString alloc] initWithString:@""];
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
	[[self.MarkdownTextView textStorage] setDelegate:self];
	[[self.MarkdownTextView textStorage] setAttributedString:self.markdownContent];
	self.wordCount = [[[self.MarkdownTextView textStorage] words] count];
	NSFont *fixedWidthFont = [NSFont userFixedPitchFontOfSize:12.0];
	[self.MarkdownTextView setFont:fixedWidthFont];
	[self convertMarkdownToWebView];
	[self.OutputView setPolicyDelegate:self];
	[self.themesDictionaryController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:NULL];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	/*
	 Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	*/
	
	NSData *data;
    self.markdownContent = [self.MarkdownTextView textStorage];
    [self.MarkdownTextView breakUndoCoalescing];
	
	NSString *plainString = [self.markdownContent string];
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
		self.markdownContent = fileContents;
		return YES;
	}
	else
		return NO;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.themesDictionaryController) {
        [self convertMarkdownToWebView]; 
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark IBActions

- (IBAction)copyToClipboardClicked:(id)sender 
{
	WebArchive *archive = [[[self.OutputView mainFrame] dataSource] webArchive];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:[self.htmlContent dataUsingEncoding:NSUTF8StringEncoding] 
																   baseURL:[[self fileURL] baseURL] 
														documentAttributes:NULL];
	NSData *rtf = [attrStr RTFFromRange:NSMakeRange(0, [attrStr length]) documentAttributes:nil];
	
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard clearContents];
	
	[pasteBoard setData:[archive data] forType:WebArchivePboardType];
	[pasteBoard setData:rtf forType:NSRTFPboardType];	
	[pasteBoard setString:self.htmlContent forType:NSHTMLPboardType];
	
	
//	// Gets a list of all <body></body> nodes.
//    DOMNodeList *bodyNodeList = [[[self.OutputView mainFrame] DOMDocument] getElementsByTagName:@"body"];
//	
//    // There should be just one in valid HTML, so get the first DOMElement.
//    DOMHTMLElement *bodyNode = (DOMHTMLElement *) [bodyNodeList item:0];
//	
//	NSDictionary *element = [NSDictionary dictionaryWithObject:bodyNode forKey:WebElementDOMNodeKey];
//	
//	
//	
//	NSArray *pboardTypes = [self.OutputView pasteboardTypesForElement:element];
//	// TODO: implement
//	[self.OutputView writeElement:element withPasteboardTypes:pboardTypes toPasteboard:[NSPasteboard pasteboardWithName:NSGeneralPboard]];
}


#pragma mark -
#pragma mark WebPolicyDelegate methods
//open all links in the default browser, not in the web view which is used for rendering the converted markdown doc
-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener; 
{
	if ([[actionInformation valueForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeLinkClicked)
	{
		[listener ignore]; 
		
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	
	[listener use];
}
			
#pragma mark -
#pragma mark private methods

- (void)convertMarkdownToWebView;
{
	NSTask *mmd = [[NSTask alloc] init];
	NSString *launchPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"multimarkdown"];
	[mmd setLaunchPath:launchPath];
		
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
	if ([self.themesDictionaryController selectionIndex] != NSNotFound)
	{
		NSString *pathToCSS = [[self.themesDictionaryController valueForKeyPath:@"arrangedObjects.value"] objectAtIndex:self.themesDictionaryController.selectionIndex]; 
		[htmlString appendString:[NSString stringWithFormat:@"<link rel=\"stylesheet\" href=\"%@\">", pathToCSS]];
	}
	
	[htmlString appendString:[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]];
	
	self.htmlContent = htmlString;
	
	[[self.OutputView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
}

#pragma mark -
#pragma mark NSTextDelegate
							  
- (void)textDidChange:(NSNotification *)notification
{
	self.markdownContent = [self.MarkdownTextView textStorage];
	self.wordCount = [[[self.MarkdownTextView textStorage] words] count];
	
	[self convertMarkdownToWebView];
}

#pragma mark -
#pragma mark NSTextStorageDelegate

// simple syntax highlighting 
- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(updateSyntaxHighlighting) withObject:nil waitUntilDone:NO]; 
}

-(void)updateSyntaxHighlighting; 
{
	NSTextStorage *textStorage = self.MarkdownTextView.layoutManager.textStorage;
	NSRange found, area;
	NSString *string = [textStorage string];
	NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
	NSLayoutManager *lm = self.MarkdownTextView.layoutManager;
	NSUInteger length = [string length];
	
	[attr setObject: [NSColor blueColor]
			 forKey: NSForegroundColorAttributeName];
	
	area.location = 0;
	area.length = length;

	// first, strip all attrs
	[lm removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:area];
	
	while (area.length)
	{
		found = [string rangeOfString: @"---"
					          options: NSCaseInsensitiveSearch
								range: area];
		
		if (found.location == NSNotFound) break;
		[lm addTemporaryAttributes: attr forCharacterRange: found];
		
		area.location = NSMaxRange(found);
		area.length = length - area.location;
	}
}

@end
