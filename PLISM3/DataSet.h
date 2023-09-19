//
//  DataSet.h
//  MGW
//
//  Created by user on 11. 3. 18..
//  Copyright 2011 juis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define MAIN_URL @"https://test.plism.com"
//#define MAIN_URL @"https://www.plism.com"
//#define MAIN_URL @"http://192.168.2.2:8082"

#define PUSH_URL @"https://testpush.plism.com"
//#define PUSH_URL @"https://push.plism.com"


@interface DataSet : NSObject {
    
}

@property(nonatomic) Boolean isLogin;
@property(nonatomic) Boolean isBackground;
@property(nonatomic, strong) NSDictionary *pushDict;
@property (nonatomic, strong) NSString *userid;
@property (nonatomic, strong) NSString *deviceTokenID;

+(DataSet *)sharedDataSet;

@end
