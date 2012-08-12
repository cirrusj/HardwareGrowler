#import "AppController.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include "FireWireNotifier.h"
#include "USBNotifier.h"
#include "BluetoothNotifier.h"
#include "VolumeNotifier.h"
#include "NetworkNotifier.h"
#include "SyncNotifier.h"
#include "PowerNotifier.h"

#define NotifierUSBConnectionNotification				@"USB Device Connected"
#define NotifierUSBDisconnectionNotification			@"USB Device Disconnected"
#define NotifierVolumeMountedNotification				@"Volume Mounted"
#define NotifierVolumeUnmountedNotification				@"Volume Unmounted"
#define NotifierBluetoothConnectionNotification			@"Bluetooth Device Connected"
#define NotifierBluetoothDisconnectionNotification		@"Bluetooth Device Disconnected"
#define NotifierFireWireConnectionNotification			@"FireWire Device Connected"
#define NotifierFireWireDisconnectionNotification		@"FireWire Device Disconnected"
#define NotifierNetworkLinkUpNotification				@"Network Link Up"
#define NotifierNetworkLinkDownNotification				@"Network Link Down"
#define NotifierNetworkIpAcquiredNotification			@"IP Acquired"
#define NotifierNetworkIpReleasedNotification			@"IP Released"
#define NotifierNetworkAirportConnectNotification		@"AirPort Connected"
#define NotifierNetworkAirportDisconnectNotification	@"AirPort Disconnected"
#define NotifierSyncStartedNotification					@"Sync started"
#define NotifierSyncFinishedNotification				@"Sync finished"
#define NotifierPowerOnACNotification					@"Switched to A/C Power"
#define NotifierPowerOnBatteryNotification				@"Switched to Battery Power"
#define NotifierPowerOnUPSNotification					@"Switched to UPS Power"

#define NotifierUSBConnectionHumanReadableDescription				NSLocalizedString(@"USB Device Connected", "")
#define NotifierUSBDisconnectionHumanReadableDescription			NSLocalizedString(@"USB Device Disconnected", "")
#define NotifierVolumeMountedHumanReadableDescription				NSLocalizedString(@"Volume Mounted", "")
#define NotifierVolumeUnmountedHumanReadableDescription				NSLocalizedString(@"Volume Unmounted", "")
#define NotifierBluetoothConnectionHumanReadableDescription			NSLocalizedString(@"Bluetooth Device Connected", "")
#define NotifierBluetoothDisconnectionHumanReadableDescription		NSLocalizedString(@"Bluetooth Device Disconnected", "")
#define NotifierFireWireConnectionHumanReadableDescription			NSLocalizedString(@"FireWire Device Connected", "")
#define NotifierFireWireDisconnectionHumanReadableDescription		NSLocalizedString(@"FireWire Device Disconnected", "")
#define NotifierNetworkLinkUpHumanReadableDescription				NSLocalizedString(@"Network Link Up", "")
#define NotifierNetworkLinkDownHumanReadableDescription				NSLocalizedString(@"Network Link Down", "")
#define NotifierNetworkIpAcquiredHumanReadableDescription			NSLocalizedString(@"IP Acquired", "")
#define NotifierNetworkIpReleasedHumanReadableDescription			NSLocalizedString(@"IP Released", "")
#define NotifierNetworkAirportConnectHumanReadableDescription		NSLocalizedString(@"AirPort Connected", "")
#define NotifierNetworkAirportDisconnectHumanReadableDescription	NSLocalizedString(@"AirPort Disconnected", "")
#define NotifierSyncStartedHumanReadableDescription					NSLocalizedString(@"Sync started", "")
#define NotifierSyncFinishedHumanReadableDescription				NSLocalizedString(@"Sync finished", "")
#define NotifierPowerOnACHumanReadableDescription					NSLocalizedString(@"Switched to A/C Power", "")
#define NotifierPowerOnBatteryHumanReadableDescription				NSLocalizedString(@"Switched to Battery Power", "")
#define NotifierPowerOnUPSHumanReadableDescription					NSLocalizedString(@"Switched to UPS Power", "")


#define NotifierFireWireConnectionTitle()				CFCopyLocalizedString(CFSTR("FireWire Connection"), "")
#define NotifierFireWireDisconnectionTitle()			CFCopyLocalizedString(CFSTR("FireWire Disconnection"), "")
#define NotifierUSBConnectionTitle()					CFCopyLocalizedString(CFSTR("USB Connection"), "")
#define NotifierUSBDisconnectionTitle()					CFCopyLocalizedString(CFSTR("USB Disconnection"), "")
#define NotifierBluetoothConnectionTitle()				CFCopyLocalizedString(CFSTR("Bluetooth Connection"), "")
#define NotifierBluetoothDisconnectionTitle()			CFCopyLocalizedString(CFSTR("Bluetooth Disconnection"), "")
#define NotifierVolumeMountedTitle()					CFCopyLocalizedString(CFSTR("Volume Mounted"), "")
#define NotifierVolumeUnmountedTitle()					CFCopyLocalizedString(CFSTR("Volume Unmounted"), "")
#define NotifierNetworkAirportConnectTitle()			CFCopyLocalizedString(CFSTR("Airport connected"), "")
#define NotifierNetworkAirportDisconnectTitle()			CFCopyLocalizedString(CFSTR("Airport disconnected"), "")
#define NotifierNetworkLinkUpTitle()					CFCopyLocalizedString(CFSTR("Ethernet activated"), "")
#define NotifierNetworkLinkDownTitle()					CFCopyLocalizedString(CFSTR("Ethernet deactivated"), "")
#define NotifierNetworkIpAcquiredTitle()				CFCopyLocalizedString(CFSTR("IP address acquired"), "")
#define NotifierNetworkIpReleasedTitle()				CFCopyLocalizedString(CFSTR("IP address released"), "")
#define NotifierSyncStartedTitle()						CFCopyLocalizedString(CFSTR("Sync started"), "")
#define NotifierSyncFinishedTitle()						CFCopyLocalizedString(CFSTR("Sync finished"), "")

#define NotifierNetworkAirportDisconnectDescription()	CFCopyLocalizedString(CFSTR("Left network %@."), "")
#define NotifierNetworkIpAcquiredDescription()			CFCopyLocalizedString(CFSTR("New primary IP: %@ (%@)"), "")
#define NotifierNetworkIpReleasedDescription()			CFCopyLocalizedString(CFSTR("No IP address now"), "")

static io_connect_t			powerConnection;
static io_object_t			powerNotifier;
static CFRunLoopSourceRef	powerRunLoopSource;
static BOOL					sleeping;

#ifdef __OBJC__
#	define DATA_TYPE				NSData *
#	define DATE_TYPE				NSDate *
#	define DICTIONARY_TYPE			NSDictionary *
#	define MUTABLE_DICTIONARY_TYPE	NSMutableDictionary *
#	define STRING_TYPE				NSString *
#	define ARRAY_TYPE				NSArray *
#	define URL_TYPE					NSURL *
#	define PLIST_TYPE				NSObject *
#	define OBJECT_TYPE				id
#	define BOOL_TYPE				BOOL
#else
#	include <CoreFoundation/CoreFoundation.h>
#	define DATA_TYPE				CFDataRef
#	define DATE_TYPE				CFDateRef
#	define DICTIONARY_TYPE			CFDictionaryRef
#	define MUTABLE_DICTIONARY_TYPE	CFMutableDictionaryRef
#	define STRING_TYPE				CFStringRef
#	define ARRAY_TYPE				CFArrayRef
#	define URL_TYPE					CFURLRef
#	define PLIST_TYPE				CFPropertyListRef
#	define OBJECT_TYPE				CFTypeRef
#	define BOOL_TYPE				Boolean
#endif

NSUserNotificationCenter *center;


static void sendNotification(NSString *title, NSString *text) {
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:title];
    [notification setInformativeText:text];
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    [notification setSoundName:NSUserNotificationDefaultSoundName];
    [notification setHasActionButton:false];
    [center scheduleNotification:notification];
    [notification release];
}

#pragma mark Firewire

void AppController_fwDidConnect(CFStringRef deviceName) {
	NSLog(@"FireWire Connect: %@", deviceName);
	CFStringRef title = NotifierFireWireConnectionTitle();
    sendNotification((NSString *)title, (NSString *)deviceName);
   	CFRelease(title);
}

void AppController_fwDidDisconnect(CFStringRef deviceName) {
	NSLog(@"FireWire Disconnect: %@", deviceName);
	CFStringRef title = NotifierFireWireDisconnectionTitle();
    sendNotification((NSString *)title, (NSString *)deviceName);
	CFRelease(title);
}

#pragma mark USB

void AppController_usbDidConnect(CFStringRef deviceName) {
	NSLog(@"USB Connect: %@", deviceName);
	CFStringRef title = NotifierUSBConnectionTitle();
    sendNotification((NSString *)title, (NSString *)deviceName);
	CFRelease(title);
}

void AppController_usbDidDisconnect(CFStringRef deviceName) {
	NSLog(@"USB Disconnect: %@", deviceName);
	CFStringRef title = NotifierUSBDisconnectionTitle();
    sendNotification((NSString *)title, (NSString *)deviceName);
	CFRelease(title);
}

#pragma mark Bluetooth

void AppController_bluetoothDidConnect(CFStringRef device) {
	NSLog(@"Bluetooth Connect: %@", device);
	CFStringRef title = NotifierBluetoothConnectionTitle();
    sendNotification((NSString *)title, (NSString *)device);
	CFRelease(title);
}

void AppController_bluetoothDidDisconnect(CFStringRef device) {
	NSLog(@"Bluetooth Disconnect: %@", device);
	CFStringRef title = NotifierBluetoothDisconnectionTitle();
    sendNotification((NSString *)title, (NSString *)device);
	CFRelease(title);
}

#pragma mark Volumes

void AppController_volumeDidMount(VolumeInfo *info) {
	NSLog(@"volume Mount: %@", info);
	CFStringRef title = NotifierVolumeMountedTitle();
	NSDictionary *context = nil;
	
	if ([info path]) {
		context = [NSDictionary dictionaryWithObjectsAndKeys:
								(NSString *)NotifierVolumeMountedNotification, @"notification",
								[info path], @"path",
								nil];
	}
    sendNotification((NSString *)title, (NSString *)[info name]);
	CFRelease(title);
}

void AppController_volumeDidUnmount(VolumeInfo *info) {
	NSLog(@"volume Unmount: %@", info);
	CFStringRef title = NotifierVolumeUnmountedTitle();
    sendNotification((NSString *)title, (NSString *)[info name]);
	CFRelease(title);
}

#pragma mark Network

void AppController_airportConnect(CFStringRef networkName, const unsigned char *bssidBytes) {


	if (sleeping)
		return;

	CFStringRef title = NotifierNetworkAirportConnectTitle();
	
	NSString *bssid = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
					   bssidBytes[0],
					   bssidBytes[1],
					   bssidBytes[2],
					   bssidBytes[3],
					   bssidBytes[4],
					   bssidBytes[5]];
	NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Joined network.\nSSID:\t\t%@\nBSSID:\t%@", ""),
							 networkName,
							 bssid];
    NSLog(@"AirPort connect: %@", description);
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
}

void AppController_airportDisconnect(CFStringRef networkName) {
	if (sleeping)
		return;
	CFStringRef title = NotifierNetworkAirportDisconnectTitle();
	CFStringRef format = NotifierNetworkAirportDisconnectDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   networkName);
    NSLog(@"AirPort disconnect: %@", description);
	CFRelease(format);
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
	CFRelease(description);
}

void AppController_linkUp(CFStringRef description) {
	NSLog(@"Link up: %@", description);
	if (sleeping)
		return;
	CFStringRef title = NotifierNetworkLinkUpTitle();
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
}

void AppController_linkDown(CFStringRef description) {
	NSLog(@"Link down: %@", description);
	if (sleeping)
		return;
	CFStringRef title = NotifierNetworkLinkDownTitle();
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
}

void AppController_ipAcquired(CFStringRef ip, CFStringRef type) {
	NSLog(@"IP acquired: %@", ip);
	if (sleeping)
		return;
	CFStringRef title = NotifierNetworkIpAcquiredTitle();
	CFStringRef format = NotifierNetworkIpAcquiredDescription();
	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault,
													   NULL,
													   format,
													   ip,
													   type);
	CFRelease(format);
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
	CFRelease(description);
}

void AppController_ipReleased(void) {
	NSLog(@"IP released");
	if (sleeping)
		return;
	CFStringRef title = NotifierNetworkIpReleasedTitle();
	CFStringRef description = NotifierNetworkIpReleasedDescription();
    sendNotification((NSString *)title, (NSString *)description);
	CFRelease(title);
	CFRelease(description);
}

#pragma mark Sync

void AppController_syncStarted(void) {
	NSLog(@"Sync started");
	CFStringRef title = NotifierSyncStartedTitle();
    sendNotification((NSString *)title, (NSString *)title);
	CFRelease(title);
}

void AppController_syncFinished(void) {
	NSLog(@"Sync finished");
	CFStringRef title = NotifierSyncFinishedTitle();
    sendNotification((NSString *)title, (NSString *)title);
	CFRelease(title);
}

#pragma mark Power
void AppController_powerSwitched(HGPowerSource powerSource, CFBooleanRef isCharging,
								 CFIndex batteryTime, CFIndex batteryPercentage)
{
	NSString		*title = nil;
	NSMutableString *description = [NSMutableString string];
	NSString		*notificationName = nil;
	BOOL		haveBatteryTime = (batteryTime != -1);
	BOOL		haveBatteryPercentage = (batteryPercentage != -1);
	if (powerSource == HGACPower) {
		title = NSLocalizedString(@"On A/C power", nil);
		if (isCharging == kCFBooleanTrue) {
			[description appendString:NSLocalizedString(@"Battery charging...", nil)];
			if (haveBatteryTime || haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time to charge: %i minutes", nil), batteryTime];
			if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
			if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
		} else {
			
		}

		notificationName = (NSString *)NotifierPowerOnACNotification;

	} else if (powerSource == HGBatteryPower) {
		title = NSLocalizedString(@"On battery power", nil);
		if (haveBatteryTime) [description appendFormat:NSLocalizedString(@"Time remaining: %i minutes", nil), batteryTime];
		if (haveBatteryTime && haveBatteryPercentage) [description appendString:@"\n"];
		if (haveBatteryPercentage) [description appendFormat:NSLocalizedString(@"Current charge: %d%%", nil), batteryPercentage];
		notificationName = (NSString *)NotifierPowerOnBatteryNotification;
	} else if (powerSource == HGUPSPower) {
		title = NSLocalizedString(@"On UPS power", nil);
		notificationName = (NSString *)NotifierPowerOnUPSNotification;
	}
	if (notificationName) {
        sendNotification((NSString *)title, (NSString *)description);
    }
}

static void powerCallback(void *refcon, io_service_t service, natural_t messageType, void *messageArgument) {
#pragma unused(refcon,service)
	switch (messageType) {
		case kIOMessageSystemWillRestart:
		case kIOMessageSystemWillPowerOff:
		case kIOMessageSystemWillSleep:
		case kIOMessageDeviceWillPowerOff:
			sleeping = YES;
			IOAllowPowerChange(powerConnection, (long)messageArgument);
			break;
		case kIOMessageCanSystemPowerOff:
		case kIOMessageCanSystemSleep:
		case kIOMessageCanDevicePowerOff:
			IOAllowPowerChange(powerConnection, (long)messageArgument);
			break;
		case kIOMessageSystemWillNotSleep:
		case kIOMessageSystemWillNotPowerOff:
		case kIOMessageSystemHasPoweredOn:
		case kIOMessageDeviceWillNotPowerOff:
		case kIOMessageDeviceHasPoweredOn:
			sleeping = NO;
		default:
			break;
	}
}

@implementation AppController

- (void) userNotificationCenter: (NSUserNotificationCenter *) center didActivateNotification: (NSUserNotification *) notification
{
    NSLog(@"Notficiation clicked");
    CFStringRef title = (CFStringRef)notification.title;
    CFStringRef informativeText = (CFStringRef)notification.informativeText;
    [center removeDeliveredNotification:notification];
    CFOptionFlags options = kCFUserNotificationNoteAlertLevel;
    CFOptionFlags responseFlags = 0;
    CFUserNotificationDisplayAlert(0, options, NULL, NULL, NULL,
                                   title,
                                   informativeText, NULL,
                                   NULL,NULL, &responseFlags);
}

- (void) awakeFromNib {
    NSLog(@"Starting...");
    center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    sendNotification(@"HardwareGrowler", @"Starting...");
    // Register for sleep and wake notifications so we can suppress various notifications during sleep
	IONotificationPortRef ioNotificationPort;
	powerConnection = IORegisterForSystemPower(NULL, &ioNotificationPort, powerCallback, &powerNotifier);
	if (powerConnection) {
		powerRunLoopSource = IONotificationPortGetRunLoopSource(ioNotificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), powerRunLoopSource, kCFRunLoopDefaultMode);
	}
	FireWireNotifier_init();
	USBNotifier_init();
	VolumeNotifier_init();
	SyncNotifier_init();
	BluetoothNotifier_init();
	networkNotifier = [[NetworkNotifier alloc] init];
	PowerNotifier_init();

}

- (void) dealloc {
	FireWireNotifier_dealloc();
	USBNotifier_dealloc();
	VolumeNotifier_dealloc();
	SyncNotifier_dealloc();
	BluetoothNotifier_dealloc();
	[networkNotifier release];
	if (powerConnection) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), powerRunLoopSource, kCFRunLoopDefaultMode);
		IODeregisterForSystemPower(&powerNotifier);
	}
	[super dealloc];
}

- (IBAction) doSimpleHelp:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"txt"]];
}

@end
