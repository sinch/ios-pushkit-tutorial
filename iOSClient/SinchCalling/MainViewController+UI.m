#import "MainViewController.h"

// This category for the MainViewController serves only to separate code that
// is directly related to the usage of the Sinch SDK, from code that is used
// for improving the look and feel of the sample app.

// Nothing magic here, just regular code interacting with the iOS SDK.

@interface MainViewController (UIAdjustments) <UITextFieldDelegate>

@end

@implementation MainViewController (UIAdjustments)

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.destination becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([[textField text] length] > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{ [self call:textField]; });
  }
  return YES;
}

@end