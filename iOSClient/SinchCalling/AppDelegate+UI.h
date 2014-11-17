#import "AppDelegate.h"

// This category for the AppDelegate serves only to separate code that
// is directly related to the usage of the Sinch SDK, from code that is used
// for improving the look and feel of the sample app.

// Nothing magic here, just regular code interacting with the iOS SDK.

@interface AppDelegate (UIAdjustments)

- (void)addSplashView;
- (void)dismissSplashViewIfNecessary;

@end
