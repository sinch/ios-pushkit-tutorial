#import "SINUIViewController.h"

#import <objc/runtime.h>

// used for associated object references to simulate property-like storage for
// this category
static char sin_deferredDismissalKey;

@implementation SINUIViewController

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if ([self.view window] == nil) {
    _isAppearing = NO;
    _isDisappearing = NO;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  _isAppearing = YES;
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  _isAppearing = NO;
  [self dismissIfNecessary];
}

- (void)viewWillDisappear:(BOOL)animated {
  _isDisappearing = YES;
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  _isAppearing = NO;
}

#pragma mark - Dismissal

- (void)dismiss {
  if ([self isDisappearing]) {
    return;
  } else if ([self isAppearing]) {
    [self setShouldDeferredDismiss:YES];
    return;
  }
  [self dismissViewControllerAnimated:YES completion:NO];
}

- (void)dismissIfNecessary {
  if ([self shouldDeferrDismiss]) {
    [self setShouldDeferredDismiss:NO];
    dispatch_async(dispatch_get_main_queue(), ^{ [self dismiss]; });
  }
}

- (BOOL)shouldDeferrDismiss {
  return [self sin_getAssociatedBOOLForKey:&sin_deferredDismissalKey];
}

- (void)setShouldDeferredDismiss:(BOOL)v {
  [self sin_setAssociatedBOOL:v forKey:&sin_deferredDismissalKey];
}

#pragma mark -

- (BOOL)sin_getAssociatedBOOLForKey:(const void *)key {
  NSNumber *v = (NSNumber *)objc_getAssociatedObject(self, key);
  return v ? [v boolValue] : NO;
}

- (void)sin_setAssociatedBOOL:(BOOL)v forKey:(const void *)key {
  objc_setAssociatedObject(self, key, [NSNumber numberWithBool:v], OBJC_ASSOCIATION_COPY);
}

@end
