//
//  TMDCompiler.m
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 28.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMDCompiler.h"

@implementation TMDCompiler

+(NSString *)htmlFromMarkdown:(NSString *)theMarkdownString title:(NSString *)theTitle scripts:(NSArray *)theScriptURLS css:(NSArray *)theCSSURLS;
{
	// setting up the mmd task
	
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
	
	
	// piping in data
	
	NSData *inData;
	inData = [theMarkdownString dataUsingEncoding:NSUTF8StringEncoding];
	
	[inFile writeData:inData];
	[inFile closeFile];
	
	
	// reading out data
	
	NSData *outData;
	outData = [outFile readDataToEndOfFile];
	
	
	// build HTML =====================================
	
	NSMutableString *htmlString = [NSMutableString string];
	
	// prepend html header
	[htmlString appendFormat:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" "
	 "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
	 "<html lang=\"en\">\n"
	 "<head>\n"
	 "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>\n"
	 "<title>%@</title>\n"
	 "</head>\n"
	 "<body>\n",
	 theTitle];
	
	
	// JavaScript stuff -----------------------------------
	if (theScriptURLS)
	{
		// add jQuery lib
		[htmlString appendFormat:@"<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.5/jquery.min.js\"></script>"];
		
		for (NSURL *jsURL in theScriptURLS) 
		{
			// add script
			NSString *jsPath = [jsURL path];
			[htmlString appendFormat:@"<script type=\"text/javascript\" src=\"%@\"></script>", jsPath];
		}
	}

	
	// CSS stuff -----------------------------------
	if (theCSSURLS)
	{
		// add css style opening tag
		[htmlString appendString:@"<style media=\"all\" type=\"text/css\">\n"];
		
		for (NSURL *cssURL in theCSSURLS)
		{
			// add CSS
			NSError *error;
			NSString *css = [NSString stringWithContentsOfURL:cssURL encoding:NSUTF8StringEncoding error:&error];
			
			[htmlString appendString:css];
		}
		
		// add css style closing tag
		[htmlString appendString:@"</style>\n"];
	}
	
	
	// add markdown html
	[htmlString appendString:[[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding]];
	
	
	// add html footer
	[htmlString appendString:@"</body>\n</html>\n"];
	
	
	return htmlString;
}


@end
