# How to use Pushkit for iOS VoIP push notifications

The biggest challenge when writing communications apps is providing a quick experience that won’t drain your users’ battery. We are going to investigate the new PushKit framework and make it run with our [Voice API](https://www.sinch.com/products/voice-api/). It will require some beta installs and server-side code, so expect to spend around 45 to 60 minutes here. This tutorial assumes that you are familiar with the old push system and how to create certificates.

## History
Prior to iOS 8, developers needed to cater to the following scenarios:

- ActiveConnecton in the foreground
- Active background connection (VoIP socket) via VoIP entitlement
- Regular push notifications

In this article, we will focus on the background modes and pros and cons of each of them. 

### VoIP socket
Prior to iOS 8, this method gave app developers the greatest flexibility because the OS would keep your VoIP socket alive and periodically ping your signaling server. If an incoming message was received, the OS would give you 10 seconds to execute code, like pushing a local notification and starting to set up the call. The drawback was that one more socket was kept alive in the phone, and the phone would have to wake up and ping your servers periodically. And, of course, Apple retains the right to shut you down to conserve energy. 

### Push
Push is very energy efficient since it is delivered on a shared socket. However, there are quite a few drawbacks: 

- Delivery: Apple doesn't promise a delivery time or priority.
- Need permission to send push: Not all users understand that they need to allow it to receive calls. 
- The app doesn't know about a push until the user decides to act on the push. 
- Apple might throttle your push messages if you send too many. 

Given the two options above, developers need to implement both if going with VoIP sockets. If you are fine with a slight delay, you only need to implement remote push. 

## iOS 8 PushKit
With iOS 8, Apple introduced a new kind of push: VoIP push. There are a couple of benefits of this push message:

- You don't need to allow push; it works without the user knowing about it.
- Apple promises to deliver these push notifications high priority. 

The best thing? It allows you to execute code when the push arrives. My initial tests in a sandbox environment show that it’s pretty darn quick, and since you can handle all calls the same way, it reduces the time to implement our Voice API. 

### The bad news
It only works on iOS 8. With our SDK (and probably any WebRTC SDK), it only works on iOS 8.1 (as of writing this, it's beta 1). This is because in 8.0, the compiler linked is a dynlib and is not able to locate PushKit framework for 32 bits when running on 64-bit hardware. At Sinch, we are working on bringing our SDK up to 64 bits, but for now, when you use us, you need to compile for armv7 and armv7s. 

## The steps
- Install [Xcode 6.1](http://developer.apple.com)
- Install iOS 8.1 beta on an iOS device
- Create an account with [Sinch](http://sinch.com/dashboard/#/signup)
- Download the SDK from [https://www.sinch.com/downloads/](https://www.sinch.com/downloads/). (We are going to use the sample calling app, so download the SDK instead of CocoaPods.)
- Grab a coffee 
- Implement some server-side code to send push
- Implement PushKit in the sample app

## Create an app ID and PushKit certificate for your app
In the member center, create an App ID. I am going to call mine com.sinch.pushkit and enable push services. 

Head over to [https://developer.apple.com/account/ios/certificate/certificateCreate.action](https://developer.apple.com/account/ios/certificate/certificateCreate.action) and you will notice that there is a new kind of certificate here.

![voip certificate](images/voipcert.png) 

Click Next and select your App ID.
 
Download the certificate and in keychain access search for VoIP, control+click to export the certificate with private key, and save it.

![voip certificate](images/voipcert.png) 

Create a development provisioning profile for the com.sinch.pushkit

## The server-side code 
In this tutorial, I will use a very simple push framework from nuget and a simple WebAPI controller in C#. I decided to build my own because I am going to do some performance testing and BaaS providers like Parse don’t support VoIP certificates yet.

We’ll need to implement one method to send the actual push messages, so launch your Visual Studio and create an empty MVC project with Web API enabled. 

![mvc project](images/setupmvcproject.png)

I am going to host the site in Azure, but you can host wherever you want.
Update all nuget packages and install PushSharp in package manager console.
```nuget
update-package
install-package PushSharp
```

[PushSharp](https://github.com/Redth/PushSharp) is a wonderful little package that makes sending push notifications a breeze. I am not strictly following the implementation guidelines by running PushSharp in an asp.net application, but let’s do the best we can and follow the guidelines for hosting there by implementing a singleton.

Create a call called PushService and add the below code:

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

Remember to add the P12 file you exported from your Mac when you created the VoIP push certificate. PushSharp does not support VoIP certificate validation yet, so it’s important that you set the environment and certificate validation yourself.

Next, add a new WebAPI controller to your project and name it PushKit. Add two methods:

```csharp
public class PushKitController : ApiController {
    [Route("sendpush")]
    [HttpPost]
    public HttpResponseMessage SendPush(PushPair push) { }
}

```
Next, add a call to your models called PushPair. This object is what the Sinch framework will give you back when you should send push. PushData contains the token and payLoad contains information about the call
```csharp
public class PushPair {
    [JsonProperty("pushData")]
    public string PushData { get; set; }
    [JsonProperty("pushPayload")]
    public string PushPayload { get; set; }
}
```

Now, implement the actual push. Open up your PushKitController and add the following code to your sendpush method: 
```csharp
var broker = PushService.Context().Broker;
            broker.QueueNotification(new AppleNotification()
                .ForDeviceToken(push.PushData)
                .WithAlert("Incoming call")
                .WithCustomItem("sin", push.PushPayload));
            return new HttpResponseMessage(HttpStatusCode.OK);
```

That’s it. Publish it to a website that your iPhone can access. 

## Changing the sample app to support push
Open the Sinch calling app sample in the Sinch SDK (or copy it if you want to save the vanilla sample).
Rename the project your App ID, in my case PushKit, then click the project. Select your target and change bundle identifier to your App ID.

![chance name space](images/changenamespace.png) 

Make sure you download the provisioning profile for the app *(Xcode/preferences/accounts/viewdetails/ and click on the refresh button)* Phew! It's so much work to just set up the basics. Let the coding begin.

## Implement registration of PushKit
First, add PushKit framework to your project in buildphases:

![add pushkit](images/addpushkit.png) 

Then, add import and protocol for PushKit to AppDelegate.h:

```objectivec
#import <UIKit/UIKit.h>
#import <Sinch/Sinch.h>
#import <PushKit/PushKit.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, 
SINClientDelegate, PKPushRegistryDelegate>
```

Next, open up appDelegate.m and add support for local notifications. (Yeah, that’s another new thing in iOS 8.) You have to ask to send local push: 
```objectivec
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
```
Under addSplashview, add the following:

```objectivec
UIUserNotificationSettings* notificationSettings =
    [UIUserNotificationSettings settingsForTypes:
      UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | 
      UIUserNotificationTypeSound categories:nil];
[[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
```
This will ask the user to allow you to play sounds, alerts, and badges locally, which is pretty similar to the old registerRemoteNotification options.

Find the initSinchClientWithUserId and change it to look like this:

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
Here it's important to make sure you enter your key and secret and the correct URL (sandbox or production). Also, in this example, you want to force push to be used so you don’t support any active connections. Next, implement the PushKit methods:

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
The above method is very similar to the regular notification service, and you just pass it to the Sinch SDK. AppDelegate adds support to handle incoming push by implementing below. 

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
In the above method, you are checking that the push has a SIN payload (for more details, see [here](http://www.sinch.com/docs/ios/user-guide/#pushnotifications)) scheduling a local notification and scheduling a local notification. 

Done! You are ready to receive push. Find the method clientDidStart and add a change so it looks like this:

```
- (void)clientDidStart:(id<SINClient>)client {
    NSLog(@"Sinch client started successfully (version: %@)", [Sinch version]);
    ///add the VoIP registration
    [self voipRegistration];
}
```
Those are all the changes required on AppDelegate. Next, you’ll want to send push in the call flow. Open up CallViewController.m
and implement the following method:

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
Deploy to the emulator, launch the app, and log in as A. Next, run it on your iPhone, and log in as B. Play some music on your computer.

In the emulator dial, B should now start ringing on your iPhone. Walk out of the room, answer the call on the iPhone, and enjoy the high-quality audio. 

## Conclusion
The biggest advantage of PushKit is the ability to execute code in the background. Despite Apple’s documentation, it actually doesn’t seem that the OS will wake your app if you terminate it, which is a bummer. Also, there is currently a bug where you only get a token for the sandbox environment and no production token, but Apple will probably address this pretty quickly. Overall, I think this is step in the right direction for Apple to let developers build more real-time applications. I expect that it will open up this kind of push not only for VoIP, but also for other types of applications. 
