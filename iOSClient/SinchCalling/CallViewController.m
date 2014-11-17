#import "CallViewController.h"
#import "CallViewController+UI.h"

@implementation CallViewController

- (id<SINAudioController>)audioController {
  return [[(AppDelegate *)[[UIApplication sharedApplication] delegate] client] audioController];
}

#pragma mark - UIViewController Cycle

- (void)viewDidLoad {
  [super viewDidLoad];

  if ([self.call direction] == SINCallDirectionIncoming) {
      NSLog(@"show call screen");
    [self setCallStatusText:@""];
    [self showButtons:kButtonsAnswerDecline];
    [[self audioController] startPlayingSoundFile:[self pathForSound:@"incoming.wav"] loop:YES];
  } else {
    [self setCallStatusText:@"calling..."];
    [self showButtons:kButtonsHangup];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.remoteUsername.text = [self.call remoteUserId];
}

#pragma mark - Call Actions

- (IBAction)accept:(id)sender {
  [[self audioController] stopPlayingSoundFile];
  [self.call answer];
}

- (IBAction)decline:(id)sender {
  [self.call hangup];
  [self dismiss];
}

- (IBAction)hangup:(id)sender {
  [self.call hangup];
  [self dismiss];
}

- (void)onDurationTimer:(NSTimer *)unused {
  NSInteger duration = [[NSDate date] timeIntervalSinceDate:[[self.call details] establishedTime]];
  [self setDuration:duration];
}

#pragma mark - SINCallDelegate
-(void)call:(id<SINCall>)call shouldSendPushNotifications:(NSArray *)pushPairs{
    NSLog(@"should send push");
    id<SINPushPair> pdata = [pushPairs lastObject];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:pdata.pushPayload forKey:@"pushPayload"];
    NSString* deviceToken = [[[[pdata.pushData description]
                               stringByReplacingOccurrencesOfString: @"<" withString: @""]
                              stringByReplacingOccurrencesOfString: @">" withString: @""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""] ;
    NSString* token = [[NSString alloc] initWithData:pdata.pushData encoding:NSUTF8StringEncoding];
    [dic setObject:deviceToken forKey:@"pushData"];
    AFHTTPSessionManager* manager = [((AppDelegate*)[UIApplication sharedApplication].delegate) getJsonManager];
    [manager POST:@"<yoururl>" parameters:dic success:^(NSURLSessionDataTask *task, id responseObject) {
            //we dont want to do anything here
    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
            //we dont want to do anything here
    }];
}

- (void)callDidProgress:(id<SINCall>)call {
    NSLog(@"call progress");
  [self setCallStatusText:@"ringing..."];
  [[self audioController] startPlayingSoundFile:[self pathForSound:@"ringback.wav"] loop:YES];
}

- (void)callDidEstablish:(id<SINCall>)call {
        NSLog(@"call progress");
  [self startCallDurationTimerWithSelector:@selector(onDurationTimer:)];
  [self showButtons:kButtonsHangup];
  [[self audioController] stopPlayingSoundFile];
}

- (void)callDidEnd:(id<SINCall>)call {
  [self dismiss];
  [[self audioController] stopPlayingSoundFile];
  [self stopCallDurationTimer];
}

#pragma mark - Sounds

- (NSString *)pathForSound:(NSString *)soundName {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:soundName];
}

@end
