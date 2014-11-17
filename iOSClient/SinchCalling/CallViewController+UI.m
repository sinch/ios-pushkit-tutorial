// This category for the CallViewController serves only to separate code that
// is directly related to the usage of the Sinch SDK, from code that is used
// for improving the look and feel of the sample app.

// Nothing magic here, just regular code interacting with the iOS SDK.

// Includes helper methods for updating UI elements such as labels and buttons.
// Includes helper functionality around dealing with modal presentation of the
// call view.

#import "CallViewController+UI.h"

@implementation CallViewController (UIAdjustments)

- (void)setCallStatusText:(NSString *)text {
  self.callStateLabel.text = text;
}

#pragma mark - Buttons

- (void)showButtons:(EButtonsBar)buttons {
  if (buttons == kButtonsAnswerDecline) {
    self.answerButton.hidden = NO;
    self.declineButton.hidden = NO;
    self.endCallButton.hidden = YES;
  } else if (buttons == kButtonsHangup) {
    self.endCallButton.hidden = NO;
    self.answerButton.hidden = YES;
    self.declineButton.hidden = YES;
  }
}

#pragma mark - Duration

- (void)setDuration:(NSInteger)seconds {
  [self setCallStatusText:[NSString stringWithFormat:@"%02d:%02d", (int)(seconds / 60), (int)(seconds % 60)]];
}

- (void)internal_updateDuration:(NSTimer *)timer {
  SEL selector = NSSelectorFromString([timer userInfo]);
  if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:selector withObject:timer];
#pragma clang diagnostic pop
  }
}

- (void)startCallDurationTimerWithSelector:(SEL)sel {
  NSString *selectorAsString = NSStringFromSelector(sel);
  self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                        target:self
                                                      selector:@selector(internal_updateDuration:)
                                                      userInfo:selectorAsString
                                                       repeats:YES];
}

- (void)stopCallDurationTimer {
  [self.durationTimer invalidate];
  self.durationTimer = nil;
}

@end
