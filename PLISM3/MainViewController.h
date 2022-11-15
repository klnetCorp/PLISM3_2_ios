//
//  MainViewController.h
//  PLISM3
//
//  Created by juis on 2016. 2. 26..
//  Copyright © 2016년 klnet. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate> {
    float webview_height;
}

@property (weak, nonatomic) IBOutlet UIView *view_footer;
@property (weak, nonatomic) IBOutlet UIImageView *iv_intro;
@property (strong, nonatomic) IBOutlet UIWebView *webView01;

@property (weak, nonatomic) IBOutlet UIButton *bt_home;
@property (weak, nonatomic) IBOutlet UIButton *bt_prev;
@property (weak, nonatomic) IBOutlet UIButton *bt_next;
@property (weak, nonatomic) IBOutlet UIButton *bt_refresh;
@property (weak, nonatomic) IBOutlet UIButton *bt_top;

@property (nonatomic, strong) NSString *authKey;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraint_footer_view_height;


- (IBAction)bt_home:(id)sender;
- (IBAction)bt_prev:(id)sender;
- (IBAction)bt_next:(id)sender;
- (IBAction)bt_refresh:(id)sender;
- (IBAction)bt_top:(id)sender;

- (void) callPush;
+ (MainViewController *)sharedMainView;

@end
