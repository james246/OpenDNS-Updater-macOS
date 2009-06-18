// Copyright (c) 2009 OpenDNS, LLC. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppController.h"
#import "SBJSON.h"
#import "GDataHTTPFetcher.h"

#include <netdb.h>

#define ONE_MINUTE_INTERVAL 60.0

@interface AppController (Private)
- (NSString *)getMyIp;
- (void)ipAddressChanged:(NSString *)newIpAddress;
- (void)ipChangeThread;
- (void)setButtonLoginStatus;
- (BOOL)isButtonLoginEnabled;
- (BOOL)shouldSendPeriodicUpdate;
- (void)sendPeriodicUpdate;
@end

static BOOL NSStringsEqual(NSString *s1, NSString *s2) {
	if (!s1 && !s2)
		return YES;
	if (!s1 || !s2)
		return NO;
	return [s1 isEqualToString:s2];
}

@implementation AppController

- (NSString *)getMyIp {
	char **addrs;
	struct hostent *he = gethostbyname("myip.opendns.com");
	// TODO: notify the user that we don't support ipv6?
	if (AF_INET != he->h_addrtype)
		return nil;
	if (4 != he->h_length)
		return nil;
	addrs = he->h_addr_list;
	while (*addrs) {
		unsigned char *a = (unsigned char*)*addrs++;
		// TODO: could by more efficient by comparing old vs. new as bytes
		// and only creating NSString when are different
		NSString *addrTxt = [NSString stringWithFormat:@"%d.%d.%d.%d", a[0], a[1], a[2], a[3]];
		return [addrTxt autorelease];
	}
	return nil;
}

- (void)ipAddressChanged:(NSString *)newIpAddress {
	[currentIpAddress_ release];
	currentIpAddress_ = [newIpAddress copy];
}

- (BOOL)shouldSendPeriodicUpdate {
	return NO;
}

- (void)sendPeriodicUpdate {
	
}

- (void)ipChangeThread {
	NSAutoreleasePool* myAutoreleasePool = [[NSAutoreleasePool alloc] init];
	NSString *currIp = nil;

	while (!exitIpChangeThread_) {
		NSString *newIp = [self getMyIp];
		if (!NSStringsEqual(newIp, currIp)) {
			[currIp release];
			currIp = [newIp copy];
			[self performSelectorOnMainThread:@selector(ipAddressChanged:) withObject:currIp waitUntilDone:NO];
		}

		if ([self shouldSendPeriodicUpdate]) {
			[self sendPeriodicUpdate];
		}

		[NSThread sleepForTimeInterval:ONE_MINUTE_INTERVAL];
	}
	[currIp release];
	[myAutoreleasePool release];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	[NSThread detachNewThreadSelector:@selector(ipChangeThread)
							 toTarget:(id)self
						   withObject:(id)nil];
}

- (void)awakeFromNib {
	statusItem_ = [[[NSStatusBar systemStatusBar] 
				   statusItemWithLength:NSSquareStatusItemLength]
				  retain];
	[statusItem_ setHighlightMode:YES];
	[statusItem_ setEnabled:YES];
	[statusItem_ setToolTip:@"OpenDNS Updater"];
	[statusItem_ setMenu:menu_]; 
	NSBundle *bundle = [NSBundle bundleForClass:[self class]]; 
	NSString *path = [bundle pathForResource:@"menuicon" ofType:@"tif"]; 
	menuIcon_= [[NSImage alloc] initWithContentsOfFile:path]; 
	[statusItem_ setImage:menuIcon_]; 
	[menuIcon_ release]; 

	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];

	NSString *account = [prefs objectForKey: @"account"];
	NSString *token = [prefs objectForKey: @"token"];
	if (!account || !token) {
		[NSApp activateIgnoringOtherApps:YES];
		[windowLogin_ makeKeyAndOrderFront:self];
	}
	[self setButtonLoginStatus];
	
	exitIpChangeThread_ = NO;
}

- (void)dealloc {
	[statusItem_ release];
	[super dealloc];
}

- (BOOL)isButtonLoginEnabled {
	NSString *account = [editOpenDnsAccount_ stringValue];
	NSString *password = [editOpenDnsPassword_ stringValue];
	if (!account || (0 == [account length]))
		return NO;
	if (!password || (0 == [password length]))
		return NO;
	return YES;
}

- (void)setButtonLoginStatus {
	[buttonLogin_ setEnabled:[self isButtonLoginEnabled]];
}

- (void)controlTextDidChange:(NSNotification*)aNotification {
	[self setButtonLoginStatus];
}

- (void)myFetcher:(GDataHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData
{
	[progressLogin_ stopAnimation: nil];
}

- (void)myFetcher:(GDataHTTPFetcher *)fetcher failedWithError:(NSError *)error
{
	[progressLogin_ stopAnimation: nil];
}

- (IBAction)login:(id)sender {
	if (![self isButtonLoginEnabled])
		return;
	[buttonLogin_ setEnabled: NO];
	[progressLogin_ setHidden: NO];
	[progressLogin_ startAnimation: nil];
	[textLoginProgress_ setHidden: NO];
	NSString *urlString = @"http://google.com/";
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	GDataHTTPFetcher* fetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
	[fetcher beginFetchWithDelegate:self
	               didFinishSelector:@selector(myFetcher:finishedWithData:)
	                 didFailSelector:@selector(myFetcher:failedWithError:)];
}

- (void)applicationWillTerminate:(NSNotification*)aNotification {
	exitIpChangeThread_ = YES;
}

- (IBAction)preferences:(id)sender {
	// TODO: implement me
}
@end
