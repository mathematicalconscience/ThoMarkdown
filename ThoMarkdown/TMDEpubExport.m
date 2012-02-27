//
//  TMDEpubExport.m
//  ThoMarkdown
//
//  Created by Leonhard Lichtschlag on 27/Feb/12.
//  Copyright (c) Leonhard Lichtschlag. All rights reserved.
//

#import "TMDEpubExport.h"

// ===============================================================================================================
@implementation TMDEpubExport
// ===============================================================================================================

+ (BOOL) exportChapter:(NSString *)chapterXhtml 
				 toPath:(NSURL *)theURL 
				 author:(NSString *)bookAuthor 
				  title:(NSString *)bookTitle
{
	NSError *returnedError = nil;
	
	// create folder in temp directory
	NSString *tempDirPath =	NSTemporaryDirectory();
	NSURL *tempDirURL =		[NSURL fileURLWithPath:tempDirPath isDirectory:YES];
	NSLog(@"%s %@", __PRETTY_FUNCTION__, tempDirURL);
	
	// bookCreationDate, bookUUID
	NSString* bookCreationDate = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" 
																	 timeZone:nil 
																	   locale:nil];
	
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *bookUUID = (__bridge NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);

	// create book skeleton
	NSURL *containerDirURL	= [tempDirURL URLByAppendingPathComponent:bookUUID isDirectory:YES];
	NSURL *metaInfURL		= [containerDirURL URLByAppendingPathComponent:@"META-INF" isDirectory:YES];
	NSURL *contentsURL		= [containerDirURL URLByAppendingPathComponent:@"OEBPS" isDirectory:YES];
	if (![[NSFileManager defaultManager] createDirectoryAtURL:containerDirURL
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:&returnedError])
	{
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	if (![[NSFileManager defaultManager] createDirectoryAtURL:metaInfURL
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&returnedError])
	{
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	if (![[NSFileManager defaultManager] createDirectoryAtURL:contentsURL
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&returnedError])
	{
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	// write epub 2.0 files (mimetype, container.xml)
	NSString *mimeContents = @"application/epub+zip";
	if (![mimeContents writeToURL:[containerDirURL URLByAppendingPathComponent:@"mimetype"]
				  atomically:NO
					encoding:NSUTF8StringEncoding
					   error:&returnedError])
	{	
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	NSString *containerContents = @"<?xml version=\"1.0\"?>\n"
									"<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n"
									"<rootfiles>\n"
									"<rootfile full-path=\"OEBPS/content.opf\" media-type=\"application/oebps-package+xml\"/>\n"
									"</rootfiles>\n"
									"</container>";
	if (![containerContents writeToURL:[metaInfURL URLByAppendingPathComponent:@"container.xml"] 
					   atomically:NO
						 encoding:NSUTF8StringEncoding 
							error:&returnedError])
	{	
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	// add our chapter (cover, chapter.xml, the content.opf, and table of contents)
	NSString *opfContents = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
							 "<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookID\" version=\"2.0\">\n"
							 "<metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:opf=\"http://www.idpf.org/2007/opf\">\n"
							 "<dc:title>%@</dc:title>\n"
							 "<dc:creator opf:role=\"aut\">%@</dc:creator>\n"
							 "<dc:date opf:event=\"creation\">%@</dc:date>\n"
							 "<dc:language>en</dc:language>\n"
							 "<dc:identifier id=\"BookID\" opf:scheme=\"UUID\">%@</dc:identifier>\n"
							 "<meta name=\"cover\" content=\"cover.jpg\"/>\n" 
							 "</metadata>\n"
							 "<manifest>\n"
							 "<item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>\n"
							 "<item id=\"cover.jpg\" href=\"cover.jpg\" media-type=\"image/jpeg\"/>\n"
							 "<item id=\"chapter.xhtml\" href=\"chapter.xhtml\" media-type=\"application/xhtml+xml\"/>\n"
							 "</manifest>\n"
							 "<spine toc=\"ncx\">\n"
							 "<itemref idref=\"chapter.xhtml\"/>\n"
							 "</spine>\n"
							 "</package>\n", bookTitle, bookAuthor, bookCreationDate, bookUUID];
	if (![opfContents writeToURL:[contentsURL URLByAppendingPathComponent:@"content.opf"]
					  atomically:NO
						encoding:NSUTF8StringEncoding
						   error:&returnedError])
	{	
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	if (![chapterXhtml writeToURL:[contentsURL URLByAppendingPathComponent:@"chapter.xhtml"]
					  atomically:NO
						encoding:NSUTF8StringEncoding
						   error:&returnedError])
	{	
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	NSString *tocContents = [NSString stringWithFormat:@"<ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">\n"
							 "<head>\n"
							 "<meta name=\"dtb:uid\" content=\"6fe1daee-a6d3-41b9-a340-6442e9a960d5\"/>\n"
							 "<meta name=\"dtb:depth\" content=\"1\"/>\n"
							 "<meta name=\"dtb:totalPageCount\" content=\"0\"/>\n"
							 "<meta name=\"dtb:maxPageNumber\" content=\"0\"/>\n"
							 "</head>\n"
							 "<docTitle>\n"
							 "<text>%@</text>\n"
							 "</docTitle>\n"
							 "<navMap>\n"
							 "<navPoint id=\"navPoint-1\" playOrder=\"1\">\n"
							 "<navLabel>\n"
							 "<text>Chapter 1</text>\n"
							 "</navLabel>\n"
							 "<content src=\"chapter.xhtml\"/>\n"
							 "</navPoint>\n"
							 "</navMap>\n"
							 "</ncx>\n", bookTitle];	
	if (![tocContents writeToURL:[contentsURL URLByAppendingPathComponent:@"toc.ncx"]
					  atomically:NO
						encoding:NSUTF8StringEncoding
						   error:&returnedError])
	{	
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}

	NSURL *bookCoverURL = [[NSBundle mainBundle] URLForResource:@"bookDefaultCover" withExtension:@"jpg"];
	if (![[NSFileManager defaultManager] copyItemAtURL:bookCoverURL 
											toURL:[contentsURL URLByAppendingPathComponent:@"cover.jpg"] 
											error:&returnedError])
	{
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	// zip the bookcontainer, but the mimtype must be the first file in the zip and it must be uncompressed
	NSTask *zipTask1			= [[NSTask alloc] init];
	[zipTask1 setLaunchPath:@"/usr/bin/zip"];
	[zipTask1 setCurrentDirectoryPath:[containerDirURL path]];
	[zipTask1 setArguments:[NSArray arrayWithObjects:@"-X0", @"book", @"mimetype", nil]];
	[zipTask1 launch];
	[zipTask1 waitUntilExit];	
	if (![zipTask1 terminationStatus] == 0)
	{
		NSLog(@"%s First Zip Run Failed", __PRETTY_FUNCTION__);
		return NO;
	}
	
	//	zip -X0 "full path to new epub file" mimetype
	//	zip -rDX9 "full path to new epub file" *  -x mimetype
	NSTask *zipTask2			= [[NSTask alloc] init];
	[zipTask2 setLaunchPath:@"/usr/bin/zip"];
	[zipTask2 setCurrentDirectoryPath:[containerDirURL path]];
	[zipTask2 setArguments:[NSArray arrayWithObjects:@"-rDX9", @"book", @"*", @"-x", @"mimetype", nil]];
	
	// this works in terminal "zip -rDX9 book * -x mimetype"
	
	[zipTask2 launch];
	[zipTask2 waitUntilExit];	
	if (![zipTask2 terminationStatus] == 0)
	{
		NSLog(@"%s Second Zip Failed", __PRETTY_FUNCTION__);
		return NO;
	}

	// copy to export url
	if (![[NSFileManager defaultManager] copyItemAtURL:[containerDirURL URLByAppendingPathComponent:@"book.zip"]
												 toURL:[theURL URLByAppendingPathExtension:@"zip"]
												 error:&returnedError])
	{
		NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedError);
		return NO;
	}
	
	// TODO: clean up temp dir (if we feel nice)
	
	return YES;
}


@end

