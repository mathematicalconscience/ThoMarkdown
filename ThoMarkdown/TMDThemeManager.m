//
//  TMDThemeManager.m
//  ThoMarkdown
//
//  Created by Jan-Peter Krämer on 20.02.12.
//  Copyright (c) 2012 RWTH Aachen University. All rights reserved.
//

#import "TMDThemeManager.h"

@interface TMDThemeManager ()

-(void)updateThemeList; 
-(void)addThemesInDirectory:(NSURL *)directoryURL; 

@end

@implementation TMDThemeManager

- (id)init
{
    self = [super init];
    if (self) {
        [self updateThemeList]; 
    }
    return self;
}

-(void)updateThemeList; 
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *applicationSupportURLs = [fm URLsForDirectory:NSApplicationSupportDirectory
														  inDomains:NSAllDomainsMask]; 
	NSString *executableName =
	[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	
	for (NSURL *applicationSupportURL in applicationSupportURLs) 
	{
		BOOL isDirectory = NO; 
		NSURL *urlWithAppName = [applicationSupportURL URLByAppendingPathComponent:executableName]; 
		[fm fileExistsAtPath:[urlWithAppName path] isDirectory:&isDirectory]; 
		if (isDirectory) 
			[self addThemesInDirectory:urlWithAppName]; 
	}
	
	[self addThemesInDirectory:[[NSBundle mainBundle] resourceURL]]; 	 
}

-(void)addThemesInDirectory:(NSURL *)directoryURL; 
{
	NSMutableDictionary *newThemes = [NSMutableDictionary dictionaryWithCapacity:1]; 
	
	NSFileManager *fm = [NSFileManager defaultManager];	
	NSDirectoryEnumerator *directoryEnumerator = [fm enumeratorAtURL:directoryURL
										  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLIsDirectoryKey,nil] 
															 options:NSDirectoryEnumerationSkipsHiddenFiles
														errorHandler:^BOOL(NSURL *url, NSError *error) {
															NSLog(@"Error while enumerating URL: %@, %@", url, error); 
															return YES;
														}];
	
	for (NSURL *fileURL in directoryEnumerator) {
		if ([[fileURL pathExtension] isEqualToString:@"css"])
		{
			NSString *name = [[fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".css" 
																						withString:@""
																						options:(NSBackwardsSearch | NSAnchoredSearch)
																						 range:NSMakeRange(0, [fileURL lastPathComponent].length)]; 
			[newThemes setObject:[fileURL path] forKey:name]; 
		}
	}
	
	if (self.themes)
		[newThemes addEntriesFromDictionary:self.themes];

	self.themes = [NSDictionary dictionaryWithDictionary:newThemes];
}



@end
