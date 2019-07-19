//
//  CMContacts.m
//  WeexDemo
//
//  Created by yMac on 2019/7/18.
//  Copyright © 2019 taobao. All rights reserved.
//

#import "CMContacts.h"
#import <MJExtension.h>

#import <AddressBook/AddressBook.h>

//ios 9 以前的 通讯录框架
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#import <AddressBookUI/ABPersonViewController.h>
//ios 9 以后的 通讯录框架
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

@interface CMContacts () <ABPeoplePickerNavigationControllerDelegate,
CNContactPickerDelegate
>

@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, copy) CompleteBlock completeBlock;

@end

@implementation CMContacts

- (instancetype)initWithViewController:(UIViewController *)controller {
    self = [super init];
    if (self) {
        self.controller = controller;
    }
    return self;
}


- (void)selectSingle:(void (^)(NSString * _Nonnull))complete {
    
    _completeBlock = complete;
    
    if (@available(iOS 9, *)) {//ios 9 之后
        NSLog(@"ios9以后");
        [self checkAddressBookIOS9AfterAuthorization:^(bool isAuthorized) {
            if (isAuthorized) {
                //调用系统的通讯录界面
                CNContactPickerViewController *contact = [[CNContactPickerViewController alloc]init];
                contact.delegate = self;
                [self.controller presentViewController:contact animated:YES completion:nil];
            } else {
                NSDictionary *result = @{
                                         @"resultCode":@"0001",
                                         @"resultMessage":@"未授权访问通讯录",
                                         @"list":@[]
                                         };
                NSString *resultString = [result mj_JSONString];
                if (complete) {
                    complete(resultString);
                }
            }
        }];
        
    } else {
        NSLog(@"ios9之前");
        [self CheckAddressBookIOS9BeforeAuthorization:^(bool isAuthorized) {
            if (isAuthorized) {
                ABPeoplePickerNavigationController *nav = [[ABPeoplePickerNavigationController alloc] init];
                nav.peoplePickerDelegate = self;
                [self.controller presentViewController:nav animated:YES completion:nil];
            } else {
                NSDictionary *result = @{
                                         @"resultCode":@"0001",
                                         @"resultMessage":@"未授权访问通讯录",
                                         @"list":@[]
                                         };
                NSString *resultString = [result mj_JSONString];
                if (complete) {
                    complete(resultString);
                }
            }
        }];
    }
    
}

- (void)selectAll:(CompleteBlock)complete {
    
    if (@available(iOS 9, *)) {
        NSLog(@"ios 9 after");
        
        [self checkAddressBookIOS9AfterAuthorization:^(bool isAuthorized) {
            if (isAuthorized) {
                [self getIOS9AfterContactsSuccess:^(NSArray *contacts) {
                    // @[@{@"":@""}]
                    NSDictionary *result = @{
                                             @"resultCode":@"0000",
                                             @"resultMessage":@"成功",
                                             @"list":@[contacts]
                                             };
                    NSString *resultString = [result mj_JSONString];
                    if (complete) {
                        complete(resultString);
                    }
                }];
            } else {
                NSDictionary *result = @{
                                         @"resultCode":@"0001",
                                         @"resultMessage":@"未授权访问通讯录",
                                         @"list":@[]
                                         };
                NSString *resultString = [result mj_JSONString];
                if (complete) {
                    complete(resultString);
                }
            }
        }];
        
    } else {
        NSLog(@"ios 9 before");
        [self CheckAddressBookIOS9BeforeAuthorization:^(bool isAuthorized) {
            
            if (isAuthorized) {
                
                NSArray *contacts = [self getIOS9BeforeAddressBooks];
                NSDictionary *result = @{
                                         @"resultCode":@"0000",
                                         @"resultMessage":@"成功",
                                         @"list":@[contacts]
                                         };
                NSString *resultString = [result mj_JSONString];
                if (complete) {
                    complete(resultString);
                }
            } else {
                
                NSDictionary *result = @{
                                         @"resultCode":@"0001",
                                         @"resultMessage":@"未授权访问通讯录",
                                         @"list":@[]
                                         };
                NSString *resultString = [result mj_JSONString];
                if (complete) {
                    complete(resultString);
                }
            }
        }];
        
    }
}


//获取通讯录数组
- (NSArray *)getIOS9BeforeAddressBooks {
    
    NSMutableArray *peopleArray = [NSMutableArray array];
    int __block tip = 0;
    ABAddressBookRef addBook = nil;
    addBook = ABAddressBookCreateWithOptions(NULL, NULL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addBook, ^(bool greanted, CFErrorRef error){
        if (!greanted) {
            tip = 1;
        }
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (tip) {
        //        ChooseAlertShow(@"请您设置允许APP访问您的通讯录\n设置>通用>隐私");
        return nil;
    }
    
    CFArrayRef allLinkPeople = ABAddressBookCopyArrayOfAllPeople(addBook);
    CFIndex number = ABAddressBookGetPersonCount(addBook);
    for (int i = 0; i < number; i++) {
        
        ABRecordRef  people = CFArrayGetValueAtIndex(allLinkPeople, i);
        
        CFTypeRef abName = ABRecordCopyValue(people, kABPersonFirstNameProperty);
        CFTypeRef abLastName = ABRecordCopyValue(people, kABPersonLastNameProperty);
        CFStringRef abFullName = ABRecordCopyCompositeName(people);
        NSString *nameString = (__bridge NSString *)abName;
        NSString *lastNameString = (__bridge NSString *)abLastName;
        
        if ((__bridge id)abFullName != nil) {
            
            nameString = (__bridge NSString *)abFullName;
        } else {
            if ((__bridge id)abLastName != nil) {
                nameString = [NSString stringWithFormat:@"%@ %@", nameString, lastNameString];
            }
        }
        //读取电话多值
        NSString *phoneStr = @"";
        ABMultiValueRef phone = ABRecordCopyValue(people, kABPersonPhoneProperty);
        for (int k = 0; k<ABMultiValueGetCount(phone); k++) {
            //获取电话Label
            //            NSString * personPhoneLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phone, k));
            //获取該Label下的电话值
            NSString * personPhone = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phone, k);
            phoneStr = [phoneStr stringByAppendingFormat:@"%@ ",personPhone];
        }
        
        //        NSString * note = (__bridge NSString*)(ABRecordCopyValue(people, kABPersonNoteProperty));
        //
        //        NSString *email = @"";
        //        //获取email多值
        //        ABMultiValueRef emailRef = ABRecordCopyValue(people, kABPersonEmailProperty);
        //
        //        for (int x = 0; x < ABMultiValueGetCount(emailRef); x++)
        //        {
        //            //获取email Label
        //            //            NSString* emailLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(emailRef, x));
        //            //获取email值
        //            email = (__bridge NSString*)ABMultiValueCopyValueAtIndex(emailRef, x);
        //
        //
        //        }
        //        //读取jobtitle工作
        //        NSString *jobtitle = (__bridge NSString*)ABRecordCopyValue(people, kABPersonJobTitleProperty);
        //
        //        //读取nickname呢称
        //        NSString *nickname = (__bridge NSString*)ABRecordCopyValue(people, kABPersonNicknameProperty);
        //
        //        NSString * organization = (__bridge NSString*)(ABRecordCopyValue(people, kABPersonOrganizationProperty));
        //
        //        NSDate *birthDate = (__bridge NSDate *)(ABRecordCopyValue(people, kABPersonBirthdayProperty));
        //        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        //        dateFormatter.dateFormat = @"yyyy-MM-dd";
        //
        //        NSString *birthday = @"";
        //        if (birthDate) {
        //            birthday = [dateFormatter stringFromDate:birthDate];
        //        }
        //
        //        //第一次添加该条记录的时间
        //        NSDate *createDate = (__bridge NSDate*)ABRecordCopyValue(people, kABPersonCreationDateProperty);
        //        NSString *createTime = @"";
        //        if (createDate) {
        //            createTime = [dateFormatter stringFromDate:createDate];
        //        }
        //
        //        //最后一次修改該条记录的时间
        //        NSDate *modifyDate = (__bridge NSDate*)ABRecordCopyValue(people, kABPersonModificationDateProperty);
        //
        //        NSString *modifyTime = @"";
        //        if (modifyDate) {
        //            modifyTime = [dateFormatter stringFromDate:modifyDate];
        //        }
        //        //读取地址多值
        //        ABMultiValueRef address = ABRecordCopyValue(people, kABPersonAddressProperty);
        //        NSString *addressStr = @"";
        //        for(int j = 0; j < ABMultiValueGetCount(address); j++)
        //        {
        //            //获取地址Label
        //            //            NSString* addressLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(address, j);
        //
        //            //获取該label下的地址6属性
        //            NSDictionary* personaddress =(__bridge NSDictionary*) ABMultiValueCopyValueAtIndex(address, j);
        //            NSString* country = [personaddress valueForKey:(NSString *)kABPersonAddressCountryKey];
        //            if(country != nil)
        //                addressStr = [addressStr stringByAppendingFormat:@"%@ ",country];
        //            NSString* city = [personaddress valueForKey:(NSString *)kABPersonAddressCityKey];
        //            if(city != nil)
        //                addressStr = [addressStr stringByAppendingFormat:@"%@ ",city];
        //            NSString* state = [personaddress valueForKey:(NSString *)kABPersonAddressStateKey];
        //            if(state != nil)
        //                addressStr = [addressStr stringByAppendingFormat:@"%@ ",state];
        //            NSString* street = [personaddress valueForKey:(NSString *)kABPersonAddressStreetKey];
        //            if(street != nil)
        //                addressStr = [addressStr stringByAppendingFormat:@"%@ ",street];
        //            //            NSString* zip = [personaddress valueForKey:(NSString *)kABPersonAddressZIPKey];
        //            //            if(zip != nil)
        //            //                addressStr = [addressStr stringByAppendingFormat:@"邮编：%@",zip];
        //
        //        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:nameString.length != 0 ? nameString : @"" forKey:@"contactName"];
        [dict setObject:phoneStr forKey:@"phoneNum"];
        
        //        [dict setObject:email forKey:@"email"];
        //
        //        [dict setObject:organization.length != 0 ? organization : @"" forKey:@"organization"];
        //
        //        [dict setObject:addressStr forKey:@"address"];
        //
        //        [dict setObject:birthday != nil ? birthday :@"" forKey:@"birthday"];
        //
        //        [dict setObject:jobtitle.length != 0 ? jobtitle : @"" forKey:@"job_title"];
        //
        //        [dict setObject:nickname.length != 0 ? nickname : @"" forKey:@"nickname"];
        //
        //        [dict setObject:note.length != 0 ? note : @"" forKey:@"note"];
        //
        //        [dict setObject:createTime forKey:@"create_time"];
        //
        //        [dict setObject:modifyTime forKey:@"modify_time"];
        
        [peopleArray addObject:dict];
        
        if(abName) CFRelease(abName);
        if(abLastName) CFRelease(abLastName);
        if(abFullName) CFRelease(abFullName);
        if(people) CFRelease(people);
    }
    if(allLinkPeople) CFRelease(allLinkPeople);
    
    return peopleArray;
    
}

//查看是否有权限读取通讯录
- (void)CheckAddressBookIOS9BeforeAuthorization:(void (^)(bool isAuthorized))block {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    if (authStatus != kABAuthorizationStatusAuthorized) {
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                                                     
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         if (!granted){
                                                             
                                                             block(NO);
                                                         } else {
                                                             
                                                             block(YES);
                                                         }
                                                     });
                                                 });
        
    } else {
        
        block(YES);
    }
}

//ios 9 以后 使用block 返回 联系人数组
- (void)getIOS9AfterContactsSuccess:(void (^)(NSArray *))block {
    
    NSMutableArray *contacts = [NSMutableArray array];
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                CNContactStore * store = [[CNContactStore alloc] init];
                //这里写要获取的内容的key
                NSArray * keys = @[CNContactGivenNameKey, CNContactFamilyNameKey,CNContactNicknameKey, CNContactOrganizationNameKey,CNContactBirthdayKey,CNContactNoteKey,CNContactJobTitleKey,CNContactPhoneNumbersKey,CNContactEmailAddressesKey,CNContactPostalAddressesKey,CNContactDatesKey];
                CNContactFetchRequest * request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
                [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                    NSString *nameString = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];
                    NSString *phoneStr = @"";
                    for (CNLabeledValue * labelValue in contact.phoneNumbers) {
                        CNPhoneNumber * number = labelValue.value;
                        phoneStr  = [phoneStr stringByAppendingFormat:@"%@ ",number.stringValue];
                    }
                    
                    //                    NSString *email = @"";
                    //
                    //                    for (CNLabeledValue * valueStr in contact.emailAddresses) {
                    //
                    //                        NSString * emailStr = valueStr.value;
                    //
                    //                        email  = [email stringByAppendingFormat:@"%@",emailStr];
                    //                    }
                    //
                    //                    NSString *addressStr = @"";
                    //
                    //                    for (CNLabeledValue * labelValue in contact.postalAddresses) {
                    //
                    //                        CNPostalAddress * postalAddress = labelValue.value;
                    //
                    //                        addressStr = [NSString stringWithFormat:@"%@ %@ %@ %@",postalAddress.country,postalAddress.city,postalAddress.state,postalAddress.street];
                    //                    }
                    //                    NSString *nickname = contact.nickname;
                    //                    NSString *note = contact.note;
                    //                    NSString *jobtitle = contact.jobTitle;
                    //                    NSString *organization = contact.organizationName;
                    //                    NSString *birthday = @"";
                    //                    if (contact.birthday) {
                    //                        NSDateComponents *dateCom = contact.birthday;
                    //                        birthday = [NSString stringWithFormat:@"%ld-%ld-%ld",(long)dateCom.year,(long)dateCom.month,(long)dateCom.day];
                    //                    }
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setObject:nameString.length != 0 ? nameString : @"" forKey:@"contactName"];
                    [dict setObject:phoneStr forKey:@"phoneNum"];
                    
                    //                    [dict setObject:email forKey:@"email"];
                    //
                    //                    [dict setObject:organization.length != 0 ? organization : @"" forKey:@"organization"];
                    //
                    //                    [dict setObject:addressStr forKey:@"address"];
                    //
                    //                    [dict setObject:birthday.length != 0 ? birthday : @"" forKey:@"birthday"];
                    //
                    //                    [dict setObject:jobtitle.length != 0 ? jobtitle : @"" forKey:@"job_title"];
                    //
                    //                    [dict setObject:nickname.length != 0 ? nickname : @"" forKey:@"nickname"];
                    //
                    //                    [dict setObject:note.length != 0 ? note : @"" forKey:@"note"];
                    //
                    //                    [dict setObject:@"" forKey:@"create_time"];
                    //
                    //                    [dict setObject:@"" forKey:@"modify_time"];
                    
                    [contacts addObject:dict];
                    
                }];
            }
            
            block(contacts);
        }];
        
    }else{//没有权限
        
        block(contacts);
    }
}

//ios 9以后查看是否有权限读取通讯录
- (void)checkAddressBookIOS9AfterAuthorization:(void (^)(bool isAuthorized))block {
    
    CNContactStore *addressBook = [[CNContactStore alloc]init];
    CNAuthorizationStatus authStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];;
    if (authStatus != CNAuthorizationStatusAuthorized) {
        [addressBook requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error){
                    NSLog(@"ios9以后Error: %@",error);
                    if (error.code == 100) {//ios 9 以后第一次被用户拒绝访问之后就走 error 的方法
                        block(NO);
                    }
                } else if (!granted){
                    
                    block(NO);
                } else {
                    
                    block(YES);
                }
            });
        }];
    } else {
        
        block(YES);
    }
    
}


#pragma mark ABPeoplePickerNavigationControllerDelegate
//取消
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    
    NSDictionary *result = @{
                             @"resultCode":@"0001",
                             @"resultMessage":@"用户取消选择",
                             @"list":@[@{
                                       @"phoneNum":@"",
                                       @"contactName":@""
                                       }
                                   ]
                             };
    NSString *resultString = [result mj_JSONString];
    if (_completeBlock) {
        _completeBlock(resultString);
    }
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person {
    //这里有许多属性值可以带过来,参考 factory类里面的数组处理
    CFTypeRef abName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    CFTypeRef abLastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
    CFStringRef abFullName = ABRecordCopyCompositeName(person);
    NSString *nameString = (__bridge NSString *)abName;
    NSString *lastNameString = (__bridge NSString *)abLastName;
    if ((__bridge id)abFullName != nil) {
        nameString = (__bridge NSString *)abFullName;
    } else {
        if ((__bridge id)abLastName != nil) {
            nameString = [NSString stringWithFormat:@"%@%@", nameString, lastNameString];
        }
    }
    NSMutableArray * phoneArr = [[NSMutableArray alloc]init];
    ABMultiValueRef phones= ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (NSInteger j = 0; j < ABMultiValueGetCount(phones); j++) {
        
        [phoneArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j))];
    }
    
    NSString *phoneNum = @"";
    if (phoneArr.count != 0) {
        NSString *firstPhone = [phoneArr firstObject];
        if ([firstPhone rangeOfString:@"-"].location != NSNotFound) {
            
            firstPhone  = [firstPhone stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        phoneNum = firstPhone;
    }
    
    NSDictionary *result = @{
                             @"resultCode":@"0000",
                             @"resultMessage":@"成功",
                             @"list":@[@{
                                           @"phoneNum":phoneNum,
                                           @"contactName":nameString
                                       }]
                             };
    NSString *resultString = [result mj_JSONString];
    if (_completeBlock) {
        _completeBlock(resultString);
    }
    
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    
}
#pragma mark  CNContactPickerDelegate
//取消
- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    
    NSDictionary *result = @{
                             @"resultCode":@"0001",
                             @"resultMessage":@"用户取消选择",
                             @"list":@[@{
                                           @"phoneNum":@"",
                                           @"contactName":@""
                                           }
                                       ]
                             };
    NSString *resultString = [result mj_JSONString];
    if (_completeBlock) {
        _completeBlock(resultString);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//选中与取消选中时调用的方法
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    //这里有许多属性值可以带过来,参考 factory类里面的数组处理
    NSString * givenName = contact.givenName ?: @"";
    NSString * familyName = contact.familyName ?: @"";
    NSString *nameString = [NSString stringWithFormat:@"%@ %@",familyName,givenName];
    NSMutableArray *phoneArray = [NSMutableArray array];
    NSArray * tmpArr = contact.phoneNumbers;
    for (CNLabeledValue * labelValue in tmpArr) {
        
        CNPhoneNumber * number = labelValue.value;
        [phoneArray addObject:number.stringValue];
    }
    NSString *phoneNum = @"";
    if (phoneArray.count != 0) {
        NSString *firstPhone = [phoneArray firstObject];
        if ([firstPhone rangeOfString:@"-"].location != NSNotFound) {
            firstPhone  = [firstPhone stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        phoneNum = firstPhone;
    }
    NSDictionary *result = @{
                             @"resultCode":@"0000",
                             @"resultMessage":@"成功",
                             @"list":@[@{
                                           @"phoneNum":phoneNum,
                                           @"contactName":nameString
                                           }]
                             };
    NSString *resultString = [result mj_JSONString];
    if (_completeBlock) {
        _completeBlock(resultString);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
