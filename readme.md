# Save Energy In Your iOS8 Apps With Pushkit

The biggest challenge when you write communications apps is that you want the experience to very quick but at the same time not consume too much of you users battery. Today we are going to investigate the new push kit framework and make it run with our [Voice API](http://www.sinch.com/products/calling/voice-api/). It will require some beta installs and server side code, so expect to spend around 45-60 minutes on this. This tutorial assumes that you are familiar with the old push system and how to create certificates.

## History
Prior to iOS8 developers needed to cater for the following scenarios
- ActiveConnecton in the foreground
- Active background connection (VoIP socket) via VoIP entitlement
- Regular push notifications

In this article we are going to focus on the background modes and pros and cons with each of them. 

### VoIP socket
This method prior to iOS8 gave you as app developer the greatest flexibility, as the OS would keep your VoIP socket alive and periodically ping you signaling server. If an incoming message was received the OS would give you 10 seconds to execute code, like pushing a local notification and maybe starting to set up the call. The draw back is of course that one more socket was kept alive in the phone, and the phone would have to wake up and ping you servers periodically. And of course, Apple always keeps the right to shut you down if they think they need to conserve energy. 

### Push
Push is very energy efficient since it is delivered on a shared socket. The drawbacks however are a quite a few. 
- Delivery; Apple don't really promise a delivery time or priority
- Get permission to send push; not all users understand that they need to allow it to receive calls. 
- The app doesn't know about a push until the users decides to act on the push. 
- Apple might throttle your push messages if you send too many 

Given the two options above, you as a developer needed to implement both if you where going with VoIP sockets. Or if you where ok with a slight delay only remote push. 

## iOS8 Push Kit
With iOS8 Apple introduced a new kind of push; VoIP push. There are a couple of great things about this push message. 
- You don't need to allow push, it just works without the user knowing about it. (verify)
- Apple promises to deliver these push notifications high priority. 

But the best thing is it allows you to execute code when the push arrives! This is excellent news. My initial tests in a sandbox environment show that its pretty damn quick and since you can handle all calls the same way it reduces the time to implement our Voice API and saves you time. 

### The Bad News
It only works on iOS8, kind of a given but anyway. With our SDK (and probably any WebRTC SDK) in only works on iOS 8.1 (as of writing this its beta 1). The reason for this was in 8.0 the compiler linked is a dynlib and was not able to locate push kit framework for 32bits when running on 64bit hardware. We at Sinch are of course working on bringing our SDK up to 64bit but for now when you use us you need to compile for armv7 and armv7s. 

## The steps
- Install Xcode 6.1 (http://developer.apple.com )
- Install iOS beta 8.1 beta on an iOS device
- Create an account with Sinch http://sinch.com/signup
- Download the SDK http://sinch.com/Download (we are going to use the sample calling app, so download the SDK not cocapods)
- Grab a coffee 
- Implement some server side code to send push
- Implement push kit in the Sample app

## Create An App ID And Push Kit Certificate For Your App
In the member center create, an App ID, I am going to call mine com.sinch.pushkit and enable push services. 

Head over to https://developer.apple.com/account/ios/certificate/certificateCreate.action and for the experienced you will notice that there is a new kind of certificate here.

![](images/voipcert.png) 

Click next and select your App ID.
 
Download the certificate and in keychain access search for VoIP, control+click to export the certificate with private key and save it.

![](images/voipcert.png) 

Create a development provisioning profile for the com.sinch.pushkit

## The Server Side Code 
In this tutorial I am going to use very simple push framework from nuget and simple WebAPI controller in C#. I decided to build my own because I am going to do some performance testing and Parse (for example) don’t support VoIP certificates yet.

What we need to do is to implement one method to send the actual push messages. Lets start!
Launch your Visual studio and create a empty MVC project with Web API enabled 

![](images/setupmvcproject.png)

I am going to host the site in azure but you can host where you want.
Update all nuget packages and install PushSharp in package manager console.
```nuget
update-package
install-package PushSharp
```

[PushSharp](https://github.com/Redth/PushSharp) is a wonderful little package that makes it a breeze to send push notifications. I am not strictly following the implementation guidelines by running pushsharp in an asp.net application. But lets do the best we can and follow the guidelines for hosting there by implementing a singleton.

Create an call called PushService and add the below code:

```csharp
public class PushService {
    private static PushService _context;
    public static PushService Context() {
        if (_context == null) {
            _context = new PushService();
        }
        return _context;
    }
    public PushBroker Broker { get; set; }
    public PushService() {
        Broker = new PushBroker();
        var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"yourfile");
        var appleCert = File.ReadAllBytes(path);
        //its super important that you set the environment your self to 
        //sandbox and disable certificate validation
        Broker.RegisterAppleService(
             new ApplePushChannelSettings(false, 
        		appleCert, "yourpassword", true));
    }
}
```

Remember to add the P12 file you exported from your mac when you created the VoIP push certificate. PushSharp does not support to validate VoIP certificates yet so it’s important that you set environment and certificate validation your self.

Next, add a new WebAPI controller to your project and name it PushKit and add two methods
```csharp
public class PushKitController : ApiController {
    [Route("sendpush")]
    [HttpPost]
    public HttpResponseMessage SendPush(PushPair push) { }
}

```
Next add a call to your models called PushPair. This object is what the Sinch framework will give you back when you should send push. PushData contains the token and payLoad contains information about the call
```csharp
public class PushPair {
    [JsonProperty("pushData")]
    public string PushData { get; set; }
    [JsonProperty("pushPayload")]
    public string PushPayload { get; set; }
}
```

Lets implement the actual push. Open up your PushKitController and add the following code to your sendpush method 
```csharp
var broker = PushService.Context().Broker;
            broker.QueueNotification(new AppleNotification()
                .ForDeviceToken(push.PushData)
                .WithAlert("Incoming call")
                .WithCustomItem("sin", push.PushPayload));
            return new HttpResponseMessage(HttpStatusCode.OK);
```

That’s it, publish it to website that your iPhone can access. 

## Changing The Sample App To Support Push
Open the Sinch calling app sample in the Sinch SDK (or copy it if you want to save the vanilla sample).
Rename the project your App ID, in my case push kit, then click the project and select your target and change bundle identifier to your app id
![](images/changenamespace.png) 
Make sure you download the provisioning profile for the app *(Xcode/preferences/accounts/viewdetails/ and click on the refresh button)*
phew, its so much work to just set up the basics. 
Let the coding begin.

## Implement Registration Of Push Kit
First add push kit framework to your project in buildphases 
![](images/addpushkit.png) 
Add import and protocol for push kit to AppDelegate.h 
```objectivec
#import <UIKit/UIKit.h>
#import <Sinch/Sinch.h>
#import <PushKit/PushKit.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, 
SINClientDelegate, PKPushRegistryDelegate>
```

open up appDelegate.m and add support for local notifications, yeah that’s another new thing in iOS8. You have to ask to send local push. 
```objectivec
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
```
under addSplashview add the following

```objectivec
UIUserNotificationSettings* notificationSettings =
    [UIUserNotificationSettings settingsForTypes:
      UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | 
      UIUserNotificationTypeSound categories:nil];
[[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
```
This will ask the user to allow you to play sounds, alerts and badges locally. pretty similar to the old registerRemoteNotification options.

Find the initSinchClientWithUserId and change it to look like this

```
- (void)initSinchClientWithUserId:(NSString *)userId {
    if (!_client) {
        _client = [Sinch clientWithApplicationKey:@"yourkey"
                         applicationSecret:@"yoursecret"
                         environmentHost:@"clientapi.sinch.com"
                         userId:userId];
        _client.delegate = self;
        [_client setSupportCalling:YES];
        [_client setSupportActiveConnectionInBackground:NO];
        [_client setSupportPushNotifications:YES];
        [_client start];
    }
}

```
The important thing here make sure you enter your key and secret and the correct url (sandbox or production). And also in this example we want to force push to be used so we don’t support any active connections. 
Next, implement the push kit methods

```
-(AFHTTPSessionManager*)getManager
{
    AFHTTPSessionManager* manager = [[AFHTTPSessionManager alloc] init];
    manager = [[AFHTTPSessionManager alloc] initWithBaseURL:
        [NSURL URLWithString:@"<YOURSERVERURL>"]];
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
     ///tell the Sinch SDK about the push token so we can 
     ///give that to users that want to call this user.
    [_client registerPushNotificationData:credentials.token];
}
```
The above method is very similar to the regular notification service, and we just pass it to the Sinch SDK
Still AppDelegate adds support to handle incoming push by implementing below. 
```
-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    //notify
    NSDictionary* dic = payload.dictionaryPayload;
    NSString* sinchinfo = [dic objectForKey:@"sin"];
    if (sinchinfo == nil)
        return;
    UILocalNotification* notif = [[UILocalNotification alloc] init];
    notif.alertBody = @"incoming call";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    dispatch_async(dispatch_get_main_queue(), ^{
       [_client relayRemotePushNotificationPayload:sinchinfo];
    });
}

```
In the above method we are checking that the push has a SIN payload (that its a call for more details http://www.sinch.com/docs/ios/user-guide/#pushnotifications) scheduling a local notification and scheduling a local notification. 

Done, we are ready to receive push, find the method clientDidStart and add change so it looks like this
```
- (void)clientDidStart:(id<SINClient>)client {
    NSLog(@"Sinch client started successfully (version: %@)", [Sinch version]);
    ///add the VoIP registration
    [self voipRegistration];
}
```
That’s all the changes required on AppDelegate, next we need to handle that we want to send push in the call flow open up CallViewController.m
and implement the following method
```
-(void)call:(id<SINCall>)call shouldSendPushNotifications:(NSArray *)pushPairs{
    id<SINPushPair> pdata = [pushPairs lastObject];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:pdata.pushPayload forKey:@"pushPayload"];
    [dic setObject:pdata.pushData forKey:@"pushData"];
    AFHTTPSessionManager* manager = [((AppDelegate*)[UIApplication sharedApplication].delegate) getJsonManager];
    [manager POST:@"push" parameters:dic success:^(NSURLSessionDataTask *task, id responseObject) {
            //we don’t want to do anything here
    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
            //we don’t want to do anything here
    }];
}
```
This method is invoked when the SinchClient can’t find the user online.

## Run it
Deploy to the emulator and launch it, log in as A. Next run it on your iPhone, log in as B. Turn on some music on your computer

In the emulator dial B it should now start ringing on your iPhone, walk out of the room and enjoy the high quality audio. 

## Conclusion
The biggest advantage with push kit is that you actually can execute code in the background. Despite Apple’s documentation it actually doesn’t seem that the OS will wake you app if you terminate it, which is a bummer. Also right now there is a bug so you only get a token for the sandbox environment and no production token. They will probably address this pretty quickly. Overall I think this is step in the right direction for Apple to let developers build more real-time applications. I expect that they will open up this kind of push not only for VoIP but also for other types of applications. 
