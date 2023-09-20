//
//  MainViewController.m
//  PLISM3
//
//  Created by juis on 2016. 2. 26..
//  Copyright © 2016년 klnet. All rights reserved.
//

#import "MainViewController.h"
#import "OpenUDID.h"
#import "DataSet.h"
#import <CommonCrypto/CommonDigest.h>
@interface MainViewController ()

@end
@implementation UIWebView (Javascript)
static BOOL diagStat = NO;
static BOOL diagStat2 = NO;
- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"확인" otherButtonTitles: nil];
    [alert show];
}

- (BOOL)webView:(UIWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame {
    diagStat2 = NO;
    UIAlertView *confirmDiag = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:NSLocalizedString(@"취소", @"취소") otherButtonTitles:NSLocalizedString(@"확인", @"확인"), nil];
    [confirmDiag show];
    
    //버튼 누르기전까지 지연.
    CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 7.) {
        while (diagStat2 == NO) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
        }
    } else {
        while (diagStat2 == NO && confirmDiag.superview != nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
        }
    }
    return diagStat;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        diagStat = NO;
        diagStat2 = YES;
    } else if (buttonIndex == 1) {
        diagStat = YES;
        diagStat2 = YES;
    }
}

@end

@implementation MainViewController
@synthesize webView01,view_footer;
@synthesize bt_home, bt_prev, bt_next, bt_refresh, bt_top, constraint_footer_view_height, authKey, iv_intro;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    webView01.delegate = self;
    webView01.scrollView.delegate = self;
    [view_footer setHidden:YES];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"authinfo.plist"];

    NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    constraint_footer_view_height.constant = 0.0f;
    authKey = [authData objectForKey:@"auth_key"];
    
    
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [bundleInfo valueForKey:@"CFBundleIdentifier"];
    NSURL *lookupURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", bundleIdentifier]];
    NSData *lookupResults = [NSData dataWithContentsOfURL:lookupURL];
    NSDictionary *jsonResults = [NSJSONSerialization JSONObjectWithData:lookupResults options:0 error:nil];
    
    NSUInteger resultCount = [[jsonResults objectForKey:@"resultCount"] integerValue];
    NSString *sSignHash = [self md5:MAIN_URL];
    NSString *getHash = [self sendDataToServer];
   
    BOOL rootingCheck = [self checkRooting];
    
    
    if(!rootingCheck) {
        NSString *msg = [NSString stringWithFormat:@"루팅된 단말기 입니다. \n개인정보 유출의 위험성이 있으므로 \n프로그램을 종료합니다."];
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:@"알림"
                                      message:msg
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"확인"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
            exit(0);
                                   }];
        [alert addAction:okAction];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
        });
    }
    
    if(![sSignHash isEqualToString:getHash]) {
    
        NSString *msg = [NSString stringWithFormat:@"프로그램 무결성에 위배됩니다. \nAppStore 내에서 \n 설치하시기 바랍니다."];
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:@"알림"
                                      message:msg
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"확인"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
            exit(0);
                                   }];
        [alert addAction:okAction];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
        });
    }
    
#if DEBUG
    NSLog(@"resultCount : %lu", (unsigned long)resultCount);
#endif
    
   
    
//    if (resultCount){
//        NSDictionary *appDetails = [[jsonResults objectForKey:@"results"] firstObject];
//        NSString *latestVersion = [appDetails objectForKey:@"version"];
//        NSString *currentVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
//        NSLog(@"latestVersion====%@",latestVersion);
//        NSLog(@"currentVersion====%@",currentVersion);
//        
//        //앱스토어에 올라간 버전과 빌드버전이 다를경우 팝업을 출력한다.
//        if(latestVersion!=currentVersion){
//            NSString *versionmsg = [NSString stringWithFormat:@"새로운버전(%@)이 나왔습니다. 업데이트 하시겠습니까?",latestVersion];
//            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"확인" message:versionmsg delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인",nil];
//            av.tag = 100;
//            [av show];
//            return;
//        }
//    }
    
    
    
    
    if ([authKey length] == 0) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/mbl/main/login_auth.jsp",MAIN_URL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
        [webView01 loadRequest:request];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/mbl/main/auto_login.jsp",MAIN_URL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
        [webView01 loadRequest:request];
    }
    
    //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/test.jsp",mainUrl]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    //[webView01 loadRequest:request];
    
    UIWindow *_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    
    webview_height = _window.frame.size.height - 72.0f;
    [bt_top setHidden:YES];
    
    //APNS 에 장치 등록
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:
                                                                             (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
}

- (void) callPush {
    [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:openpushmenu();"];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

+ (MainViewController *)sharedMainView
{
    static MainViewController *singletonClass = nil;
    if(singletonClass == nil)
    {
        @synchronized(self)
        {
            if(singletonClass == nil)
            {
                singletonClass = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
            }
        }
    }
    return singletonClass;
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *requestString = [[request URL] absoluteString];
#if DEBUG
    NSLog(@"requestString : %@", requestString);
#endif
//    if([requestString hasPrefix:@"hybridversion://"]) {
//        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridversion://"];
//        NSString *server_version = [jsDataArray objectAtIndex:1];
//        NSLog(@"server_version : %@", server_version);
//        
//        NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
//        NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
//        
//        NSLog(@"currentVersion : %@", currentVersion);
//        
//        if (![server_version isEqualToString:currentVersion]) {
//            NSString *versionmsg = [NSString stringWithFormat:@"새로운버전(%@)이 나왔습니다. 업데이트 하시겠습니까?",server_version];
//            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"확인" message:versionmsg delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인",nil];
//            av.tag = 100;
//            [av show];
//        }
//        
//    }
    
    
    if ([requestString hasSuffix:@"/mbl/main/main.jsp"]) {
        [DataSet sharedDataSet].isLogin = true;
        [iv_intro setHidden:YES];
        [webView01 setHidden:NO];
        [view_footer setHidden:NO];
    }
    
    
    if([requestString hasPrefix:@"hybridautologin://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridautologin://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        return NO;
    } else if ([requestString hasPrefix:@"hybridloginresult://"]) {
        NSArray *jsDataArray2 = [requestString componentsSeparatedByString:@"hybridloginresult://"];
        NSArray *jsDataArray = [[jsDataArray2 objectAtIndex:1] componentsSeparatedByString:@"//"];
        
        NSString *jsString1 = [jsDataArray objectAtIndex:0];
        NSString *jsString2 = [jsDataArray objectAtIndex:1];
        
#if DEBUG
        NSLog(@"authkeyresult : %@", jsString1);
        NSLog(@"userid : %@", jsString2);
#endif
        [DataSet sharedDataSet].userid = jsString2;

        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"authinfo.plist"];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"authinfo" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        [authData setObject:jsString1 forKey:@"auth_key"];
        [authData writeToFile:path atomically:YES];
        
        authKey = [authData objectForKey:@"auth_key"];
        
        [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:fn_goMain();"];
        
        return NO;
    } else if ([requestString hasPrefix:@"hybriddelauthkey://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybriddelauthkey://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        
        if ([jsString isEqualToString:@"off"]) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:@"authinfo.plist"];
            
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath: path])
            {
                NSString *bundle = [[NSBundle mainBundle] pathForResource:@"authinfo" ofType:@"plist"];
                
                [fileManager copyItemAtPath:bundle toPath: path error:&error];
            }
            
            NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
            
            [authData setObject:@"" forKey:@"auth_key"];
            [authData writeToFile:path atomically:YES];
            
            authKey = [authData objectForKey:@"auth_key"];
#if DEBUG
            NSLog(@"authkeydel : %@" , authKey);
#endif

        }
        return NO;
    }  else if ([requestString hasPrefix:@"hybridsetauthkey://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridsetauthkey://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
#if DEBUG
        NSLog(@"authkeyresult : %@", jsString);
#endif
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"authinfo.plist"];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"authinfo" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        [authData setObject:jsString forKey:@"auth_key"];
        [authData writeToFile:path atomically:YES];
        
        authKey = [authData objectForKey:@"auth_key"];
#if DEBUG
        NSLog(@"authkeyset : %@" , authKey);
#endif
        return NO;
    }  else if ([requestString hasPrefix:@"hybridlogout://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridlogout://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
#if DEBUG
        NSLog(@"logout : %@", jsString);
#endif
        
        if ([jsString isEqualToString:@"success"]) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:@"authinfo.plist"];
            
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath: path])
            {
                NSString *bundle = [[NSBundle mainBundle] pathForResource:@"authinfo" ofType:@"plist"];
                
                [fileManager copyItemAtPath:bundle toPath: path error:&error];
            }
            
            NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
            
            [authData setObject:@"" forKey:@"auth_key"];
            [authData writeToFile:path atomically:YES];

            [view_footer setHidden:YES];
            constraint_footer_view_height.constant = 0.0f;
            
            //[2023.09.19 취약점조치] 캐시데이터 삭제
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            [NSURLCache sharedURLCache].diskCapacity = 0;
            [NSURLCache sharedURLCache] .memoryCapacity = 0;
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/mbl/main/login_auth.jsp",MAIN_URL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
            [webView01 loadRequest:request];
            

        }
        return NO;
    }   else if ([requestString hasPrefix:@"hybridappname://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridappname://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        
        if ([jsString isEqualToString:@"ciqapp"]) {
            BOOL isInstalled = [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"mCIQ://"]];
#if DEBUG
            NSLog(@"isInstalled %d", isInstalled);
#endif
            if (!isInstalled) {
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://itunes.apple.com/app/id1460559150?mt=8"]];
            }
        }
        return NO;
    }
    else if ([requestString hasPrefix:@"hybridurl://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridurl://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        NSString *url = [NSString stringWithFormat:@"http://%@",jsString];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        return NO;
    } else if ([requestString hasPrefix:@"hybridsuburl://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridsuburl://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        NSString *url = [NSString stringWithFormat:@"%@%@",MAIN_URL,jsString];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        return NO;
    }  else if ([requestString hasPrefix:@"hybriduserid://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybriduserid://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        [DataSet sharedDataSet].userid = jsString;
        [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:fn_goMain();"];
        return NO;
    } else {
        return YES;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *currentURL = webView01.request.URL.absoluteString;
    NSLog(@"currentURL : %@",currentURL);
    
    
    if ([currentURL hasSuffix:@"/mbl/main/auto_login.jsp"]) {
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:fn_setAuthKey('%@');",authKey]];
    }
    
    NSString *status = @"";
    
    if (authKey.length != 0) {
        status = @"on";
    } else {
        status = @"off";
    }
    
    NSRange range_login;
    range_login = [currentURL rangeOfString:@"/mbl/main/login_auth.jsp"];
    
    NSRange range_main;
    range_main = [currentURL rangeOfString:@"/mbl/main/main.jsp"];
    
    if (range_login.location != NSNotFound) {
        [iv_intro setHidden:YES];
        [webView01 setHidden:NO];
        [view_footer setHidden:YES];
        constraint_footer_view_height.constant = 0.0f;
        
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:fn_setDeviceId('%@');",[OpenUDID value]]];
    } else {
        constraint_footer_view_height.constant = 52.0f;
        [view_footer setHidden:NO];
#if DEBUG
        NSLog(@"URL : %@", currentURL);
#endif
    }
    
    if ([webView01 canGoBack] && range_main.location == NSNotFound) {
        bt_prev.enabled=YES;
    } else {
        bt_prev.enabled=NO;
    }
           
    if(range_main.location != NSNotFound) {
        if ([DataSet sharedDataSet].pushDict != nil) {
            NSString *recv_id = [[DataSet sharedDataSet].pushDict objectForKey:@"userid"];
#if DEBUG
            NSLog(@"recv_id : %@",recv_id);
#endif
            if ([recv_id isEqualToString:[DataSet sharedDataSet].userid]) {
                [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - 1;
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"알림" message:[[DataSet sharedDataSet].pushDict objectForKey:@"message"] delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인",nil];
                av.tag = 99;
                [av show];
            } else {
                [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            }
        }
    }
    
    if ([webView canGoForward]) {
        bt_next.enabled=YES;
    } else {
        bt_next.enabled=NO;
    }
    
    [iv_intro setHidden:YES];
    [webView01 setHidden:NO];
    //[view_footer setHidden:YES];
    //constraint_footer_view_height.constant = 0.0f;
    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:fn_setDeviceId('%@');",[OpenUDID value]]];

    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPPushUrl('%@');",PUSH_URL]];
    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPMobileAppId('%@');",@"PLISM3"]];
    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOs('%@');",@"fcm_ios"]];
    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOsVerion('%@');",[[UIDevice currentDevice] systemVersion]]];
    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceId('%@');",[OpenUDID value]]];

    NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains(
                                                              NSDocumentDirectory,
                                                              NSUserDomainMask,
                                                              YES);

    NSString* docDir = [arrayPaths objectAtIndex:0];
    
    NSString *filePath = [docDir stringByAppendingString:@"/jpp.plist"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
#if DEBUG
    NSLog(@"Read APNS Device dict: %@", dict);
#endif
    if (dict == nil)
    {
        dict = [[NSMutableDictionary alloc] init];
    }
    
    NSString * token = [dict objectForKey:@"token"];
    
    if (token == nil)
        token = @"-1";
#if DEBUG
    NSLog(@"Read APNS Device Token: %@", token);
#endif

    [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPToken('%@');",token]];
    [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setJPPUserId();"];
    
    if ([currentURL hasSuffix:@"/mbl/main/setting.jsp"]) {
        NSLog(@"finish authkey : %@", authKey);
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:fn_initAutoLoginButton('%@','%@');",status,authKey]];
        NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSLog(@"version :%@",appversion);
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setVersion('%@');",appversion]];
        [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:pageInitPushInfo();"];
    }
    
    [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setPushList();"];
    
    

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error : %@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)bt_home:(id)sender {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/mbl/main/main.jsp", MAIN_URL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    
    [webView01 loadRequest:request];
}

- (IBAction)bt_prev:(id)sender {
     [webView01 goBack];
}

- (IBAction)bt_next:(id)sender {
    [webView01 goForward];
}

- (IBAction)bt_refresh:(id)sender {
   [webView01 reload];
}

- (IBAction)bt_top:(id)sender {
    [webView01 stringByEvaluatingJavaScriptFromString:@"goTop();"];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    float scrollPosition = [[webView01 stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] floatValue];
    
    
    //NSLog(@"scrollPosition : %f", scrollPosition);
    
    
    if (scrollPosition > (webview_height/5)) {
        [bt_top setHidden:NO];
        
    } else {
        
       [bt_top setHidden:YES];
        
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *) sourceApplication annotation:(id)annotation {
    
    return YES;
}

- (NSString *)sendDataToServer{
    __block NSString *returnValue;
    
    NSUInteger length = [MAIN_URL length];
//     /mbl/com/selectMobileHashKey.do?app_id=PLISM3&app_os=android&app_version=1
       NSString *getURL = [NSString stringWithFormat:@"%@/mbl/com/selectMobileHashKey.do?app_id=PLISM3&app_os=ios&app_version=%lu",MAIN_URL,(unsigned long)length];
    
    
    NSURL* url = [NSURL URLWithString:getURL];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSError* error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil  error:&error];
    
    if(data != nil) {
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        returnValue = [dic objectForKey:@"hash_code"];
    }
    
    return returnValue;
}


- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i=0; i < CC_MD5_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x",digest[i]];
    return output;
}
- (BOOL)checkRooting {
    BOOL returnValue = YES;
    NSArray *checkList=[NSArray arrayWithObjects:
                         @"/Applications/Cydia.app",
                         @"/Applications/RockApp.app",
                         @"/Applications/Icy.app",
                         @"/usr/sbin/sshd",
                         @"/usr/bin/sshd",
                         @"/usr/libexec/sftp-server",
                         @"/Applications/WinterBoard.app",
                         @"/Applications/SBSettings.app",
                         @"/Applications/MxTube.app",
                         @"/Applications/IntelliScreen.app",
                         @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                         @"/Applications/FakeCarrier.app",
                         @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                         @"/private/var/lib/apt",
                         @"/Applications/blackra1n.app",
                         @"/private/var/stash",
                         @"/private/var/mobile/Library/SBSettings/Themes",
                         @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                         @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                         @"/private/var/tmp/cydia.log",
                         @"/private/var/lib/cydia",
                         @"/Applications/FlyJB.app/FlyJB",
                         @"/Library/MobileSubstrate/DynamicLibraries/FlyJBX.dylib",
                         @"/Library/MobileSubstrate/DynamicLibraries/FlyJBX.plist",
                         @"/usr/lib/FJDobby",
                         @"/usr/lib/FJHooker.dylib",
                         @"/var/mobile/Library/Preferences/FJMemory",
                         nil];
    if(!TARGET_IPHONE_SIMULATOR) {
        for (NSString *filePath in checkList) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
                returnValue = NO;
                break;
            }
        }
    }
    return returnValue;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 99)
    {
        [DataSet sharedDataSet].pushDict = nil;
        if (buttonIndex == 1) {
            [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:openpushmenu();"];
        }
    } else if(alertView.tag == 100) { //vesion
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://itunes.apple.com/kr/app/PLISM3.0/id1107804633?mt=8"]];
        }
    }
}
@end
