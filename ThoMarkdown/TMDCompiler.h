//
//  TMDCompiler.h
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 28.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMDCompiler : NSObject

+(NSString *)htmlFromMarkdown:(NSString *)theMarkdownString title:(NSString *)theTitle scripts:(NSArray *)theScriptURLS css:(NSArray *)theCSSURLS;

@end
