#import <UIKit/UIKit.h>
#import <Sinch/Sinch.h>
#import <PushKit/PushKit.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, SINClientDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id<SINClient> client;

- (void)initSinchClientWithUserId:(NSString *)userId;
-(AFHTTPSessionManager*)getJsonManager;

@end
