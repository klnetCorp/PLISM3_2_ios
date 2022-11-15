//
//  AppDelegate.m
//  PLISM3
//
//  Created by juis on 2016. 2. 26..
//  Copyright © 2016년 klnet. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "DataSet.h"

@import Firebase;
@import FirebaseMessaging;
@import UserNotifications;

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

// Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
// running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
// devices running iOS 10 and above.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
@end
#endif
// Copied from Apple's header in case it is missing in some cases (e.g. pre-Xcode 8 builds).
#ifndef NSFoundationVersionNumber_iOS_9_x_Max
#define NSFoundationVersionNumber_iOS_9_x_Max 1299
#endif
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        // iOS 7.1 or earlier. Disable the deprecation warnings.
        UIRemoteNotificationType allNotificationTypes =
        (UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeBadge);
        [application registerForRemoteNotificationTypes:allNotificationTypes];
        
    } else {
        // iOS 8 or later
        // [START register_for_notifications]
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
            UIUserNotificationType allNotificationTypes =
            (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
            UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
            // iOS 10 or later
            UNAuthorizationOptions authOptions =
            UNAuthorizationOptionAlert
            | UNAuthorizationOptionSound
            | UNAuthorizationOptionBadge;
            [[UNUserNotificationCenter currentNotificationCenter]
             requestAuthorizationWithOptions:authOptions
             completionHandler:^(BOOL granted, NSError * _Nullable error) {
             }
             ];
            
            // For iOS 10 display notification (sent via APNS)
            [UNUserNotificationCenter currentNotificationCenter].delegate = self;
            // For iOS 10 data message (sent via FCM)
            [FIRMessaging messaging].remoteMessageDelegate = self;
        }
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        // [END register_for_notifications]
    }
    
    // [START configure_firebase]
    [FIRApp configure];
    // [END configure_firebase]
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    
    //최초실행
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        // 설치 후 이미 실행한 적이 있을 때
    }
    else
    {
        // 설치 후 처음 실행
        //UIAlertView* Alert = [[UIAlertView alloc] initWithTitle:@"앱 권한 이용 안내" message:@"[필수적 접근 권한] \n *인터넷 : 인터넷을 이용한 eTrans 서비스 접근 \n *저장공간 : 기기 사진, 미디어, 파일 액세스 권한으로 다운로드 파일 보관\n [선태적 접근 권한] \n *푸시알림 : PUSH 알림 서비스" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        //[Alert show];
        
        
        UIWindow* topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        topWindow.rootViewController = [UIViewController new];
        topWindow.windowLevel = UIWindowLevelAlert + 1;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"앱 권한 이용 안내" message:@"[필수적 접근 권한] \n *인터넷 : 인터넷을 이용한 PLISM3 서비스 접근 \n *저장공간 : 기기 사진, 미디어, 파일 액세스 권한으로 다운로드 파일 보관\n [선태적 접근 권한] \n *푸시알림 : PUSH 알림 서비스" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"confirm") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            topWindow.hidden = YES;
        }]];
        
        [topWindow makeKeyAndVisible];
        [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"]; // 처음 실행을 저장
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = [MainViewController sharedMainView];
    
    [_window makeKeyAndVisible];
    return YES;
}

// [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Print message ID.
    if (userInfo != nil) {
        NSString *str = [userInfo objectForKey:@"msg"];
        
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&error];
        NSString *seq = (NSString *)[json valueForKey:@"id"];
        NSString *userid = (NSString *)[json valueForKey:@"recv_id"];
        NSString *message = [userInfo objectForKey:@"alert"];
        
        [DataSet sharedDataSet].pushDict = [[NSDictionary alloc] initWithObjectsAndKeys:seq, @"push_id",
                                            userid, @"userid",
                                            message, @"message",
                                            nil];
        //        NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        [[MainViewController sharedMainView] performSelector:@selector(callPush)];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    // Print full message.
    NSLog(@"%@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Print message ID.
    // Print message ID.
    if (userInfo != nil) {
        NSString *str = [userInfo objectForKey:@"msg"];
        
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&error];
        NSString *seq = (NSString *)[json valueForKey:@"id"];
        NSString *userid = (NSString *)[json valueForKey:@"recv_id"];
        NSString *message = [userInfo objectForKey:@"alert"];
        
        [DataSet sharedDataSet].pushDict = [[NSDictionary alloc] initWithObjectsAndKeys:seq, @"push_id",
                                            userid, @"userid",
                                            message, @"message",
                                            nil];
        //        NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        [[MainViewController sharedMainView] performSelector:@selector(callPush)];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    
    // Print full message.
    NSLog(@"%@", userInfo);
    
    completionHandler(UIBackgroundFetchResultNewData);
}
// [END receive_message]

// [START ios_10_message_handling]
// Receive displayed notifications for iOS 10 devices.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // Print message ID.
    NSDictionary *userInfo = notification.request.content.userInfo;
    // Print message ID.
    if (userInfo != nil) {
        NSString *str = [userInfo objectForKey:@"msg"];
        
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&error];
        NSString *seq = (NSString *)[json valueForKey:@"id"];
        NSString *userid = (NSString *)[json valueForKey:@"recv_id"];
        NSString *message = [userInfo objectForKey:@"alert"];
        
        [DataSet sharedDataSet].pushDict = [[NSDictionary alloc] initWithObjectsAndKeys:seq, @"push_id",
                                            userid, @"userid",
                                            message, @"message",
                                            nil];
        //        NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        [[MainViewController sharedMainView] performSelector:@selector(callPush)];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    // Print full message.
    NSLog(@"%@", userInfo);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    // Print message ID.
    if (userInfo != nil) {
        NSString *str = [userInfo objectForKey:@"msg"];
        
        NSError* error;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&error];
        NSString *seq = (NSString *)[json valueForKey:@"id"];
        NSString *userid = (NSString *)[json valueForKey:@"recv_id"];
        NSString *message = [userInfo objectForKey:@"alert"];
        
        
        [DataSet sharedDataSet].pushDict = [[NSDictionary alloc] initWithObjectsAndKeys:seq, @"push_id",
                                            userid, @"userid",
                                            message, @"message",
                                            nil];
        //        NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        [[MainViewController sharedMainView] performSelector:@selector(callPush)];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    
    // Print full message.
    NSLog(@"%@", userInfo);
}

#endif
// [END ios_10_message_handling]


// [START refresh_token]
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"FCM registration token: %@", fcmToken);
    
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
    
    //NSString *fcmToken = [FIRMessaging messaging].FCMToken;
    
    [DataSet sharedDataSet].deviceTokenID = fcmToken;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"jpp.plist"];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath: path])
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"jpp" ofType:@"plist"];
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error];
    }
    
    NSMutableDictionary *jppData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    [jppData setObject:fcmToken forKey:@"token"];
    
    [jppData writeToFile:path atomically:YES];
    
    
}
// [END refresh_token]

// [START ios_10_data_message]
// Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
// To enable direct data messages, you can set [Messaging messaging].shouldEstablishDirectChannel to YES.
- (void)messaging:(FIRMessaging *)messaging didReceiveMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"Received data message: %@", remoteMessage.appData);
}
// [END ios_10_data_message]



// [START ios_10_data_message_handling]
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Receive data message on iOS 10 devices while app is in the foreground.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    // Print full message
    NSLog(@"remoteMessage : %@", [remoteMessage appData]);
}
#endif
// [END ios_10_data_message_handling]


- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    
    // TODO: If necessary send token to application server.
}

- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Unable to register for remote notifications: %@", error);
}

// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
// the InstanceID token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APNs token retrieved: %@", deviceToken);
    
    // With swizzling disabled you must set the APNs token here.
    // [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [DataSet sharedDataSet].isBackground = YES;
    [[FIRMessaging messaging] disconnect];
    NSLog(@"Disconnected from FCM");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [DataSet sharedDataSet].isBackground = NO;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self connectToFcm];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.klnet.plism3.PLISM3" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PLISM3" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PLISM3.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
