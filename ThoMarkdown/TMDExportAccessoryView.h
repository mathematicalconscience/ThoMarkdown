//
//  TMDExportAccessoryView.h
//  ThoMarkdown
//
//  Created by Thorsten Karrer on 22.2.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum TMDExportFormats 
{
	kTMDExportFormatInvalid = -1,
	kTMDExportFormatPDF,
	kTMDExportFormatHTML,
	kTMDExportFormatRTF,
	kTMDExportFormatEpub,
	kTMDExportFormatCount
} TMDExportFormat;

@interface TMDExportAccessoryView : NSView
@property (weak) IBOutlet NSPopUpButton *formatSelectionPopupButton;

@end
