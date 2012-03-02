#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "TMDCompiler.h"


OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
	
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
	
	//QLThumbnailRequestSetThumbnailWithDataRepresentation(<#QLThumbnailRequestRef thumbnail#>, <#CFDataRef data#>, <#CFStringRef contentTypeUTI#>, <#CFDictionaryRef previewProperties#>, <#CFDictionaryRef properties#>)
	
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
