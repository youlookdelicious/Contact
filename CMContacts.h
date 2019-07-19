//
//  CMContacts.h
//  WeexDemo
//
//  Created by yMac on 2019/7/18.
//  Copyright © 2019 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompleteBlock)(NSString *contactsString);

@interface CMContacts : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithViewController:(UIViewController *)controller NS_DESIGNATED_INITIALIZER;

- (void)selectSingle:(CompleteBlock)complete;
- (void)selectAll:(CompleteBlock)complete;

@end

NS_ASSUME_NONNULL_END
