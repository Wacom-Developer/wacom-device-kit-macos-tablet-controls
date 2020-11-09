///////////////////////////////////////////////////////////////////////////////
//
// DESCRIPTION
//		Controls UI which demonstrates how to query the Wacom driver for tablet
//		information, then take control of special features of the tablets, including
//		ExpressKeys, OLED displays, and touch strips.
//
// COPYRIGHT
//    Copyright (c) 2008 - 2020 Wacom Co., Ltd.
//    All rights reserved
//
///////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import "TabletAEDictionary.h"

@interface TabletControlsController : NSObject {

	IBOutlet NSPopUpButton	*_tabletButton;
	IBOutlet NSButton			*_makeContext;
	IBOutlet NSTextField		*_contextField;
	IBOutlet NSButton			*_takeControl;
	IBOutlet NSTextField		*_controlCountField;
	IBOutlet NSTabView		*_tabView;

	// TouchRing tab
	IBOutlet NSTextField				*_ringValue;
	IBOutlet NSTextField				*_ringMax;
	IBOutlet NSTextField				*_ringMin;
	IBOutlet NSMatrix					*_ringMode;
	IBOutlet NSProgressIndicator	*_ringIndicator1;
	IBOutlet NSProgressIndicator	*_ringIndicator2;
	IBOutlet NSLevelIndicator		*_ringIndicator3;
	IBOutlet NSLevelIndicator		*_ringIndicator4;
	IBOutlet NSButton					*_ring1;
	IBOutlet NSButton					*_ring2;
	IBOutlet NSButton					*_ring3;
	IBOutlet NSButton					*_ring4;
	
	// ExpressKeys tab
	IBOutlet NSTextField				*_keyValue;
	IBOutlet NSTextField				*_keyMax;
	IBOutlet NSTextField				*_keyMin;
	IBOutlet NSTextField				*_keyIconWidth;
	IBOutlet NSTextField				*_keyIconHeight;
	IBOutlet NSTextField				*_keyPixelFormat;
	IBOutlet NSButton					*_key1;
	IBOutlet NSButton					*_key2;
	IBOutlet NSButton					*_key3;
	IBOutlet NSButton					*_key4;
	IBOutlet NSButton					*_key5;
	IBOutlet NSButton					*_key6;
	IBOutlet NSButton					*_key7;
	IBOutlet NSButton					*_key8;
	IBOutlet NSImageView				*_keyImage1;
	IBOutlet NSImageView				*_keyImage2;
	IBOutlet NSImageView				*_keyImage3;
	IBOutlet NSImageView				*_keyImage4;
	IBOutlet NSImageView				*_keyImage5;
	IBOutlet NSImageView				*_keyImage6;
	IBOutlet NSImageView				*_keyImage7;
	IBOutlet NSImageView				*_keyImage8;
	IBOutlet NSTextField				*_keyLocation1;
	IBOutlet NSTextField				*_keyLocation2;
	IBOutlet NSTextField				*_keyLocation3;
	IBOutlet NSTextField				*_keyLocation4;
	IBOutlet NSTextField				*_keyLocation5;
	IBOutlet NSTextField				*_keyLocation6;
	IBOutlet NSTextField				*_keyLocation7;
	IBOutlet NSTextField				*_keyLocation8;

	// TouchStrip tab
	IBOutlet NSTextField				*_stripValue;
	IBOutlet NSTextField				*_stripMax;
	IBOutlet NSTextField				*_stripMin;
	IBOutlet NSMatrix					*_stripMode1;
	IBOutlet NSMatrix					*_stripMode2;
	IBOutlet NSButton					*_strip1;
	IBOutlet NSButton					*_strip2;
	IBOutlet NSButton					*_strip3;
	IBOutlet NSButton					*_strip4;
	IBOutlet NSButton					*_strip5;
	IBOutlet NSButton					*_strip6;
	IBOutlet NSLevelIndicator		*_stripIndicator1;
	IBOutlet NSLevelIndicator		*_stripIndicator2;
	IBOutlet NSLevelIndicator		*_stripIndicator3;
	IBOutlet NSLevelIndicator		*_stripIndicator4;
	IBOutlet NSLevelIndicator		*_stripIndicator5;
	IBOutlet NSLevelIndicator		*_stripIndicator6;
	
	NSInteger					_currentTablet;	// 1-based tablet id
	UInt32						_context;
	
	// TouchRing
	NSArray						*_ringCheckboxes;
	SInt32						_ringCount;
	BOOL							_isControllingRing;
	UInt32						_lastRingValue;
	UInt32						_maxRingValue;
	UInt32						_minRingValue;
	SInt32						_ringValueDelta;
	NSDictionary				*_ringData;

	// ExpressKeys
	NSArray						*_keyCheckboxes;
	NSArray						*_keyImages;
	NSArray						*_keyLocations;
	SInt32						_keyCount;
	BOOL							_isControllingKeys;
	UInt32						_maxKeyValue;
	UInt32						_minKeyValue;
	NSDictionary				*_keyData;
	
	// TouchStrip
	NSArray						*_stripCheckboxes;
	NSArray						*_stripIndicators;
	SInt32						_stripCount;
	BOOL							_isControllingStrip;
	UInt32						_maxStripValue;
	UInt32						_minStripValue;
	NSDictionary				*_stripData;
}

- (IBAction) createContext:(id)sender;
- (IBAction) tabletSelect:(id)sender;
- (IBAction) takeControl:(id)sender;

- (SInt32) currentTab;
- (void) updateUI;
- (SInt32) controlCountOfTabWithID:(SInt32)tabletId_I;
- (BOOL) isControllingTabWithID:(SInt32)tabletId_I;

- (void) makeContext;
- (void) destroyContext;

- (void) setContext:(UInt32)context_I;
- (UInt32) context;
- (BOOL) isContextValid;

- (NSString *) locationStringFromID:(eAEControlPosition)locationID_I;

// TouchRing
- (void) setIsControllingRing:(BOOL)flag_I;
- (BOOL) isControllingRing;

- (void) setRingData:(NSDictionary *)data_I;
- (NSDictionary *) ringData;

- (void) takeControlOfRing;

- (void) updateTouchRingUI;
- (void) adjustLevelIndicator:(NSLevelIndicator*)indicator_I
				withRingValue:(UInt32)value_I sensitivity:(SInt32)sensitivity_I;

// ExpressKeys
- (void) setIsControllingKeys:(BOOL)flag_I;
- (BOOL) isControllingKeys;

- (void) setKeyData:(NSDictionary *)data_I;
- (NSDictionary *) keyData;

- (void) takeControlOfKeys;

- (void) updateExpressKeysUI;

// TouchStrip
- (void) setIsControllingStrip:(BOOL)flag_I;
- (BOOL) isControllingStrip;

- (void) setStripData:(NSDictionary *)data_I;
- (NSDictionary *) stripData;

- (void) takeControlOfStrip;

- (void) updateTouchStripUI;

@end
