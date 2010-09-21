/*
 * AppController.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <StropheCappuccino/StropheCappuccino.j>
@import <GrowlCappuccino/GrowlCappuccino.j>
@import <VNCCappuccino/VNCCappuccino.j>
@import <LPKit/LPKit.j>
@import <iTunesTabView/iTunesTabView.j>

//@import <LPKit/LPCrashReporter.j>

//@import "LPMultiLineTextField.j";
@import "TNAvatarManager.j";
@import "TNCategoriesAndGlobalSubclasses.j";
@import "TNDatasourceRoster.j";
@import "TNOutlineViewRoster.j";
@import "TNToolbar.j";
@import "TNModuleLoader.j";
@import "TNViewProperties.j";
@import "TNWindowAddContact.j";
@import "TNWindowAddGroup.j";
@import "TNWindowConnection.j";
@import "TNModule.j";
@import "TNViewLineable.j";
@import "TNUserDefaults.j";
@import "TNTableViewDataSource.j";
@import "TNSearchField.j";
@import "TNStepper.j";

/*! @global
    @group TNArchipelEntityType
    This represent a Hypervisor XMPP entity
*/
TNArchipelEntityTypeHypervisor      = @"hypervisor";

/*! @global
    @group TNArchipelEntityType
    This represent a virtual machine XMPP entity
*/
TNArchipelEntityTypeVirtualMachine  = @"virtualmachine";


/*! @global
    @group TNArchipelEntityType
    This represent a user XMPP entity
*/
TNArchipelEntityTypeUser            = @"user";

/*! @global
    @group TNArchipelEntityType
    This represent a group XMPP entity
*/
TNArchipelEntityTypeGroup            = @"group";


/*! @global
    @group TNArchipelStatus
    This string represent a status Available
*/
TNArchipelStatusAvailableLabel  = @"Available";

/*! @global
    @group TNArchipelStatus
    This string represent a status Away
*/
TNArchipelStatusAwayLabel       = @"Away";

/*! @global
    @group TNArchipelStatus
    This string represent a status Busy
*/
TNArchipelStatusBusyLabel       = @"Busy";

/*! @global
    @group TNArchipelStatus
    This string represent a status DND
*/
TNArchipelStatusDNDLabel       = @"Do not disturb";



/*! @global
    @group TNArchipelAction
    ask for removing the current roster item
*/
TNArchipelActionRemoveSelectedRosterEntityNotification = @"TNArchipelActionRemoveSelectedRosterEntityNotification";

TNArchipelXMPPNamespace             = "http://archipelproject.org";
TNArchipelRememberOpenedGroup       = @"TNArchipelRememberOpenedGroup_";
TNArchipelGroupMergedNotification   = @"TNArchipelGroupMergedNotification";

/*! @ingroup archipelcore
    This is the main application controller. It is loaded from MainMenu.cib.
    Anyone that is interessted in the way of Archipel is working should begin
    to read this class. This is the main application entry point.
*/
@implementation AppController : CPObject
{
    @outlet CPButtonBar         buttonBarLeft;
    @outlet CPImageView         ledIn;
    @outlet CPImageView         ledOut;
    @outlet CPSplitView         leftSplitView;
    @outlet CPSplitView         mainHorizontalSplitView;
    @outlet CPTextField         textFieldAboutVersion;
    @outlet CPTextField         textFieldLoadedBundle;
    @outlet CPView              filterView;
    @outlet CPView              leftView;
    @outlet CPView              rightView;
    @outlet CPView              statusBar;
    @outlet CPView              viewLoadingModule;
    @outlet CPWebView           helpView;
    @outlet CPWebView           webViewAboutCredits;
    @outlet CPWindow            theWindow;
    @outlet CPWindow            windowAboutArchipel;
    @outlet TNSearchField       filterField;
    @outlet TNViewProperties    propertiesView;
    @outlet TNWhiteWindow       windowModuleLoading;
    @outlet TNWindowAddContact  addContactWindow;
    @outlet TNWindowAddGroup    addGroupWindow;
    @outlet TNWindowConnection  connectionWindow;
    @outlet TNAvatarManager     windowAvatarManager;

    BOOL                        _shouldShowHelpView;
    CPImage                     _imageLedInData;
    CPImage                     _imageLedNoData;
    CPImage                     _imageLedOutData;
    CPMenu                      _mainMenu;
    CPMenu                      _modulesMenu;
    CPPlatformWindow            _platformHelpWindow;
    CPScrollView                _outlineScrollView;
    TNiTunesTabView             _moduleTabView;
    CPTextField                 _rightViewTextField;
    CPTimer                     _ledInTimer;
    CPTimer                     _ledOutTimer;
    CPTimer                     _moduleLoadingDelay;
    CPWindow                    _helpWindow;
    int                         _tempNumberOfReadyModules;
    TNDatasourceRoster          _mainRoster;
    TNModuleLoader              _moduleLoader;
    TNOutlineViewRoster         _rosterOutlineView;
    TNToolbar                   _mainToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
}

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    [connectionWindow orderOut:nil];
    
    var bundle      = [CPBundle mainBundle];
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelHelpWindowURL"], @"TNArchipelHelpWindowURL",
            [bundle objectForInfoDictionaryKey:@"TNArchipelVersion"], @"TNArchipelVersion",
            [bundle objectForInfoDictionaryKey:@"TNArchipelModuleLoadingDelay"], @"TNArchipelModuleLoadingDelay",
            [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"], @"TNArchipelConsoleDebugLevel",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHService"], @"TNArchipelBOSHService",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHResource"], @"TNArchipelBOSHResource",
            [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"], @"TNArchipelConsoleDebugLevel",
            [bundle objectForInfoDictionaryKey:@"TNArchipelCopyright"], @"TNArchipelCopyright"
    ]];
    
    // register logs
    CPLogRegister(CPLogConsole, [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"]);
    
    [mainHorizontalSplitView setIsPaneSplitter:YES];
    
    [viewLoadingModule setBackgroundColor:[CPColor colorWithHexString:@"D3DADF"]];
    
    var posx;
    if (posx = [defaults integerForKey:@"mainSplitViewPosition"])
    {
        CPLog.trace("recovering with of main vertical CPSplitView from last state");
        [mainHorizontalSplitView setPosition:posx ofDividerAtIndex:0];

        var bounds = [leftView bounds];
        bounds.size.width = posx;
        [leftView setFrame:bounds];
    }
    [mainHorizontalSplitView setDelegate:self];    
    
    /* hide main window */
    [theWindow orderOut:nil];
    
    /* toolbar */
    CPLog.trace("initializing mianToolbar");
    _mainToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_mainToolbar];

    /* properties view */
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:YES];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:propertiesView];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];
    [propertiesView setAvatarManager:windowAvatarManager];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
    [_rosterOutlineView setEntityRenameField:[propertiesView entryName]];
    [filterField setOutlineView:_rosterOutlineView];

    /* init scroll view of the outline view */
    CPLog.trace(@"initializing _outlineScrollView");
    _outlineScrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
    [_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_outlineScrollView setAutohidesScrollers:YES];
    [[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [_outlineScrollView setDocumentView:_rosterOutlineView];

    CPLog.trace(@"adding _outlineScrollView as subview of leftView");
    [leftView addSubview:_outlineScrollView];

    /* right view */
    CPLog.trace(@"initializing rightView");
    [rightView setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [rightView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    
    /* filter view. */
    CPLog.trace(@"initializing the filterView");
    [filterView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];

    /* tab module view */
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[TNiTunesTabView alloc] initWithFrame:[rightView bounds]];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setBackgroundColor:[CPColor whiteColor]];
    [rightView addSubview:_moduleTabView];

    /* message in _moduleTabView */
    _rightViewTextField = [CPTextField labelWithTitle:@""];
    var bounds  = [_moduleTabView bounds];

    [_rightViewTextField setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [_rightViewTextField setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [_rightViewTextField setAlignment:CPCenterTextAlignment]
    [_rightViewTextField setFont:[CPFont boldSystemFontOfSize:18]];
    [_rightViewTextField setTextColor:[CPColor grayColor]];
    [_moduleTabView addSubview:_rightViewTextField];
    
    /* main menu */
    [self makeMainMenu];
    
    /* module Loader */
    // var view    = [windowModuleLoading contentView];
    // var frame   = [windowModuleLoading frame];
    [windowModuleLoading center]
    [windowModuleLoading makeKeyAndOrderFront:nil];
    
    CPLog.trace(@"initializing _moduleLoader");
    _moduleLoader = [[TNModuleLoader alloc] init]
    
    [_moduleLoader setDelegate:self];
    [_moduleTabView setDelegate:_moduleLoader];
    [_moduleLoader setMainToolbar:_mainToolbar];
    [_moduleLoader setMainTabView:_moduleTabView];
    [_moduleLoader setInfoTextField:_rightViewTextField];
    [_moduleLoader setModulesPath:@"Modules/"]
    [_moduleLoader setMainModuleView:rightView];
    [_moduleLoader setModulesMenu:_modulesMenu];
    [_rosterOutlineView setModulesTabView:_moduleTabView];

    CPLog.trace(@"Starting loading all modules");
    [_moduleLoader load];

    
    CPLog.trace(@"Display _helpWindow");
    _shouldShowHelpView = YES;
    [self showHelpView];
    
    CPLog.trace(@"initializing Growl");
    var growl = [TNGrowlCenter defaultCenter];
    [growl setView:rightView];
    
    CPLog.trace(@"Initializing the traffic status LED");
    [statusBar setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"statusBarBg.png"]]]];
    _imageLedInData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-in.png"]];
    _imageLedOutData    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-out.png"]];
    _imageLedNoData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-no.png"]];
    
    // buttonBar
    CPLog.trace(@"Initializing the roster button bar");
    [mainHorizontalSplitView setButtonBar:buttonBarLeft forDividerAtIndex:0];
    
    var bezelColor              = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    var leftBezel               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezel.png"] size:CGSizeMake(2, 26)];
    var centerBezel             = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    var rightBezel              = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezel.png"] size:CGSizeMake(2, 26)];
    var buttonBezel             = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezel, centerBezel, rightBezel] isVertical:NO]];
    var leftBezelHighlighted    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezelHighlighted.png"] size:CGSizeMake(2, 26)];
    var centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    var rightBezelHighlighted   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezelHighlighted.png"] size:CGSizeMake(2, 26)];
    var buttonBezelHighlighted  = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezelHighlighted, centerBezelHighlighted, rightBezelHighlighted] isVertical:NO]];
    var plusButton              = [[TNButtonBarPopUpButton alloc] initWithFrame:CPRectMake(0,0,30, 30)];
    var plusMenu                = [[CPMenu alloc] init];
    var minusButton             = [CPButtonBar minusButton];
    
    [buttonBarLeft setValue:bezelColor forThemeAttribute:"bezel-color"];
    [buttonBarLeft setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBarLeft setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];
    
    [plusButton setTarget:self];
    [plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"plus-menu.png"] size:CPSizeMake(20, 20)]];
    [plusButton setBordered:NO];
    [plusButton setImagePosition:CPImageOnly];
    
    [plusMenu addItemWithTitle:@"Add a contact" action:@selector(addContact:) keyEquivalent:@""];
    [plusMenu addItemWithTitle:@"Add a group" action:@selector(addGroup:) keyEquivalent:@""];
    [plusButton setMenu:plusMenu];
    
    [minusButton setTarget:self];
    [minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"minus.png"] size:CPSizeMake(20, 20)]];
    [minusButton setAction:@selector(didMinusBouttonClicked:)];

    [buttonBarLeft setButtons:[plusButton, minusButton]];
    
    // copyright;
    [self copyright];
    
    // about window
    [webViewAboutCredits setMainFrameURL:[bundle pathForResource:@"credits.html"]];
    [webViewAboutCredits setBorderedWithHexColor:@"#C0C7D2"];
    [textFieldAboutVersion setStringValue:[defaults objectForKey:@"TNArchipelVersion"]];
    
    /* notifications */
    var center = [CPNotificationCenter defaultCenter];

    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionStatusConnected object:nil];
    
    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheConnectionStatusDisconnecting object:nil];
    
    CPLog.trace(@"registering for notification CPApplicationWillTerminateNotification");
    [center addObserver:self selector:@selector(onApplicationTerminate:) name:CPApplicationWillTerminateNotification object:nil];
    
    CPLog.trace(@"registering for notification TNArchipelModulesAllReadyNotification");
    [center addObserver:self selector:@selector(allModuleReady:) name:TNArchipelModulesAllReadyNotification object:nil];

    CPLog.trace(@"registering for notification TNArchipelActionRemoveSelectedRosterEntityNotification");
    [center addObserver:self selector:@selector(didMinusBouttonClicked:) name:TNArchipelActionRemoveSelectedRosterEntityNotification object:nil];
    
    CPLog.info(@"Initialization of AppController OK");
    
    _tempNumberOfReadyModules = -1;
}

- (void)makeMainMenu
{
    CPLog.trace(@"Creating the main menu");
    
    // free the menu
    // _mainMenu = [theWindow menu]; //[[CPMenu alloc] init];
    // 
    // for (var i = 0; i < [[_mainMenu itemArray] count]; i++)
    //     [_mainMenu removeItem:[[_mainMenu itemArray] objectAtIndex:i]];
    _mainMenu = [[CPMenu alloc] init];
    
    var archipelItem    = [_mainMenu addItemWithTitle:@"Archipel" action:nil keyEquivalent:@""];
    var contactsItem    = [_mainMenu addItemWithTitle:@"Contacts" action:nil keyEquivalent:@""];
    var groupsItem      = [_mainMenu addItemWithTitle:@"Groups" action:nil keyEquivalent:@""];
    var statusItem      = [_mainMenu addItemWithTitle:@"Status" action:nil keyEquivalent:@""];
    var navigationItem  = [_mainMenu addItemWithTitle:@"Navigation" action:nil keyEquivalent:@""];
    var moduleItem      = [_mainMenu addItemWithTitle:@"Modules" action:nil keyEquivalent:@""];
    var helpItem        = [_mainMenu addItemWithTitle:@"Help" action:nil keyEquivalent:@""];
    
    // Archipel
    var archipelMenu = [[CPMenu alloc] init];
    [archipelMenu addItemWithTitle:@"About Archipel" action:@selector(showAboutWindow:) keyEquivalent:@""];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Preferences" action:nil keyEquivalent:@""];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Log out" action:@selector(logout:) keyEquivalent:@"Q"];
    [archipelMenu addItemWithTitle:@"Quit" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:archipelMenu forItem:archipelItem];
    
    // Groups
    var groupsMenu = [[CPMenu alloc] init];
    [groupsMenu addItemWithTitle:@"Add group" action:@selector(addGroup:) keyEquivalent:@"G"];
    [groupsMenu addItemWithTitle:@"Delete group" action:@selector(deleteGroup:) keyEquivalent:@"D"];
    [groupsMenu addItem:[CPMenuItem separatorItem]];
    [groupsMenu addItemWithTitle:@"Rename group" action:@selector(renameGroup:) keyEquivalent:@""];
    [_mainMenu setSubmenu:groupsMenu forItem:groupsItem];
    
    // Contacts
    var contactsMenu = [[CPMenu alloc] init];
    [contactsMenu addItemWithTitle:@"Add contact" action:@selector(addContact:) keyEquivalent:@"n"];
    [contactsMenu addItemWithTitle:@"Delete contact" action:@selector(deleteContact:) keyEquivalent:@"d"];
    [contactsMenu addItem:[CPMenuItem separatorItem]];
    [contactsMenu addItemWithTitle:@"Rename contact" action:@selector(renameContact:) keyEquivalent:@"R"];
    [contactsMenu addItem:[CPMenuItem separatorItem]];
    [contactsMenu addItemWithTitle:@"Reload vCard" action:@selector(reloadContactVCard:) keyEquivalent:@""];
    [_mainMenu setSubmenu:contactsMenu forItem:contactsItem];
    
    // Status
    var statusMenu = [[CPMenu alloc] init];
    [statusMenu addItemWithTitle:@"Set status available" action:nil keyEquivalent:@"1"];
    [statusMenu addItemWithTitle:@"Set status away" action:nil keyEquivalent:@"2"];
    [statusMenu addItemWithTitle:@"Set status busy" action:nil keyEquivalent:@"3"];
    [statusMenu addItem:[CPMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Set custom status" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:statusMenu forItem:statusItem];
    
    // navigation
    var navigationMenu = [[CPMenu alloc] init];
    [navigationMenu addItemWithTitle:@"Hide main menu" action:@selector(switchMainMenu:) keyEquivalent:@"U"];
    [navigationMenu addItemWithTitle:@"Search entity" action:@selector(focusFilter:) keyEquivalent:@"F"];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Select next entity" action:@selector(selectNextEntity:) keyEquivalent:nil];
    [navigationMenu addItemWithTitle:@"Select previous entity" action:@selector(selectPreviousEntity:) keyEquivalent:nil];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Expand group" action:@selector(expandGroup:) keyEquivalent:@""];
    [navigationMenu addItemWithTitle:@"Collapse group" action:@selector(collapseGroup:) keyEquivalent:@""];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Expand all groups" action:@selector(expandAllGroups:) keyEquivalent:@""];
    [navigationMenu addItemWithTitle:@"Collapse all groups" action:@selector(collapseAllGroups:) keyEquivalent:@""];
    [_mainMenu setSubmenu:navigationMenu forItem:navigationItem];
    
    // Modules
    _modulesMenu = [[CPMenu alloc] init];
    [_mainMenu setSubmenu:_modulesMenu forItem:moduleItem];
    
    // help
    var helpMenu = [[CPMenu alloc] init];
    [helpMenu addItemWithTitle:@"Archipel Help" action:nil keyEquivalent:@""];
    [helpMenu addItemWithTitle:@"Release note" action:nil keyEquivalent:@""];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:@"Go to website" action:@selector(openWebsite:) keyEquivalent:@""];
    [helpMenu addItemWithTitle:@"Report a bug" action:@selector(openBugTracker:) keyEquivalent:@""];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:@"Make a donation" action:@selector(openDonationPage:) keyEquivalent:@""];
    [_mainMenu setSubmenu:helpMenu forItem:helpItem];
    
    [CPApp setMainMenu:_mainMenu];
    [CPMenu setMenuBarVisible:NO];
    
    CPLog.trace(@"Main menu created");
}

/*! delegate of TNModuleLoader sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleLoader)aLoader
{
    CPLog.info(@"All modules have been loaded");
    CPLog.trace(@"Positionning the connection window");
    
    [windowModuleLoading orderOut:nil];
    [connectionWindow center];
    [connectionWindow makeKeyAndOrderFront:nil];
    [connectionWindow initCredentials];
}

/*! delegate of TNModuleLoader sent when a module is loaded
*/
- (void)moduleLoader:(TNModuleLoader)aLoader hasLoadBundle:(CPBundle)aBundle
{
    CPLog.info(@"Bundle loaded : " + aBundle);
    [textFieldLoadedBundle setStringValue:@"Sucessfully loaded " + [aBundle objectForInfoDictionaryKey:@"CPBundleName"]];
}

- (IBAction)didMinusBouttonClicked:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item    = [_rosterOutlineView itemAtRow:index];
    
    if ([item class] == TNStropheContact)
        [self deleteContact:sender];
    else if ([item class] == TNStropheGroup)
        [self deleteGroup:sender];
}

- (IBAction)logout:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:@"TNArchipelBOSHJID"];
    [defaults removeObjectForKey:@"TNArchipelBOSHPassword"];
    [defaults setBool:NO forKey:@"TNArchipelBOSHRememberCredentials"];
    
    CPLog.info(@"starting to disconnect");
    [_mainRoster disconnect];
    
    [CPMenu setMenuBarVisible:NO];
}

- (IBAction)addContact:(id)sender
{
    [addContactWindow setRoster:_mainRoster];
    [addContactWindow makeKeyAndOrderFront:nil];
}

- (IBAction)deleteContact:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item    = [_rosterOutlineView itemAtRow:index];
    
    if ([item class] != TNStropheContact)
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"User supression" message:@"You must choose a contact" icon:TNGrowlIconError];
        return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Delet contact"
                                message:@"Are you sure you want to delete this contact?"
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteContact:)], ["Cancel", nil]]];
    [alert setUserInfo:item]
    [alert runModal];
}

- (void)performDeleteContact:(id)userInfo
{
    var growl   = [TNGrowlCenter defaultCenter];
    var contact = userInfo;
    
    [_mainRoster removeContactWithJID:[contact JID]];
    
    CPLog.info(@"contact " + [contact JID] + "removed");
    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + [contact JID] + @" has been removed"];
    
    [propertiesView hide];
    [_rosterOutlineView deselectAll];
    
    [self unregisterFromEventNodeOfJID:[contact JID] ofServer:@"pubsub." + [contact domain]];
}


- (IBAction)addGroup:(id)sender
{
    [addGroupWindow setRoster:_mainRoster];
    [addGroupWindow makeKeyAndOrderFront:nil];
}

- (IBAction)deleteGroup:(id)sender
{
    var growl       = [TNGrowlCenter defaultCenter];
    var index       = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item        = [_rosterOutlineView itemAtRow:index];
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    if ([item class] != TNStropheGroup)
    {
        [growl pushNotificationWithTitle:@"Group supression" message:@"You must choose a group" icon:TNGrowlIconError]; 
        return;
    }
    
    if ([[item contacts] count] != 0)
    {
        [growl pushNotificationWithTitle:@"Group supression" message:@"The group must be empty" icon:TNGrowlIconError];
        return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Delete group"
                                message:@"Are you sure you want to delete this group?"
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteGroup:)], ["Cancel", nil]]];
    [alert setUserInfo:item]
    [alert runModal];
}

- (void)performDeleteGroup:(id)userInfo
{
    var group   = userInfo;
    var key     = TNArchipelRememberOpenedGroup + [group name];
    
    [_mainRoster removeGroup:group];
    [_rosterOutlineView reloadData];
    [growl pushNotificationWithTitle:@"Group supression" message:@"The group has been removed"];
    
    [defaults removeObjectForKey:key];
    
    [propertiesView hide];
    [_rosterOutlineView deselectAll];
}

- (IBAction)selectNextEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var nextIndex       = (selectedIndex + 1) > [_rosterOutlineView numberOfRows] - 1 ? 0 : (selectedIndex + 1);
    
    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];
}

- (IBAction)selectPreviousEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var nextIndex       = (selectedIndex - 1) < 0 ? [_rosterOutlineView numberOfRows] -1 : (selectedIndex - 1);
    
    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];
    
}

- (IBAction)renameContact:(id)sender
{
    [[propertiesView entryName] mouseDown:nil];
}

- (IBAction)focusFilter:(id)sender
{
    [filterField mouseDown:nil];
}

- (IBAction)expandGroup:(id)sender
{
    var index       = [_rosterOutlineView selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item        = [_rosterOutlineView itemAtRow:[index firstIndex]];
    
    [_rosterOutlineView expandItem:item];
}

- (IBAction)collapseGroup:(id)sender
{
    var index = [_rosterOutlineView selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item = [_rosterOutlineView itemAtRow:[index firstIndex]];
    
    [_rosterOutlineView collapseItem:item];
}

- (IBAction)expandAllGroups:(id)sender
{
    [_rosterOutlineView expandAll];
}

- (IBAction)collapseAllGroups:(id)sender
{
    [_rosterOutlineView collapseAll];
}

- (IBAction)reloadContactVCard:(id)sender
{
    //
}

- (IBAction)openWebsite:(id)sender
{
    window.open("http://archipelproject.org");
}

- (IBAction)openDonationPage:(id)sender
{
    window.open("http://antoinemercadal.fr/archipelblog/donate/");
}

- (IBAction)openBugTracker:(id)sender
{
    window.open("http://bitbucket.org/primalmotion/archipel/issues/new");
}

- (IBAction)renameGroup:(id)sender
{
    [[propertiesView entryName] mouseDown:nil];
}

- (IBAction)switchMainMenu:(id)sender
{
    if ([CPMenu menuBarVisible])
        [CPMenu setMenuBarVisible:NO];
    else
        [CPMenu setMenuBarVisible:YES];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on logout item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemLogoutClick:(id)sender
{
    [self logout:sender];
}


/*! Delegate of toolbar imutables toolbar items.
    Trigger on add JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemAddContactClick:(id)sender
{
    [self addContact:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemDeleteContactClick:(id)sender
{
    [self deleteContact:sender]
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on add group item click
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemAddGroupClick:(id)sender
{
    [self addGroup:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete group item click
    NOT IMPLEMENTED
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemDeleteGroupClick:(id)sender
{
    [self deleteGroup:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete help item click.
    This will show a window conataining the helpView
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemHelpClick:(id)sender
{
    if (!_helpWindow)
    {
        _platformHelpWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(0,0,950,600)];
        
        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask|CPClosableWindowMask|CPMiniaturizableWindowMask|CPResizableWindowMask|CPBorderlessBridgeWindowMask];
        var scrollView  = [[CPScrollView alloc] initWithFrame:[[_helpWindow contentView] bounds]];
        
        [_helpWindow setPlatformWindow:_platformHelpWindow];
        [_platformHelpWindow orderFront:nil];
        
        [_helpWindow setDelegate:self];
        
        var bundle          = [CPBundle mainBundle];
        var defaults        = [TNUserDefaults standardUserDefaults];
        var newHelpView     = [[CPWebView alloc] initWithFrame:[[_helpWindow contentView] bounds]];
        var url             = [defaults objectForKey:@"TNArchipelHelpWindowURL"];
        var version         = [defaults objectForKey:@"TNArchipelVersion"];
        
        if (!url || (url == @"local"))
            url = @"help/index.html";
        
        [newHelpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];
        
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [scrollView setDocumentView:newHelpView];

        [_helpWindow setContentView:scrollView];
        [_helpWindow center];
        [_helpWindow makeKeyAndOrderFront:nil];
    }
    else
    {
        [_helpWindow close];
        _helpWindow = nil;
    }
}


/*! Delegate of toolbar imutables toolbar items.
    Trigger presence item change.
    This will change your own XMPP status
*/
- (IBAction)toolbarItemPresenceStatusClick:(id)sender
{
    var XMPPShow;
    var statusLabel = [sender title];
    
    switch (statusLabel)
    {
        case TNArchipelStatusAvailableLabel:
            XMPPShow = TNStropheContactStatusOnline
            break;
        case TNArchipelStatusAwayLabel:
            XMPPShow = TNStropheContactStatusAway
            break;
        case TNArchipelStatusBusyLabel:
            XMPPShow = TNStropheContactStatusBusy
            break;
        case TNArchipelStatusDNDLabel:
            XMPPShow = TNStropheContactStatusDND
            break;
    }
    
    var presence    = [TNStropheStanza presenceWithAttributes:{}];
    [presence addChildName:@"status"];
    [presence addTextNode:statusLabel];
    [presence up]
    [presence addChildName:@"show"];
    [presence addTextNode:XMPPShow];
    CPLog.info(@"Changing presence to " + statusLabel + ":" + XMPPShow);
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Status" message:@"Your status is now " + statusLabel];
    
    [[_mainRoster connection] send:presence];
}

/*! Delegate for CPWindow.
    Tipically set _helpWindow to nil on closes.
*/
- (void)windowWillClose:(CPWindow)aWindow
{
    if (aWindow == _helpWindow)
    {
        _helpWindow = nil;
    }
}

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [connectionWindow orderOut:nil];
    [theWindow makeKeyAndOrderFront:nil];

    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification object]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:filterField];
    [propertiesView setRoster:_mainRoster];
    
    
    [_mainRoster getRoster];
    
    [CPMenu setMenuBarVisible:YES];
    
    [_moduleLoader setRosterForToolbarItems:_mainRoster andConnection:[aNotification object]];
    
    var user = [[_mainRoster connection] JID];
    
    [[_mainRoster connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
    [[_mainRoster connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Welcome" message:@"Welcome back " + user];
}

- (void)stropheConnectionRawIn:(TNStropheStanza)aStanza
{
    [ledIn setImage:_imageLedInData];
    
    if (_ledInTimer)
        [_ledInTimer invalidate];
    
    _ledInTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledIn repeats:NO];
}

- (void)stropheConnectionRawOut:(TNStropheStanza)aStanza
{
    [ledOut setImage:_imageLedOutData];
    
    if (_ledOutTimer)
        [_ledOutTimer invalidate];
    _ledOutTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledOut repeats:NO];
}

- (void)timeOutDataLed:(CPTimer)aTimer
{
    [[aTimer userInfo] setImage:_imageLedNoData];
}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [theWindow orderOut:nil];
    [connectionWindow makeKeyAndOrderFront:nil];
}

/*! Notification responder for CPApplicationWillTerminateNotification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [_mainRoster disconnect];
}


/*! Delegate method of main TNStropheRoster.
    will be performed when a subscription request is sent
    @param requestStanza TNStropheStanza cotainining the subscription request
*/
- (void)didReceiveSubscriptionRequest:(id)requestStanza
{
    var nick;
    
    if ([requestStanza firstChildWithName:@"nick"])
        nick = [[requestStanza firstChildWithName:@"nick"] text];
    else
        nick = [requestStanza from];
    
    var alert = [TNAlert alertWithTitle:@"Subscription request"
                                message:nick + " is asking you subscription. Do you want to add it ?"
                                delegate:self
                                 actions:[["Accept", @selector(performSubscribe:)], 
                                            ["Decline", @selector(performUnsubscribe:)]]];

    [alert setUserInfo:requestStanza]
    [alert runModal];
}

- (void)performSubscribe:(id)userInfo
{
    var bundle  = [CPBundle mainBundle];
    var stanza  = userInfo;
    [_mainRoster answerAuthorizationRequest:stanza answer:YES];
    
    // evenually subscribe to event node of the entity
    [self registerToEventNodeOfJID:[stanza from] ofServer:@"pubsub." + [stanza fromDomain]];
}

- (void)registerToEventNodeOfJID:(CPString)aJID ofServer:(CPString)aServer
{
    var pubSubServer        = aServer;
    var uid                 = [[_mainRoster connection] getUniqueId];
    var nodeSubscribeStanza = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
    
    [nodeSubscribeStanza setTo:pubSubServer];
    [nodeSubscribeStanza addChildName:@"pubsub" withAttributes:{"xmlns": "http://jabber.org/protocol/pubsub"}];
    [nodeSubscribeStanza addChildName:@"subscribe" withAttributes:{
        "node": "/archipel/" + aJID.split("/")[0] + "/events",
        "jid": [[_mainRoster connection] JID],
    }];
    
    var params = [[CPDictionary alloc] init];
    [params setValue:uid forKey:@"id"];
    
    [[_mainRoster connection] registerSelector:@selector(didPubSubSubscribe:) ofObject:self withDict:params]
    [[_mainRoster connection] send:nodeSubscribeStanza];
    
}

- (void)didPubSubSubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Sucessfully subscribed to pubsub event node of " + [aStanza from]);
    }
    else
    {
        CPLog.error("unable to subscribe to pubsub");
    }
    
    return NO;
}

- (BOOL)performUnsubscribe:(id)userInfo
{
    var stanza = userInfo;
    [_mainRoster answerAuthorizationRequest:stanza answer:NO];
    
    // evenually unsubscribe to event node of the entity
   [self unregisterFromEventNodeOfJID:[stanza from] ofServer:@"pubsub." + [stanza fromDomain]];
}

- (void)unregisterFromEventNodeOfJID:(CPString)aJID ofServer:(CPString)aServer
{
    var pubSubServer            = aServer;
    var uid                     = [[_mainRoster connection] getUniqueId];
    var nodeUnsubscribeStanza   = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];

    [nodeUnsubscribeStanza setTo:pubSubServer];
    [nodeUnsubscribeStanza addChildName:@"pubsub" withAttributes:{"xmlns": "http://jabber.org/protocol/pubsub"}];
    [nodeUnsubscribeStanza addChildName:@"unsubscribe" withAttributes:{
        "node": "/archipel/" + aJID.split("/")[0] + "/events",
        "jid": [[_mainRoster connection] JID],
    }];

    var params = [[CPDictionary alloc] init];
    [params setValue:uid forKey:@"id"];

    [[_mainRoster connection] registerSelector:@selector(didPubSubUnsubscribe:) ofObject:self withDict:params]
    [[_mainRoster connection] send:nodeUnsubscribeStanza];    
}

- (BOOL)didPubSubUnsubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Sucessfully unsubscribed from pubsub event node of " + [aStanza from]);
    }
    else
    {
        CPLog.error("unable to unsubscribe to pubsub");
    }
    
    return NO;
}



/*! Display the helpView in the rightView
*/
- (void)showHelpView
{
    if (![helpView mainFrameURL])
    {
        var bundle      = [CPBundle mainBundle];
        var defaults    = [TNUserDefaults standardUserDefaults];
        var url         = [defaults objectForKey:@"TNArchipelHelpWindowURL"];
        var version     = [defaults objectForKey:@"TNArchipelVersion"];
        
        if (!url || (url == @"local"))
            url = @"help/index.html";
        
        [helpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];
    }
    
    
    [helpView setFrame:[rightView bounds]];
    [rightView addSubview:helpView];
    
    var animView    = [CPDictionary dictionaryWithObjectsAndKeys:helpView, CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];
    
    [anim setDuration:0.3];
    // [anim startAnimation];
}

/*! Hide the helpView from the rightView
*/
- (void)hideHelpView
{
    [helpView removeFromSuperview];
}

/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying
    if managed by this message
    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var index       = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item        = [_rosterOutlineView itemAtRow:index];
    var loadDelay   = [defaults objectForKey:@"TNArchipelModuleLoadingDelay"];
    
    if (_moduleLoadingDelay)
        [_moduleLoadingDelay invalidate];
    
    [viewLoadingModule setFrame:[rightView bounds]];
    
    [propertiesView setEntity:item];
    [propertiesView reload];
    
    _moduleLoadingDelay = [CPTimer scheduledTimerWithTimeInterval:loadDelay target:self selector:@selector(performModuleChange:) userInfo:item repeats:NO];
}

- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"];
    var defaults    = [TNUserDefaults standardUserDefaults];
    var key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"expanded" forKey:key];
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"];
    var defaults    = [TNUserDefaults standardUserDefaults];
    var key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"collapsed" forKey:key];
    
    return YES;
}



- (void)performModuleChange:(CPTimer)aTimer
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
    {
        [self showHelpView];
        [_mainRoster setCurrentItem:nil];
        [propertiesView hide];
        return;
    }
    
    var item        = [aTimer userInfo];
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    // if (item == [_moduleLoader entity])
    //     return;
    
    [_mainRoster setCurrentItem:item];
    
    [self hideHelpView];
    
    if ([item class] == TNStropheGroup)
    {
        CPLog.info(@"setting the entity as " + item + " of type group");
        [_moduleLoader setEntity:item ofType:@"group" andRoster:_mainRoster];
        return;
    }
    else if ([item class] == TNStropheContact)
    {
        var vCard       = [item vCard];
        var entityType  = [_moduleLoader analyseVCard:vCard];

        CPLog.info(@"setting the entity as " + item + " of type " + entityType);
        [_moduleLoader setEntity:item ofType:entityType andRoster:_mainRoster];
        
    }
}


/*! Delegate of mainSplitView
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var splitView   = [aNotification object];
    var newWidth    = [splitView rectOfDividerAtIndex:0].origin.x;
    
    CPLog.info(@"setting the mainSplitViewPosition value in defaults");
    [defaults setInteger:newWidth forKey:@"mainSplitViewPosition"];
}


- (void)allModuleReady:(CPNotification)aNotification
{
    if ([viewLoadingModule superview])
        [viewLoadingModule removeFromSuperview];
}


- (@action)showAboutWindow:(id)sender
{
    [windowAboutArchipel makeKeyAndOrderFront:sender];
}

- (void)copyright
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    var copy = document.createElement("div");
    copy.style.position = "absolute";
    copy.style.fontSize = "10px";
    copy.style.color = "#5a5a5a";
    copy.style.width = "700px";
    copy.style.bottom = "8px";
    copy.style.left = "50%";
    copy.style.textAlign = "center";
    copy.style.marginLeft = "-350px";
    copy.style.textShadow = "0px 1px 0px white";
    copy.innerHTML =  [defaults objectForKey:@"TNArchipelVersion"] + @" - " + [defaults objectForKey:@"TNArchipelCopyright"];
    document.body.appendChild(copy);
    
}
@end
