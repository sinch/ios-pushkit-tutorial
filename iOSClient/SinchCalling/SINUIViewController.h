#import <UIKit/UIKit.h>

@interface SINUIViewController : UIViewController

@property (nonatomic, readonly, assign) BOOL isAppearing;
@property (nonatomic, readonly, assign) BOOL isDisappearing;

- (void)dismiss;

@end
