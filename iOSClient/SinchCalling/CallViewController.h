#import <UIKit/UIKit.h>
#import <Sinch/Sinch.h>

#import "AppDelegate.h"
#import "SINUIViewController.h"
#import <AFNetworking/AFNetworking.h>

typedef enum { kButtonsAnswerDecline, kButtonsHangup, } EButtonsBar;

@interface CallViewController : SINUIViewController <SINCallDelegate>

@property (weak, nonatomic) IBOutlet UILabel *remoteUsername;
@property (weak, nonatomic) IBOutlet UILabel *callStateLabel;
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;

@property (nonatomic, readwrite, strong) NSTimer *durationTimer;

@property (nonatomic, readwrite, strong) id<SINCall> call;

- (IBAction)accept:(id)sender;
- (IBAction)decline:(id)sender;
- (IBAction)hangup:(id)sender;

@end
