#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "TMDCompiler.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
	
	// load the markdown text
	NSURL *bridgeURL = (__bridge NSURL *)url;
	NSError *error;
	NSString *markdownString = [NSString stringWithContentsOfURL:bridgeURL encoding:NSUTF8StringEncoding error:&error];
	
	// convert to html
	NSString *htmlString = [TMDCompiler htmlFromMarkdown:markdownString
												   title:@"markdown file title"
												 scripts:nil
													 css:nil];
	
	NSData *theHTMLData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
	
	CFDataRef bridgeData = (__bridge CFDataRef)theHTMLData;
		
	QLPreviewRequestSetDataRepresentation(preview, bridgeData, kUTTypeHTML, NULL);
	
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
