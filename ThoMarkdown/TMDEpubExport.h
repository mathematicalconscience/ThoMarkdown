//
//  TMDEpubExport.h
//  ThoMarkdown
//
//  Created by Leonhard Lichtschlag on 27/Feb/12.
//  Copyright (c) Leonhard Lichtschlag. All rights reserved.
//

#import <Foundation/Foundation.h>

// ===============================================================================================================
@interface TMDEpubExport : NSObject
// ===============================================================================================================

+ (BOOL) exportChapter:(NSString *)chapterHtml toPath:(NSURL *)theURL author:(NSString *)bookAuthor title:(NSString *)bookTitle;

@end

