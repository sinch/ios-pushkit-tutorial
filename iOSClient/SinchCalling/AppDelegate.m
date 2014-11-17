#import "AppDelegate.h"
#import "AppDelegate+UI.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self addSplashView];
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    [self handleLocalNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self handleLocalNotification:notification];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self dismissSplashViewIfNecessary];
}

#pragma mark -

- (id<SINClient>)client {
    return _client;
}

- (void)initSinchClientWithUserId:(NSString *)userId {
    if (!_client) {
        
        _client = [Sinch clientWithApplicationKey:@"<yourkey>"
                                applicationSecret:@"<yoursecret>"
                                  environmentHost:@"clientapi.sinch.com"
                                           userId:userId];
        
        _client.delegate = self;
        
        [_client setSupportCalling:YES];
        [_client setSupportActiveConnectionInBackground:NO];
        [_client setSupportPushNotifications:YES];
        [_client start];
        //[_client startListeningOnActiveConnection];
    }
}

- (void)handleLocalNotification:(UILocalNotification *)notification {
    if (notification) {
        id<SINNotificationResult> result = [self.client relayLocalNotification:notification];
        if ([result isCall] && [[result callResult] isTimedOut]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Missed call"
                                  message:[NSString stringWithFormat:@"Missed call from %@", [[result callResult] remoteUserId]]
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil];
            [alert show];
        }
    }
}


#pragma mark - PushKit

-(void)voipRegistration
{
    PKPushRegistry* voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}	

-(AFHTTPSessionManager*)getManager
{
    AFHTTPSessionManager* manager = [[AFHTTPSessionManager alloc] init];
    manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://yoururl/"]];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    return manager;
}

-(AFHTTPSessionManager*)getJsonManager
{
    AFHTTPSessionManager* manager = [self getManager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    return manager;
}

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{

   
    NSString* deviceToken = [[[[credentials.token description]
                               stringByReplacingOccurrencesOfString: @"<" withString: @""]
                              stringByReplacingOccurrencesOfString: @">" withString: @""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""] ;
    NSData* tokenData =[deviceToken dataUsingEncoding:NSUTF8StringEncoding];
    [_client registerPushNotificationData:credentials.token];
    AFHTTPSessionManager* manager = [self getManager];
    [manager GET:[@"regdevice?token=" stringByAppendingString:deviceToken] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"posted token");
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"posted token error %@", error);
    }];
    
    
    ///send to surver
}

-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    //notify
    NSDictionary* dic = payload.dictionaryPayload;
    NSString* sinchinfo = [dic objectForKey:@"sin"];
    UILocalNotification* notif = [[UILocalNotification alloc] init];
    notif.alertBody = @"incoming call";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    if (sinchinfo == nil)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [_client relayRemotePushNotificationPayload:sinchinfo];
    });
    
}

#pragma mark - SINClientDelegate

- (void)clientDidStart:(id<SINClient>)client {
    NSLog(@"Sinch client started successfully (version: %@)", [Sinch version]);
    [self voipRegistration];
}

- (void)clientDidStop:(id<SINClient>)client {
    NSLog(@"Sinch client stopped");
}

- (void)clientDidFail:(id<SINClient>)client error:(NSError *)error {
    NSLog(@"Error: %@", error);
}

- (void)client:(id<SINClient>)client
    logMessage:(NSString *)message
          area:(NSString *)area
      severity:(SINLogSeverity)severity
     timestamp:(NSDate *)timestamp {
    
    if (severity == SINLogSeverityCritical) {
        NSLog(@"%@", message);
    }
}

@end