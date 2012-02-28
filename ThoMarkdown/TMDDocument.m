//
//  TMDDocument.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDDocument.h"
#import "TMDExportAccessoryView.h"
#import "TMDCompiler.h"

@interface TMDDocument ()
@property (strong) NSAttributedString *markdownContent;
- (void)convertMarkdownToWebView;
- (void)updateSyntaxHighlighting; 
- (NSString *)displayNameWithoutExtension;
- (void)syncScrollViews;
- (void)cheatSpaceCharIntoWebView;
@property (assign) NSRange caretPos;
@property (strong) WebView *offScreenWebView;
@property (strong) NSWindow *offScreenWindow;
@end

@implementation TMDDocument
{
	NSAttributedString *markdownContent;
	WebView *offScreenWebView;
	NSWindow *offScreenWindow;
	
	NSRange caretPos;
}

@synthesize exportAccessoryView;
@synthesize MarkdownTextView;
@synthesize OutputView;
@synthesize markdownContent;
@synthesize wordCount;
@synthesize themesDictionaryController;
@synthesize caretPos;
@synthesize offScreenWebView, offScreenWindow;

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		// If an error occurs here, return nil.
			self.markdownContent = [[NSAttributedString alloc] initWithString:@""];
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
	[self.MarkdownTextView setDelegate:self];
	self.markdownContent = [self.MarkdownTextView textStorage];
	self.wordCount = [[[self.MarkdownTextView textStorage] words] count];
	NSFont *fixedWidthFont = [NSFont userFixedPitchFontOfSize:12.0];
	[self.MarkdownTextView setFont:fixedWidthFont];
	[self convertMarkdownToWebView];
	[self.OutputView setPolicyDelegate:self];
	[self.OutputView setFrameLoadDelegate:self];
	[self.themesDictionaryController addObserver:self forKeyPath:@"selectionIndex" options:NSKeyValueObservingOptionNew context:NULL];	
	
	// create offscreen webview
	self.offScreenWindow = [[NSWindow alloc] initWithContentRect : NSMakeRect( 0.0, 0.0, 300.0, 500.0 )
													   styleMask : NSBorderlessWindowMask
														 backing : NSBackingStoreNonretained
														   defer : NO
														  screen : nil];
	self.offScreenWebView = [[WebView alloc] initWithFrame:NSMakeRect(.0, .0, 300.0, 500.0)];
	self.offScreenWindow.contentView = self.offScreenWebView;
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

#pragma mark -
#pragma mark KVO

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
	// Clipboard reps
	// Webarchive, PDF, RTF, HTML, markdown plaintext
	
	
	// we first need to compile a 'clean' version of the html with CSS
	NSArray *cssURLs = nil;
	if ([self.themesDictionaryController selectionIndex] != NSNotFound)
	{
		NSURL *cssURL = [[self.themesDictionaryController valueForKeyPath:@"arrangedObjects.value"] objectAtIndex:self.themesDictionaryController.selectionIndex]; 
		cssURLs = [NSArray arrayWithObject:cssURL];
	}
	// run compiler
	NSString *htmlString = [TMDCompiler htmlFromMarkdown:[self.markdownContent string]
												   title:self.displayNameWithoutExtension
												 scripts:nil
													 css:cssURLs];

	
	// set up pasteboard
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard clearContents];

	
	// plain text
	[pasteBoard setString:[self.markdownContent string] forType:NSStringPboardType];
		
	// HTML
	[pasteBoard setString:htmlString forType:NSHTMLPboardType];
	
	// RTF
	NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:htmlData 
																   baseURL:[[self fileURL] baseURL] 
														documentAttributes:NULL];
	NSData *rtf = [attrStr RTFFromRange:NSMakeRange(0, [attrStr length]) documentAttributes:nil];
	[pasteBoard setData:rtf forType:NSRTFPboardType];	
	
	
	// for PDF and WebArchive, we need to render the HTML using an offscreen WebView
	[[self.offScreenWebView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
	
	// WebArchive
	WebArchive *archive = [[[self.offScreenWebView mainFrame] dataSource] webArchive];
	[pasteBoard setData:[archive data] forType:WebArchivePboardType];

	// PDF
	NSView *docView = [[[self.offScreenWebView mainFrame] frameView] documentView];
	NSRect docRect = docView.bounds;
	docRect.size.height += 15;
	[docView writePDFInsideRect:docRect toPasteboard:pasteBoard];
}

- (IBAction)exportStyledDoc:(id)sender;
{
	NSSavePanel *sp = [NSSavePanel savePanel];
	[sp setNameFieldLabel:@"Export:"];
	[sp setAccessoryView:exportAccessoryView];
	
	[sp setNameFieldStringValue:[self displayNameWithoutExtension]];
	NSWindow *docWindow = [(NSWindowController *)[self.windowControllers objectAtIndex:0] window];
	[sp beginSheetModalForWindow:docWindow  completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelCancelButton) {
			return;
		}
		
		// we first need to compile a 'clean' version of the html with CSS
		NSArray *cssURLs = nil;
		if ([self.themesDictionaryController selectionIndex] != NSNotFound)
		{
			NSURL *cssURL = [[self.themesDictionaryController valueForKeyPath:@"arrangedObjects.value"] objectAtIndex:self.themesDictionaryController.selectionIndex]; 
			cssURLs = [NSArray arrayWithObject:cssURL];
		}
		// run compiler
		NSString *htmlString = [TMDCompiler htmlFromMarkdown:[self.markdownContent string]
													   title:self.displayNameWithoutExtension
													 scripts:nil
														 css:cssURLs];
		
		NSURL *theURL = [sp URL];
		
		NSString *extension = [theURL pathExtension];
		
		TMDExportFormat format = (TMDExportFormat)[[(TMDExportAccessoryView *)[sp accessoryView] formatSelectionPopupButton] selectedTag];
		
		NSData *fileData;
		
		switch (format) {
				
			case kTMDExportFormatPDF:
				{
					// for PDF, we need to render the HTML using an offscreen WebView
					[[self.offScreenWebView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
					NSView *docView = [[[self.offScreenWebView mainFrame] frameView] documentView];
					NSRect docRect = docView.bounds;
					docRect.size.height += 15;
					fileData = [docView dataWithPDFInsideRect:docRect];
					if (![extension isEqualToString:@"pdf"]) {
						theURL = [theURL URLByAppendingPathExtension:@"pdf"];
					}
				}
				break;
				
			case kTMDExportFormatHTML:
				fileData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
				if (![extension isEqualToString:@"htm"] && ![extension isEqualToString:@"html"]) {
					theURL = [theURL URLByAppendingPathExtension:@"html"];
				}
				break;
				
			case kTMDExportFormatRTF:
				{
					NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
					NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:htmlData 
																				   baseURL:[[self fileURL] baseURL] 
																		documentAttributes:NULL];
					fileData = [attrStr RTFFromRange:NSMakeRange(0, [attrStr length]) documentAttributes:nil];
					if (![extension isEqualToString:@"rtf"]) {
						theURL = [theURL URLByAppendingPathExtension:@"rtf"];
					}
				}
				break;
				
			case kTMDExportFormatInvalid:
			default:
				NSAssert(NO, @"Invalid export format: %d", format);
				break;
		}
		
		[fileData writeToURL:theURL atomically:NO];
	}];
}

- (IBAction)printDocument:(id)sender
{
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo]; 
	NSPrintOperation *printOperation; 
	NSView *webView = [[[self.OutputView mainFrame] frameView] documentView]; 
	[printInfo setTopMargin:15.0]; 
	[printInfo setLeftMargin:10.0]; 
	[printInfo setHorizontallyCentered:NO]; 
	[printInfo setVerticallyCentered:NO]; 
	printOperation = [NSPrintOperation printOperationWithView:webView printInfo:printInfo]; 
	[printOperation runOperation];
}

#pragma mark -
#pragma mark WebView related Delegate methods
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

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	[self syncScrollViews];
}
			
#pragma mark -
#pragma mark private methods

- (void)syncScrollViews;
{
	WebScriptObject *wso = [self.OutputView windowScriptObject];
	//[wso evaluateWebScript:@"window.location.hash = \"caretPos\";"];
	[wso evaluateWebScript:@"scrollToAnchor()"];
}

- (void)cheatSpaceCharIntoWebView;
{
	WebScriptObject *wso = [self.OutputView windowScriptObject];
	[wso evaluateWebScript:@"addSpaceInCaretAnchor()"];
}

- (NSString *)displayNameWithoutExtension;
{
	NSMutableArray *components = [[self.displayName componentsSeparatedByString:@"."] mutableCopy];
	if ([components count] > 1)
		[components removeLastObject];
	return [components componentsJoinedByString:@"."];
}

- (void)convertMarkdownToWebView;
{
	// inject anchor at caret pos 
	NSMutableString *markdownString = [[self.markdownContent string] mutableCopy];
	[markdownString insertString:@"<a name=\"caretPos\" class=\"cursor\">❮</a>" atIndex:self.caretPos.location];
	
	
	NSArray *jsURLS = [NSArray arrayWithObjects:
					   [[NSBundle mainBundle] URLForResource:@"cursorBlink" withExtension:@"js"],
					   [[NSBundle mainBundle] URLForResource:@"scrolling" withExtension:@"js"],
					   nil];
	

	// css
	NSArray *cssURLs = nil;
	if ([self.themesDictionaryController selectionIndex] != NSNotFound)
	{
		NSURL *cssURL = [[self.themesDictionaryController valueForKeyPath:@"arrangedObjects.value"] objectAtIndex:self.themesDictionaryController.selectionIndex]; 
		cssURLs = [NSArray arrayWithObject:cssURL];
	}
	
	
	// run compiler
	NSString *htmlString = [TMDCompiler htmlFromMarkdown:markdownString
												   title:self.displayNameWithoutExtension
												 scripts:jsURLS
													 css:cssURLs];
	
	// send html to WebView
	[[self.OutputView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];	
}


#pragma mark -
#pragma mark NSTextDelegate

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
	// TODO: it is actually too costly to make the markdown every time
	// we just do it here to change the cursor position
	// need to find a way to just move the caretPos anchor tag around the html
	self.caretPos = [self.MarkdownTextView selectedRange];
	[self convertMarkdownToWebView];
}

#pragma mark -
#pragma mark NSTextDelegate
							  
- (void)textDidChange:(NSNotification *)notification
{
	self.markdownContent = [self.MarkdownTextView textStorage];
	self.wordCount = [[[self.MarkdownTextView textStorage] words] count];

	
	BOOL spaceEntered = NO;
	// check if caret moved to the right by one
	NSRange newCaretPos = [self.MarkdownTextView selectedRange];
	if (newCaretPos.location == self.caretPos.location +1) {
		// check if the new char is a space
		NSRange lastChar = newCaretPos;
		lastChar.location -= 1;
		lastChar.length = 1;
		NSString *lastString = [[self.markdownContent string] substringWithRange:lastChar];
		spaceEntered = [lastString isEqualToString:@" "];
	}
	self.caretPos = newCaretPos;
	
	// if a space was inserted, DO NOT RELOAD THE WEB VIEW
	// Cheat a space into the view via JS instead
	if (!spaceEntered)
		[self convertMarkdownToWebView];
	else
		[self cheatSpaceCharIntoWebView];
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
	NSLayoutManager *lm = self.MarkdownTextView.layoutManager;
	NSUInteger length = [string length];
	
	NSMutableDictionary *h1Attr = [[NSMutableDictionary alloc] init];
	[h1Attr setObject: [NSColor blueColor]
			 forKey: NSForegroundColorAttributeName];
	NSDictionary *h2Attr = [NSDictionary dictionaryWithObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	NSDictionary *h3Attr = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	
	area.location = 0;
	area.length = length;

	// first, strip all attrs
	[lm removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:area];
	
	NSError *error;
	NSRegularExpression *h1 = [NSRegularExpression regularExpressionWithPattern:@"[^#]#[^#]+?$" 
																		options:NSRegularExpressionAnchorsMatchLines  
																		  error:&error];
	NSRegularExpression *h2 = [NSRegularExpression regularExpressionWithPattern:@"[^#]##[^#]+?$" 
																		options:NSRegularExpressionAnchorsMatchLines  
																		  error:&error];
	NSRegularExpression *h3 = [NSRegularExpression regularExpressionWithPattern:@"[^#]###[^#]+?$" 
																		options:NSRegularExpressionAnchorsMatchLines  
																		  error:&error];
	
	[h1 enumerateMatchesInString:string 
						 options:0 
						   range:NSMakeRange(0, [string length]) 
					  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
						  NSRange range =[result range];
						  if (found.location != NSNotFound)
						  {
							  [lm addTemporaryAttributes:h1Attr forCharacterRange:range];
						  }
					  }];
	
	[h2 enumerateMatchesInString:string 
						 options:0 
						   range:NSMakeRange(0, [string length]) 
					  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
						  NSRange range =[result range];
						  if (found.location != NSNotFound)
						  {
							  [lm addTemporaryAttributes:h2Attr forCharacterRange:range];
						  }
					  }];
	
	[h3 enumerateMatchesInString:string 
						 options:0 
						   range:NSMakeRange(0, [string length]) 
					  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
						  NSRange range =[result range];
						  if (found.location != NSNotFound)
						  {
							  [lm addTemporaryAttributes:h3Attr forCharacterRange:range];
						  }
					  }];
	
	
	
	while (area.length)
	{
		found = [string rangeOfString: @"---"
					          options: NSCaseInsensitiveSearch
								range: area];
		
		if (found.location == NSNotFound) break;
		[lm addTemporaryAttributes: h1Attr forCharacterRange: found];
		
		area.location = NSMaxRange(found);
		area.length = length - area.location;
	}
}

@end
