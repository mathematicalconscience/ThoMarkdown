//
//  TMDDocument.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 19.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDDocument.h"
#import "TMDExportAccessoryView.h"

@interface TMDDocument ()
@property (strong) NSAttributedString *markdownContent;
@property (strong) NSString *htmlContent;
- (void)convertMarkdownToWebView;
- (void)updateSyntaxHighlighting; 
- (NSString *)displayNameWithoutExtension;
- (void)syncScrollViews;
@end

@implementation TMDDocument
{
	NSAttributedString *markdownContent;
	NSString *htmlContent;
}

@synthesize exportAccessoryView;
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
	[self.OutputView setFrameLoadDelegate:self];
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
	
	WebArchive *archive = [[[self.OutputView mainFrame] dataSource] webArchive];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:[self.htmlContent dataUsingEncoding:NSUTF8StringEncoding] 
																   baseURL:[[self fileURL] baseURL] 
														documentAttributes:NULL];
	NSData *rtf = [attrStr RTFFromRange:NSMakeRange(0, [attrStr length]) documentAttributes:nil];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard clearContents];
	
	[pasteBoard setData:[archive data] forType:WebArchivePboardType];
	NSView *docView = [[[self.OutputView mainFrame] frameView] documentView];
	NSRect docRect = docView.bounds;
	docRect.size.height += 15;
	[docView writePDFInsideRect:docRect toPasteboard:pasteBoard];
	[pasteBoard setData:rtf forType:NSRTFPboardType];	
	[pasteBoard setString:self.htmlContent forType:NSHTMLPboardType];	
	[pasteBoard setString:[self.markdownContent string] forType:NSStringPboardType];
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
		
		NSURL *theURL = [sp URL];
		
		NSString *extension = [theURL pathExtension];
		
		TMDExportFormat format = (TMDExportFormat)[[(TMDExportAccessoryView *)[sp accessoryView] formatSelectionPopupButton] selectedTag];
		
		NSData *fileData;
		
		switch (format) {
				
			case kTMDExportFormatPDF:
				{
					NSView *docView = [[[self.OutputView mainFrame] frameView] documentView];
					NSRect docRect = docView.bounds;
					docRect.size.height += 15;
					fileData = [docView dataWithPDFInsideRect:docRect];
					if (![extension isEqualToString:@"pdf"]) {
						theURL = [theURL URLByAppendingPathExtension:@"pdf"];
					}
					
				}
				break;
				
			case kTMDExportFormatHTML:
				fileData = [self.htmlContent dataUsingEncoding:NSUTF8StringEncoding];
				if (![extension isEqualToString:@"htm"] && ![extension isEqualToString:@"html"]) {
					theURL = [theURL URLByAppendingPathExtension:@"html"];
				}
				break;
				
			case kTMDExportFormatRTF:
				{
					NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:[self.htmlContent dataUsingEncoding:NSUTF8StringEncoding] 
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
	if (YES) 
	{
		[self syncScrollViews];
	}
}
			
#pragma mark -
#pragma mark private methods

- (void)syncScrollViews;
{
	NSScrollView *webScrollView = [[[[self.OutputView mainFrame] frameView] documentView] enclosingScrollView];
	NSScrollView *mdScrollView = [self.MarkdownTextView enclosingScrollView];
	
	// get scroller position
	NSScroller *vScroller = [mdScrollView verticalScroller];
	float relPos = [vScroller floatValue];
	
	// TODO: this is a simple hack to get the approximate relative position in the text
	// what we should do is find the rect of the position in the webView corresponding to
	// the current caret pos and scroll to that position!
	
	NSRect fullTarget = [[[self.OutputView mainFrame] frameView] documentView].bounds;
	
	NSRect newTarget = fullTarget;
	newTarget.origin.y = fullTarget.size.height * relPos - webScrollView.bounds.size.height * 0.5;
	newTarget.size.height = webScrollView.bounds.size.height;
	
	[[webScrollView documentView] scrollRectToVisible:newTarget];
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

	// prepend html header
	[htmlString appendFormat:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\""
	"\"http://www.w3.org/TR/html4/strict.dtd\">\n"
	"<html lang=\"en\">\n"
	"<head>\n"
	"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
	"<title>%@</title>\n"
	"</head>\n"
	"<body>\n",
	 self.displayNameWithoutExtension];
	
	// prepend css style opening tag
	[htmlString appendString:@"<style media=\"screen\" type=\"text/css\">\n"];
	
	// add css to html
	if ([self.themesDictionaryController selectionIndex] != NSNotFound)
	{
		NSError *error;
		NSURL *pathToCSS = [[self.themesDictionaryController valueForKeyPath:@"arrangedObjects.value"] objectAtIndex:self.themesDictionaryController.selectionIndex]; 
		//[htmlString appendString:[NSString stringWithFormat:@"<link rel=\"stylesheet\" href=\"%@\">", pathToCSS]];
		NSString *css = [NSString stringWithContentsOfURL:pathToCSS encoding:NSUTF8StringEncoding error:&error];
		[htmlString appendString:css];
	}
	
	// add css style closing tag
	[htmlString appendString:@"</style>\n"];
	
	// add markdown html
	[htmlString appendString:[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]];
	
	// add html footer
	[htmlString appendString:@"</body>\n</html>\n"];
	
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
