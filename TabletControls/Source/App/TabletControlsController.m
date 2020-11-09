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

#import "TabletControlsController.h"
#import "WacomTabletDriver.h"

#define	GRAB_IMAGE @"5001.bmp"

// These define the max number of tablet controls or functions
// that this sample application can handle.
#define	MAX_EXPRESS_KEY_COUNT				8
#define	MAX_TOUCH_RING_FUNCTION_COUNT		4
#define	MAX_TOUCH_STRIP_COUNT				2
#define	MAX_TOUCH_STRIP_FUNCTION_COUNT	3

///////////////////////////////////////////////////////////////////////////////
@implementation TabletControlsController

///////////////////////////////////////////////////////////////////////////////

//	This is called when the main nib is loaded. Perform some initialization here.

-(void)awakeFromNib
{
	UInt32   tabletCount			= 0;
	UInt32   transducerCount	= 0;
	UInt32   idx					= 0;

	// initialize some data members
	_ringCount        = -1;
	_keyCount			= -1;
	_stripCount			= -1;
	
	_ringCheckboxes   = [NSArray arrayWithObjects:_ring1, _ring2, _ring3, _ring4, nil];
	
	_keyCheckboxes    = [NSArray arrayWithObjects:_key1, _key2, _key3, _key4,
																	_key5, _key6, _key7, _key8, nil];
	_keyImages        = [NSArray arrayWithObjects:_keyImage1, _keyImage2, _keyImage3, _keyImage4,
																	_keyImage5, _keyImage6, _keyImage7, _keyImage8, nil];
	_keyLocations     = [NSArray arrayWithObjects:_keyLocation1, _keyLocation2, _keyLocation3, _keyLocation4,
																	_keyLocation5, _keyLocation6, _keyLocation7, _keyLocation8, nil];
							
	_stripCheckboxes  = [NSArray arrayWithObjects:_strip1, _strip2, _strip3,
																	_strip4, _strip5, _strip6, nil];
	_stripIndicators  = [NSArray arrayWithObjects:_stripIndicator1, _stripIndicator2, _stripIndicator3,
																	_stripIndicator4, _stripIndicator5, _stripIndicator6, nil];
	
	[_ringIndicator1 setIndeterminate:NO];
	[_ringIndicator2 setIndeterminate:NO];
	
	[_tabletButton removeAllItems];
	
	// add tablets to the popup menu
	// Apple Events indices are 1 based!
	tabletCount = [WacomTabletDriver tabletCount];

	for (idx = 1; idx <= tabletCount; idx++)
	{
		NSAppleEventDescriptor  *routingDesc   = [WacomTabletDriver routingTableForTablet:idx];
		NSAppleEventDescriptor  *nameReply     = [WacomTabletDriver dataForAttribute:pName
																									 ofType:typeUTF8Text
																							 routingTable:routingDesc];
		NSAppleEventDescriptor  *connectedReply= [WacomTabletDriver dataForAttribute:pIsConnected
																									 ofType:typeBoolean
																							 routingTable:routingDesc];
		NSAppleEventDescriptor  *tabletModelReply= [WacomTabletDriver dataForAttribute:pTabletModel
																									 ofType:typeSInt16
																							 routingTable:routingDesc];
      
		//removed because pTabletUniqueId isn't declared here. 
      NSAppleEventDescriptor __unused *tabletUIDReply= [WacomTabletDriver dataForAttribute:pTabletUniqueID
                                                                              ofType:typeUTF8Text
                                                                        routingTable:routingDesc];

		// Count the number of transducers for a tablet. Not displayed.
		transducerCount = [WacomTabletDriver transducerCountForTablet:idx];
																						
		SInt32 model = 0;
		
		// Getting the tablet model number.  Not displayed.
		if ([tabletModelReply int32Value] > 0)
		{
			model = [tabletModelReply int32Value];
		}

		// Only display tablets which are physically connected right now. (The 
		// Wacom driver returns an entry for every tablet the user has ever 
		// plugged in, even if it is not currently connected.) 
		if ([connectedReply booleanValue] == TRUE)
		{
			NSString *menuName = [NSString stringWithFormat:@"%d: %@", idx, [nameReply stringValue]];
			[_tabletButton addItemWithTitle:menuName];
			[[_tabletButton itemWithTitle:menuName] setTag:idx];
		}
	}

	// select the first tablet in the popup if it exists
	if ([_tabletButton numberOfItems] > 0)
	{
		[_tabletButton selectItem:[_tabletButton itemAtIndex:0]];
		[self tabletSelect:_tabletButton];
	}
	[_tabView selectTabViewItemWithIdentifier:[NSString stringWithFormat: @"%d", eAETouchRing]];
	
	// update UI
	[self updateUI];
	
	// An application needs to create a context before it can query or override
	// functions of tablet controls and it must destroy the context it creates 
	// when it's done with the context upon termination.
	// Here we register for NSApplicationWillTerminateNotification so we will 
	// perform context deletion when terminating. 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:)
					name:NSApplicationWillTerminateNotification object:Nil];
}

///////////////////////////////////////////////////////////////////////////////

//	Create a context for the currently selected tablet in the tablet popup button
//	in response to a click on the "Make Context" button.

- (void)makeContext
{
	UInt32 context = 0;
	
	// destroy current context
	[self destroyContext];
	
	// Create a new Context.
	// Note:	This is a Blank context, because we only intend to customize 
	//			controls. Blank contexts will still follow mapping changes made 
	//			in the control panel. They behave much more transparently than 
	//			Default contexts, which are intended for applications which want 
	//			to take over the tablet and not honor user settings. 
	context = [WacomTabletDriver createContextForTablet:(UInt32)_currentTablet type:pContextTypeBlank];
	[self setContext:context];

	// check validity of the context
	if (![self isContextValid])
	{
		return;
	}
	
	// get control counts
	_ringCount	= [WacomTabletDriver controlCountOfContext:context forControlType:eAETouchRing];
	_keyCount	= [WacomTabletDriver controlCountOfContext:context forControlType:eAEExpressKey];
	_stripCount	= [WacomTabletDriver controlCountOfContext:context forControlType:eAETouchStrip];

	// Tablet driver posts distributed notifications to inform applications of 
	// control data changes from action on the tablet controls (eg pressing an 
	// ExpressKey). 
	// We register for these notifications here.
	// NOTE: Suspend the notifications when we are in the background because our 
	//			overrides are effective only when we are in the foreground. 
	NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter notificationCenterForType:NSLocalNotificationCenterType];
	[distributedNotificationCenter addObserver:self
												 selector:@selector(tabletControlData:)
													  name:@kWacomTabletControlNotification
													object:@kWacomNotificationObject
									suspensionBehavior:NSNotificationSuspensionBehaviorDrop];
	
	// update UI
	[self updateUI];
}

///////////////////////////////////////////////////////////////////////////////

//	Delete the context for the currently selected tablet in the tablet popup button
//	in response to a click on the "Destroy Context" button.

- (void)destroyContext
{
	// do nothing if the context is not valid (has not been created)
	if (![self isContextValid])
	{
		return;
	}
	
	// stop receiving control data notifications
	[[NSDistributedNotificationCenter notificationCenterForType:NSLocalNotificationCenterType] 
				removeObserver:self];
	
	// destroy the context
	[WacomTabletDriver destroyContext:[self context]];
	[self setContext:0];

	// reset data
	[self setRingData:nil];
	[self setKeyData:nil];
	[self setStripData:nil];
	[self setIsControllingRing:NO];
	[self setIsControllingKeys:NO];
	[self setIsControllingStrip:NO];
	
	_ringCount = _keyCount = _stripCount = -1;
	
	// update UI
	[self updateUI];
}

///////////////////////////////////////////////////////////////////////////////

//	Convenient method for getting the currently selected tab.
//	Returns: The tablet id as integer of the currently selected tab.

- (SInt32)currentTab
{
	return [[[_tabView selectedTabViewItem] identifier] intValue];
}

///////////////////////////////////////////////////////////////////////////////

//	Update all UI elements in response to data change.

- (void)updateUI
{
	SInt32   currentTab     = [self currentTab];
	SInt32   controlCount   = [self controlCountOfTabWithID:currentTab];
	
	// update controls outside of the tab
	[_makeContext setEnabled:(_currentTablet > 0)];
	[_makeContext setState:[self isContextValid] ? NSOnState : NSOffState];
	[_makeContext setTitle:[self isContextValid] ? @"Destroy Context" : @"Make Context"];
	[_takeControl setEnabled:[self isContextValid] && 
						[self controlCountOfTabWithID:currentTab] > 0 && 
						![self isControllingTabWithID:currentTab]];
	[_contextField setStringValue:[self isContextValid] ? 
						[[NSNumber numberWithUnsignedLong:[self context]] stringValue]: @"None"];
	
	// update UI of the current tab
	switch (currentTab)
	{
		case eAETouchRing:
		{
			[self updateTouchRingUI];
			break;
		}
		case eAETouchStrip:
		{
			[self updateTouchStripUI];
			break;
		}
		case eAEExpressKey:
		{
			[self updateExpressKeysUI];
			break;
		}
		default:
		{
			break;
		}
	}
	
	// update control count text
	if (controlCount == -1)
	{
		// have not queried for the count yet
		[_controlCountField setStringValue:@""];
	}
	else
	{
		[_controlCountField setIntValue:controlCount];
	}
}

///////////////////////////////////////////////////////////////////////////////

//	Convenient mothod for getting the contorl count for a tab of interest.
//	Parameters:  tabletId_I - The tablet id of interest.
//	Returns:  The number of controls associated with the tab of interest.

- (SInt32)controlCountOfTabWithID:(SInt32)tabletId_I
{
	switch (tabletId_I)
	{
		case eAETouchRing:
		{
			return _ringCount;
		}
		case eAETouchStrip:
		{
			return _stripCount;
		}
		case eAEExpressKey:
		{
			return _keyCount;
		}
		default:
		{
			break;
		}
	}
	return -1;
}

///////////////////////////////////////////////////////////////////////////////

//	Convenient mothod for checking whether we have taken control of the tablet
//	control associated with a tab.
//	Parameters: tabID_I - the tablet id of interest.

- (BOOL)isControllingTabWithID:(SInt32)tabID_I
{
	switch (tabID_I)
	{
		case eAETouchRing:
		{
			return [self isControllingRing];
		}
		case eAETouchStrip:
		{
			return [self isControllingStrip];
		}
		case eAEExpressKey:
		{
			return [self isControllingKeys];
		}
		default:
		{
			break;
		}
	}
	return NO;
}

///////////////////////////////////////////////////////////////////////////////

- (void)setContext:(UInt32)context_I
{
	_context = context_I;
}

///////////////////////////////////////////////////////////////////////////////

- (UInt32)context
{
	return _context;
}

///////////////////////////////////////////////////////////////////////////////

- (BOOL)isContextValid
{
	return [self context] != 0;
}

///////////////////////////////////////////////////////////////////////////////

//	Convenient mothod for converting location id to an NSString.
//	Parameters: locationID - location id of a tablet control.

- (NSString *)locationStringFromID:(eAEControlPosition)locationID_I
{
	switch (locationID_I)
	{
		case eAEControlPositionLeft:
		{
			return @"L";
		}
		case eAEControlPositionRight:
		{
			return @"R";
		}
		case eAEControlPositionTop:
		{
			return @"T";
		}
		case eAEControlPositionBottom:
		{
			return @"B";
		}
		default:
		{
			NSLog(@"Bad location id: %u", locationID_I);
			break;
		}
	}
	return @"";
}

#pragma mark Notification Handling

///////////////////////////////////////////////////////////////////////////////

- (void)willTerminate:(NSNotification*)notification
{
	if ([self isContextValid])
	{
		[self destroyContext];
	}
}

///////////////////////////////////////////////////////////////////////////////

//	Handle tablet data notifications.

- (void)tabletControlData:(NSNotification*)note_I
{
	NSDictionary   *userInfo   = [note_I userInfo];
	SInt32         controlType = (SInt32)[[userInfo objectForKey:@kControlTypeKey] longValue];
	
	switch (controlType)
	{
		case eAETouchRing:
		{
			[self setRingData:userInfo];
			break;
		}
		case eAETouchStrip:
		{
			[self setStripData:userInfo];
			break;
		}
		case eAEExpressKey:
		{
			[self setKeyData:userInfo];
			break;
		}
		default:
		{
			NSLog(@"Bad Control Type : %d", (int)controlType);
			break;
		}
	}
	
	[self updateUI];
}

#pragma mark IBActions

///////////////////////////////////////////////////////////////////////////////

//	This is the action associated with the "Create Context"/"Destroy Context"
//	button. It handles the click in the button.

-(IBAction)createContext:(id)button
{
	if ([button state] == NSOnState)
	{
		[self makeContext];
	}
	else
	{
		[self destroyContext];
	}
}

///////////////////////////////////////////////////////////////////////////////

//	This is the action associated with the tablet popup button.
//	It handles the selection change of the button.

-(IBAction)tabletSelect:(id)button
{
	NSInteger selectedTabletID = [[button selectedItem] tag];
	
	if (_currentTablet != selectedTabletID)
	{
		// destroy current context
		[self destroyContext];
		
		_currentTablet = selectedTabletID;

		// update UI
		[self updateUI];
	}
}

///////////////////////////////////////////////////////////////////////////////

//	This is the action associated with the "Take Control" push button.
//	It will take control of the tablet controls associated with the current tab.

- (IBAction)takeControl:(id)sender
{
	switch ([self currentTab])
	{
		case eAETouchRing:
		{
			[self takeControlOfRing];
			break;
		}
		case eAETouchStrip:
		{
			[self takeControlOfStrip];
			break;
		}
		case eAEExpressKey:
		{
			[self takeControlOfKeys];
			break;
		}
		default:
		{
			break;
		}
	}
	[self updateUI];
}

#pragma mark TouchRing

///////////////////////////////////////////////////////////////////////////////

- (void)setIsControllingRing:(BOOL)flag_I
{
	if (![self isContextValid])
	{
		_isControllingRing = NO;
		return;
	}
	
	_isControllingRing = flag_I;
}

///////////////////////////////////////////////////////////////////////////////

- (BOOL)isControllingRing
{
	return _isControllingRing;
}

///////////////////////////////////////////////////////////////////////////////

- (void)setRingData:(NSDictionary *) data_I
{
	_ringData = nil;
	_ringData = data_I;
}

///////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)ringData
{
	return _ringData;
}

///////////////////////////////////////////////////////////////////////////////

//	Send Apple Events to tablet driver to take control of the ring
//	of the selected tablet.

- (void)takeControlOfRing
{
	UInt32   controlIndex   = 1; // first ring
	UInt32   functionIndex  = 1;
	UInt32   functionCount  = 0;
	
	if (![self isContextValid] ||
		  [self isControllingRing] ||
		  (_currentTablet < 1) ||
		  (_ringCount < 1))
	{
		return;
	}
		
	// get max/min value of the ring
	NSAppleEventDescriptor  *maxReply   = nil;
	NSAppleEventDescriptor  *minReply   = nil;
	
	maxReply = [WacomTabletDriver dataForAttribute:pControlMaxValue
														 ofType:typeUInt32
												 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																												control:1
																										  controlType:eAETouchRing]];
	minReply = [WacomTabletDriver dataForAttribute:pControlMinValue
														 ofType:typeUInt32
												 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																												control:1
																										  controlType:eAETouchRing]];
	_maxRingValue = [maxReply int32Value];
	_minRingValue = [minReply int32Value];
	

	// find out which functions of the ring is available for override
	// this app only cares about the first 4 functions of the first ring
	functionCount = [WacomTabletDriver functionCountOfControl:1 ofContext:[self context] 
										forControlType:eAETouchRing];
	functionCount = (functionCount) > MAX_TOUCH_RING_FUNCTION_COUNT ? 
										MAX_TOUCH_RING_FUNCTION_COUNT : functionCount;
	for (functionIndex = 1; functionIndex <= functionCount; functionIndex++)
	{
		NSAppleEventDescriptor	*aeResponse = nil;
		BOOL							overridden	= NO;
		
		// check if this function is available for override
		aeResponse = [WacomTabletDriver dataForAttribute:pFunctionAvailable
																ofType:typeBoolean
														routingTable:[WacomTabletDriver routingTableForContext:[self context]
																													  control:controlIndex
																												 controlType:eAETouchRing
																													 function:functionIndex] ];
		if (([aeResponse booleanValue] != FALSE))
		{
			// this ring function can be overridden
			// send apple event to override
			Boolean overrideFlag = 1;
			overridden = [WacomTabletDriver setBytes:&overrideFlag 
														 ofSize:sizeof(overrideFlag)
														 ofType:typeBoolean 
												 forAttribute:pOverrideFlag
												 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																												control:1
																										  controlType:eAETouchRing
																											  function:functionIndex] ];
			if (!overridden)
			{
				NSLog(@"Failed to override TouchRing function #%d.", functionIndex);
			}
		}

		// check the associated checkbox if the function is overridden successfully
		[[_ringCheckboxes objectAtIndex:(functionIndex - 1)] setState:overridden ? NSOnState : NSOffState];
	}

	[self setIsControllingRing:YES];
}

///////////////////////////////////////////////////////////////////////////////

//	Update all UI elements in the TouchRing tab in response to data change.

- (void)updateTouchRingUI
{
	[_ringMode setEnabled:NO];
	
	if (![self isContextValid] || ![self isControllingRing])
	{
		// not controlling the ring
		SInt32 idx;
		for (idx = 0; idx < [_ringCheckboxes count]; idx++)
		{
			[[_ringCheckboxes objectAtIndex:idx] setState:NSOffState];
		}
		
		[_ringMode selectCellWithTag:1];
		[_ringMax setStringValue:@""];
		[_ringMin setStringValue:@""];
		[_ringValue setStringValue:@""];
		
		[_ringIndicator1 setDoubleValue:0.];
		[_ringIndicator2 setDoubleValue:0.];
		[_ringIndicator3 setIntValue:0];
		[_ringIndicator4 setIntValue:0];

		_lastRingValue = _ringValueDelta = 0;
	}
	else
	{
		// controlling the ring
		NSDictionary   *dict          = [self ringData];
		UInt32         tabletIndex    = (UInt32)[[dict objectForKey:@kTabletNumberKey] unsignedLongValue];
		UInt32         controlIndex   = (UInt32)[[dict objectForKey:@kControlNumberKey] unsignedLongValue];
		
		if (tabletIndex == _currentTablet && 
			 controlIndex == 1) // we only deal with the first ring
		{
			id controlValue = [dict objectForKey:@kControlValueKey];
			UInt32 functionIndex = (UInt32)[[dict objectForKey:@kFunctionNumberKey] unsignedLongValue];
			if (functionIndex == 0)
			{
				// unspecified => the first function
				functionIndex = 1;
			}
			
			if ([[_ringMode selectedCell] tag] != functionIndex)
			{
				// ring function changed
				// select the new function
				[_ringMode selectCellWithTag:functionIndex];
				
				// reset some cache values
				_lastRingValue = _ringValueDelta = 0;
			}
			
			switch (functionIndex)
			{
				case 1:
				{
					[_ringIndicator1 setMinValue:_minRingValue];
					[_ringIndicator1 setMaxValue:_maxRingValue];
					[_ringIndicator1 setDoubleValue:[controlValue doubleValue]];
					break;
				}
				case 2:
				{
					[_ringIndicator2 setMinValue:_minRingValue];
					[_ringIndicator2 setMaxValue:_maxRingValue];
					[_ringIndicator2 setDoubleValue:[controlValue doubleValue]];
					break;
				}
				case 3:
				{
					[self adjustLevelIndicator:_ringIndicator3 
									withRingValue:(UInt32)[controlValue unsignedLongValue] sensitivity:5];
					break;
				}
				case 4:
				{
					[self adjustLevelIndicator:_ringIndicator4 
									withRingValue:(UInt32)[controlValue unsignedLongValue] sensitivity:10];
					break;
				}
				default:
				{
					break;
				}
			}
			
			[_ringValue setIntValue:[controlValue intValue]];
		}
		
		[_ringMax setIntValue:_maxRingValue];
		[_ringMin setIntValue:_minRingValue];
	}
}

///////////////////////////////////////////////////////////////////////////////

//	Update the level indicator associated with a touch ring function in
//	response to ring data change.

- (void)adjustLevelIndicator:(NSLevelIndicator*)indicator
					withRingValue:(UInt32)value_I sensitivity:(SInt32)sensitivity_I
{
	if(value_I && _lastRingValue)
	{
		SInt32   split = _maxRingValue/2;
		SInt32   diff  = value_I - _lastRingValue;
		
		if (diff > split)
		{
			diff = diff - _maxRingValue;
		}
		else if (diff < -split)
		{
			diff += _maxRingValue;
		}
		
		_ringValueDelta += diff;
		if (_ringValueDelta > sensitivity_I || _ringValueDelta < -sensitivity_I)
		{
			SInt32 direction = _ringValueDelta > 0 ? 1 : -1;
			SInt32 newIndicationvalue = [indicator intValue] + direction;
			if(newIndicationvalue > 9) newIndicationvalue = 9;
			if(newIndicationvalue < 0) newIndicationvalue = 0;
			[indicator setIntValue:newIndicationvalue];
			_ringValueDelta = 0;
		}
		_lastRingValue = value_I;
	}
	else
	{
		_lastRingValue = value_I;
	}
}

#pragma mark ExpressKeys

///////////////////////////////////////////////////////////////////////////////

- (void)setIsControllingKeys:(BOOL)flag_I
{
	if (![self isContextValid])
	{
		_isControllingKeys = NO;
		return;
	}
	
	_isControllingKeys = flag_I;
}


///////////////////////////////////////////////////////////////////////////////

- (BOOL)isControllingKeys
{
	return _isControllingKeys;
}

///////////////////////////////////////////////////////////////////////////////

- (void)setKeyData:(NSDictionary *)data_I
{
	_keyData = nil;
	_keyData = data_I;
}

///////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)keyData
{
	return _keyData;
}

///////////////////////////////////////////////////////////////////////////////

//	Send Apple Events to tablet driver to take control of the ExpressKeys
//	of the selected tablet.

- (void)takeControlOfKeys
{
	BOOL     testedIcon     = NO;
	UInt32   controlIndex   = 1;
	UInt32   iconWidth      = 0;
	UInt32   iconHeight     = 0;
	UInt32   pixelFormat    = 0;
	UInt32   keyCount       = 0;
	
	NSAppleEventDescriptor *aeMax = nil;
	NSAppleEventDescriptor *aeMin = nil;
	

	if (![self isContextValid] ||
		  [self isControllingKeys] ||
		  (_currentTablet < 1) ||
		  (_keyCount < 1))
	{
		return;
	}
	
	// get max/min value
	aeMax = [WacomTabletDriver dataForAttribute:pControlMaxValue
													 ofType:typeUInt32
											 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																											control:1
																									  controlType:eAEExpressKey] ];
	aeMin = [WacomTabletDriver dataForAttribute:pControlMinValue
													 ofType:typeUInt32
											 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																											control:1 // assume all keys have the same min value
																									  controlType:eAEExpressKey] ];
	_maxKeyValue = [aeMax int32Value];
	_minKeyValue = [aeMin int32Value];

	// find out the express keys available for override
	keyCount = _keyCount > MAX_EXPRESS_KEY_COUNT ? MAX_EXPRESS_KEY_COUNT : _keyCount;
	for (controlIndex = 1; controlIndex <= keyCount; controlIndex++)
	{
		UInt32						functionIndex			= 1;	// assume each key has one function
		NSAppleEventDescriptor	*aeResponse 			= nil;
		BOOL							overridden				= NO;
		NSAppleEventDescriptor	*controlRoutingDesc	= nil;
		NSAppleEventDescriptor	*functionRoutingDesc = nil;
		
		controlRoutingDesc = [WacomTabletDriver routingTableForContext:[self context]
																				 control:controlIndex
																			controlType:eAEExpressKey];
																			
		functionRoutingDesc = [WacomTabletDriver routingTableForContext:[self context]
																				  control:controlIndex
																			 controlType:eAEExpressKey
																				 function:functionIndex];
		// get icon info
		// we just pick one to ask for the display info assuming it's the same for all
		if (controlIndex == 1)
		{
			// note that there is no need to specify the function index for this 
			// info if you do, the function index would be ignored anyway 
			
			iconWidth   = [[WacomTabletDriver dataForAttribute:pIconWidth 
																	  ofType:typeUInt32
															  routingTable:controlRoutingDesc] int32Value];
			
			iconHeight  = [[WacomTabletDriver dataForAttribute:pIconHeight 
																	  ofType:typeUInt32
															  routingTable:controlRoutingDesc] int32Value];
			
			pixelFormat = [[WacomTabletDriver dataForAttribute:pIconPixelFormat 
																	  ofType:typeUInt32
															  routingTable:controlRoutingDesc] int32Value];
			[_keyIconWidth setIntValue:iconWidth];
			[_keyIconHeight setIntValue:iconHeight];
			[_keyPixelFormat setIntValue:pixelFormat];
		}
		
		// find the location of this control
		aeResponse = [WacomTabletDriver dataForAttribute:pControlLocation
																ofType:typeUInt32
														routingTable:controlRoutingDesc ];
		
		[[_keyLocations objectAtIndex:(controlIndex - 1)] 
					setStringValue:[self locationStringFromID:[aeResponse int32Value]]];
		
		// check if this function is available for override
		aeResponse = [WacomTabletDriver dataForAttribute:pFunctionAvailable
																ofType:typeBoolean
														routingTable:functionRoutingDesc ];
		if ([aeResponse booleanValue] != 0)
		{
			// this ExpressKey function is available for override
			// send apple event to override
			Boolean overrideFlag = 1;
			overridden = [WacomTabletDriver setBytes:&overrideFlag 
														 ofSize:sizeof(overrideFlag)
														 ofType:typeBoolean 
												 forAttribute:pOverrideFlag
												 routingTable:functionRoutingDesc ];
			if (overridden)
			{
				// override successfully
				BOOL success = NO;
				NSString *overrideName = [NSString stringWithFormat:@"ExpressKey #%d", controlIndex];
				if (pixelFormat > 0 && iconHeight > 0 && iconWidth > 0 && !testedIcon)
				{
					// this control has a OLED display
					// set custom icon
					NSImage *image = [NSImage imageNamed:GRAB_IMAGE];
					NSData *imageData = [image TIFFRepresentation];
					if ([imageData length])
					{
						success = [WacomTabletDriver setBytes:(void *)[imageData bytes] 
																 ofSize:(UInt32)[imageData length]
																 ofType:typeWTDData
														 forAttribute:pOverrideIcon
														 routingTable:controlRoutingDesc ];
						if (success)
						{
							[[_keyImages objectAtIndex:(controlIndex - 1)] setImage:image];
						}
						else
						{
							NSLog(@"Failed to override icon for ExpressKey #%d.", controlIndex);
						}
					}
					testedIcon = YES;
				}
				
				// set custom name
				success = [WacomTabletDriver setBytes:(void *)[overrideName UTF8String] 
														 ofSize:(UInt32)[overrideName length]
														 ofType:typeUTF8Text 
												 forAttribute:pOverrideName
												 routingTable:functionRoutingDesc ];
				if (success)
				{
					// get the custom name and update UI
					aeResponse = [WacomTabletDriver dataForAttribute:pOverrideName
																			ofType:typeUTF8Text
																	routingTable:functionRoutingDesc ];
					if (nil == aeResponse)
					{
						NSLog(@"Failed to get override name of ExpressKey #%d.", controlIndex);
					}
					
					[[_keyCheckboxes objectAtIndex:(controlIndex - 1)] setTitle:[aeResponse stringValue]];
				}
				else
				{
					NSLog(@"Failed to override name for ExpressKey #%d.", controlIndex);
				}
			}
			else
			{
				NSLog(@"Failed to override ExpressKey #%d.", controlIndex);
			}
		}
		else
		{
			[[_keyCheckboxes objectAtIndex:(controlIndex - 1)] setTitle:@"Unavailable"];
		}
		
		// check the associated checkbox if the function override was sucessful
		[[_keyCheckboxes objectAtIndex:(controlIndex - 1)] setState:overridden ? NSOnState : NSOffState];
	}

	[self setIsControllingKeys:YES];
}

///////////////////////////////////////////////////////////////////////////////

//	Update all UI elements in the ExpressKeys tab in response to data change.

- (void)updateExpressKeysUI
{
	if (![self isContextValid] || ![self isControllingKeys])
	{
		SInt32 idx;
		for (idx = 0; idx < [_keyCheckboxes count]; idx++)
		{
			[[_keyCheckboxes objectAtIndex:idx] setState:NSOffState];
			[[_keyCheckboxes objectAtIndex:idx] setTitle:@""];
			[[_keyImages objectAtIndex:idx] setImage:nil];
			[[_keyLocations objectAtIndex:idx] setStringValue:[NSString stringWithFormat:@"%d", idx + 1]];
		}
		
		[_keyMax setStringValue:@""];
		[_keyMin setStringValue:@""];
		[_keyValue setStringValue:@""];
		[_keyIconWidth setStringValue:@""];
		[_keyIconHeight setStringValue:@""];
		[_keyPixelFormat setStringValue:@""];
	}
	else
	{
		NSDictionary *dict = [self keyData];
		UInt32 tabletIndex = (UInt32)[[dict objectForKey:@kTabletNumberKey] unsignedLongValue];
		if (tabletIndex == _currentTablet)
		{
			[_keyValue setStringValue:[NSString stringWithFormat:@"%ld (Button #%ld)", 
					[[dict objectForKey:@kControlValueKey] unsignedLongValue], 
					[[dict objectForKey:@kControlNumberKey] unsignedLongValue]]];
		}
		
		[_keyMax setIntValue:_maxKeyValue];
		[_keyMin setIntValue:_minKeyValue];
	}
}

#pragma mark TouchStrip

///////////////////////////////////////////////////////////////////////////////

- (void)setIsControllingStrip:(BOOL)flag_I
{
	if (![self isContextValid])
	{
		_isControllingStrip = NO;
		return;
	}
	_isControllingStrip = flag_I;
}

///////////////////////////////////////////////////////////////////////////////

- (BOOL)isControllingStrip
{
	return _isControllingStrip;
}

///////////////////////////////////////////////////////////////////////////////

- (void)setStripData:(NSDictionary *)data_I
{
	_stripData = nil;
	_stripData = data_I;
}

///////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)stripData
{
	return _stripData;
}

///////////////////////////////////////////////////////////////////////////////

//	Send Apple Events to tablet driver to take control of the touch
//	strips of the selected tablet.

- (void)takeControlOfStrip
{
	UInt32   controlIndex   = 1;
	UInt32   functionIndex  = 1;
	UInt32   functionCount  = 0;
	
	if (![self isContextValid] ||
		  [self isControllingRing] ||
		  (_currentTablet < 1) ||
		  (_stripCount < 1))
	{
		return;
	}
	
	NSAppleEventDescriptor *aeMax = nil;
	NSAppleEventDescriptor *aeMin = nil;
	
	// get max/min value of the first touch strip (this app only cares about the first touch strip)
	aeMax = [WacomTabletDriver dataForAttribute:pControlMaxValue
													 ofType:typeUInt32
											 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																											control:1
																									  controlType:eAETouchStrip] ];
	aeMin = [WacomTabletDriver dataForAttribute:pControlMinValue
													 ofType:typeUInt32
											 routingTable:[WacomTabletDriver routingTableForContext:[self context]
																											control:1
																									  controlType:eAETouchStrip] ];
	_maxStripValue = [aeMax int32Value];
	_minStripValue = [aeMin int32Value];


	// find out which functions of the touch strip is available for override
	// this app only cares about the first 2 functions of the first touch strip
	functionCount = [WacomTabletDriver functionCountOfControl:1
																	ofContext:[self context] 
															 forControlType:eAETouchStrip];
	for (controlIndex = 1; 
		  controlIndex <= _stripCount && controlIndex <= MAX_TOUCH_STRIP_COUNT; 
		  controlIndex++)
	{
		for (functionIndex = 1; 
			  functionIndex <= functionCount && functionIndex <= MAX_TOUCH_STRIP_FUNCTION_COUNT; 
			  functionIndex++)
		{
			BOOL overridden = NO;
			
			// check if this function is available for override
			NSAppleEventDescriptor	*routingDesc = [WacomTabletDriver routingTableForContext:[self context]
																											control:controlIndex
																									  controlType:eAETouchStrip
																										  function:functionIndex];
			NSAppleEventDescriptor *aeResponse = [WacomTabletDriver dataForAttribute:pFunctionAvailable 
																									ofType:typeBoolean
																							routingTable:routingDesc];

			if ([aeResponse booleanValue] != 0)
			{
				// this touch strip function can be overridden
				// send apple event to override
				Boolean overrideFlag = 1;
				overridden = [WacomTabletDriver setBytes:&overrideFlag 
															 ofSize:sizeof(overrideFlag)
															 ofType:typeBoolean 
													 forAttribute:pOverrideFlag
													 routingTable:routingDesc ];
				if (!overridden)
				{
					NSLog(@"Failed to override TouchStrip function #%d.", functionIndex);
				}
			}

			// check the associated checkbox if the function override was successful
			[[_stripCheckboxes objectAtIndex:(controlIndex - 1) * 
						MAX_TOUCH_STRIP_FUNCTION_COUNT + (functionIndex - 1)]
						setState:overridden ? NSOnState : NSOffState];
		}
	}

	[self setIsControllingStrip:YES];
}
	
///////////////////////////////////////////////////////////////////////////////

//	Update all UI elements in the TouchStrip tab in response to data change.

- (void)updateTouchStripUI
{
	NSDictionary *dict = nil;
	
	[_stripMode1 setEnabled:NO];
	[_stripMode2 setEnabled:NO];
	
	if (![self isContextValid] || ![self isControllingStrip])
	{
		SInt32 idx;
		for (idx = 0; idx < [_stripCheckboxes count]; idx++)
		{
			[[_stripCheckboxes objectAtIndex:idx] setState:NSOffState];
			[[_stripIndicators objectAtIndex:idx] setIntValue:0];
		}
		
		[_stripMode1 selectCellWithTag:1];
		[_stripMode2 selectCellWithTag:1];
		[_stripMax setStringValue:@""];
		[_stripMin setStringValue:@""];
		[_stripValue setStringValue:@""];
	}
	else if (dict == [self stripData])
	{
		UInt32 tabletIndex = (UInt32)[[dict objectForKey:@kTabletNumberKey] unsignedLongValue];
		UInt32 controlIndex = (UInt32)[[dict objectForKey:@kControlNumberKey] unsignedLongValue];
		
		if (tabletIndex <= 0)
		{
			NSLog(@"Bad Tablet Index");
		}
		if (controlIndex <= 0 || controlIndex > _stripCount)
		{
			NSLog(@"Bad Control Index");
		}
		
		if (tabletIndex == _currentTablet && controlIndex >= 1 && controlIndex <= MAX_TOUCH_STRIP_COUNT)
		{
			UInt32 functionIndex = (UInt32)[[dict objectForKey:@kFunctionNumberKey] unsignedLongValue];
			UInt32 controlValue = (UInt32)[[dict objectForKey:@kControlValueKey] unsignedLongValue];
			
			if (functionIndex <= 0)
			{
				NSLog(@"Bad Function Index");
			}
			else
			{
				NSLevelIndicator *indicator = [_stripIndicators objectAtIndex:
							(controlIndex - 1) * MAX_TOUCH_STRIP_FUNCTION_COUNT + (functionIndex - 1)];
				
				[indicator setIntValue:floor(controlValue * 
							([_stripMax intValue] - [_stripMin intValue]) / 
							([indicator maxValue] - [indicator minValue]))];
				
				[((controlIndex == 1) ? _stripMode1 :  _stripMode2) selectCellWithTag:functionIndex];
			}
			
			[_stripValue setIntValue:controlValue];
		}
		
		[_stripMax setIntValue:_maxStripValue];
		[_stripMin setIntValue:_minStripValue];
	}
}

#pragma mark Delegate Methods

///////////////////////////////////////////////////////////////////////////////

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self updateUI];
}

///////////////////////////////////////////////////////////////////////////////
@end
