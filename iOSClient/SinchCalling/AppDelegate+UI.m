#import "AppDelegate+UI.h"

@implementation AppDelegate (UIAdjustments)

- (void)addSplashView {
  UIImageView *splash = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
  splash.image = [UIImage imageNamed:@"Default"];
  splash.tag = 4321;
  splash.alpha = 1.0;
  [self.window addSubview:splash];
}

- (void)dismissSplashViewIfNecessary {
  UIView *splash = [self.window viewWithTag:4321];
  if (!splash) {
    return;
  }
  [self.window bringSubviewToFront:splash];
  [UIView animateWithDuration:0.4
      delay:0
      options:UIViewAnimationOptionTransitionNone
      animations:^{ splash.alpha = 0.0; }
      completion:^(BOOL finished) { [splash removeFromSuperview]; }];
}

@end
