//
//  wechatTweak.mm
//  wechatTweak
//
//  Created by bx_1512 on 16/6/28.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h>
#import "MBProgressHUD.h"

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

static BOOL isAddingFriend = NO;

@interface wechatTweak : NSObject

@end

@implementation wechatTweak

-(id)init
{
	if ((self = [super init]))
	{
	}

    return self;
}

@end

#pragma mark - ----ShakeViewController
@class ShakeViewController;

CHDeclareClass(ShakeViewController);

CHOptimizedMethod(0, self, void, ShakeViewController, viewDidLoad) {
    
	CHSuper(0, ShakeViewController, viewDidLoad);
    
    UINavigationItem *navigatItem = [self performSelector:@selector(navigationItem)];
    NSArray *array = navigatItem.rightBarButtonItems;
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"多摇几次" style:UIBarButtonItemStylePlain target:self action:@selector(addShakeTimer)];
    NSMutableArray *rights = [[NSMutableArray alloc]initWithArray:array];
    [rights addObject:rightBarButtonItem];
    navigatItem.rightBarButtonItems = rights;
}

CHDeclareMethod0(void, ShakeViewController, addShakeTimer) {
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantPast] interval:8.0 target:self selector:@selector(shakeItShake) userInfo:nil repeats: YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

CHDeclareMethod0(void, ShakeViewController, shakeItShake) {
    [self performSelector:@selector(OnShake)];
    [NSThread sleepForTimeInterval:1];
    [self performSelector:@selector(onShakeStop)];
}

#pragma mark - ----ChatRoomInfoViewController
@class ChatRoomInfoViewController;

CHDeclareClass(ChatRoomInfoViewController);

CHOptimizedMethod(0, self, void, ChatRoomInfoViewController, viewDidLoad) {
    
    CHSuper(0, ChatRoomInfoViewController, viewDidLoad);
    UINavigationItem *navigatItem = [self performSelector:@selector(navigationItem)];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"一键添加" style:UIBarButtonItemStylePlain target:self action:@selector(addFriends)];
    
    navigatItem.rightBarButtonItem = rightBarButtonItem;
}

CHOptimizedMethod(2, self, void, ChatRoomInfoViewController, alertView, UIAlertView *, alertView, clickedButtonAtIndex, NSInteger, buttonIndex) {
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    if (buttonIndex == 1 && textField != nil && [alertView.title isEqualToString:@"设置验证内容"]) {
        [[NSUserDefaults standardUserDefaults]setObject:textField.text forKey:@"lastautomessage"];
        UIView *view = [self performSelector:@selector(view)];
        MBProgressHUD *hub = [[MBProgressHUD alloc] initWithView:view];
        [view addSubview: hub];
        isAddingFriend = YES;
        [hub showAnimated:YES whileExecutingBlock:^{
            
            Ivar m_arrMemberListIvar = class_getInstanceVariable(objc_getClass("ChatRoomInfoViewController"), "m_arrMemberList");
            NSArray *m_arrMemberList = object_getIvar(self, m_arrMemberListIvar);
            
            int m_arrMemberListCount = [m_arrMemberList count];
            
            int allCount = m_arrMemberListCount;
            
            for (int i = 0; i < allCount; i++) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    hub.label.text = @"正在添加";
                    hub.detailsLabel.text = [NSString stringWithFormat:@"%d/%d",i+1,allCount];
                    [self performSelector:@selector(sayHello:) withObject:@(i)];
                    
                });
                [NSThread sleepForTimeInterval: 5];
            }
            
            [[NSUserDefaults standardUserDefaults]setObject:[NSDate new] forKey:@"lastaddtime"];
            
            isAddingFriend = NO;
            
        } onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    else {
        CHSuper(2, ChatRoomInfoViewController, alertView, alertView, clickedButtonAtIndex, buttonIndex);
    }
}

CHDeclareMethod0(void, ChatRoomInfoViewController, addFriends) {
    NSDate *date = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastaddtime"];
    
    if ([[NSDate new] timeIntervalSinceDate:date] < 1) {
        int minut = ( 60*60 - ((int)[[NSDate new] timeIntervalSinceDate:date])) / 60;
        int sec =  ( 60*60 - ((int)[[NSDate new] timeIntervalSinceDate:date])) % 60;
        NSString *message = [NSString stringWithFormat:@"为你您的账户安全，该功能每小时仅能够用一次，还需等待%d分%d秒",minut,sec];
        UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"友情提示" message:message delegate:nil cancelButtonTitle:@"好的" otherButtonTitles: nil];
        [alertView show];
    } else {
        NSString *message = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastautomessage"];
        UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"设置验证内容" message:@"为避免封号，限制发送频率为5秒1个" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        [alertView setAlertViewStyle: UIAlertViewStylePlainTextInput];
        [alertView textFieldAtIndex:0].text = message;
        [alertView show];
    }
}

CHDeclareMethod1(void, ChatRoomInfoViewController, sayHello, NSNumber *, theindex) {
    Ivar m_arrMemberListIvar = class_getInstanceVariable(objc_getClass("ChatRoomInfoViewController"), "m_arrMemberList");
    NSArray *m_arrMemberList = object_getIvar(self, m_arrMemberListIvar);
    
    id contact = m_arrMemberList[[theindex intValue]];
    
    Ivar m_uiFriendSceneIvar = class_getInstanceVariable(objc_getClass("CContact"), "m_uiFriendScene");
    ptrdiff_t m_uiFriendSceneOffset = ivar_getOffset(m_uiFriendSceneIvar);
    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)contact;
    NSUInteger m_uiFriendScene = * ((NSUInteger *)(stuffBytes + m_uiFriendSceneOffset));
    
    if(m_uiFriendScene == 0) {
        id CVerifyContactWrap = [[NSClassFromString(@"CVerifyContactWrap") alloc]init];
        [CVerifyContactWrap performSelector:@selector(setM_nsUsrName:) withObject:[contact performSelector:@selector(m_nsUsrName)]];
        
        SEL setM_uiSceneMethod = @selector(setM_uiScene:);
        NSMethodSignature *setM_uiSceneSig = [[CVerifyContactWrap class] instanceMethodSignatureForSelector:setM_uiSceneMethod];
        NSInvocation *setM_uiSceneInvocatin = [NSInvocation invocationWithMethodSignature:setM_uiSceneSig];
        [setM_uiSceneInvocatin setTarget:CVerifyContactWrap];
        [setM_uiSceneInvocatin setSelector:setM_uiSceneMethod];
        [setM_uiSceneInvocatin setArgument:&m_uiFriendScene atIndex:2];
        [setM_uiSceneInvocatin invoke];
        
        [CVerifyContactWrap performSelector:@selector(setM_oVerifyContact:) withObject:contact];
        
        id chatRoomContact = [self performSelector:@selector(m_chatRoomContact)];
        
        [CVerifyContactWrap performSelector:@selector(setM_nsChatRoomUserName:) withObject:[chatRoomContact performSelector:@selector(m_nsUsrName)]];
        
        id CContactVerifyLogic = [[NSClassFromString(@"CContactVerifyLogic") alloc]init];
        [CContactVerifyLogic performSelector:@selector(setM_delegate:) withObject:self];
        
        SEL startForSendVerifyMsg = @selector(startForSendVerifyMsg:parentView:verifyMsg:);
        NSMethodSignature *startForSendVerifyMsgSig = [[CContactVerifyLogic class] instanceMethodSignatureForSelector:startForSendVerifyMsg];
        NSInvocation *startForSendVerifyMsgInvocatin = [NSInvocation invocationWithMethodSignature:startForSendVerifyMsgSig];
        [startForSendVerifyMsgInvocatin setTarget:CContactVerifyLogic];
        [startForSendVerifyMsgInvocatin setSelector:startForSendVerifyMsg];
        [startForSendVerifyMsgInvocatin setArgument:&CVerifyContactWrap atIndex:2];
        
        id view = [self performSelector:@selector(view)];
        id message = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastautomessage"];
        
        [startForSendVerifyMsgInvocatin setArgument:&view atIndex:3];
        [startForSendVerifyMsgInvocatin setArgument:&message atIndex:4];
        [startForSendVerifyMsgInvocatin invoke];
    }
}

CHDeclareMethod2(void, ChatRoomInfoViewController, contactVerifyOk, NSArray *, arg1, opCode, unsigned int, arg2) {

}

CHDeclareMethod0(void, ChatRoomInfoViewController, onContactVerifyFail) {
    
}

CHDeclareClass(UIView);

CHOptimizedMethod(1, self, void, UIView, addSubview, UIView *, subView) {
    if(isAddingFriend && [subView isKindOfClass:NSClassFromString(@"MMLoadingView")]) {
        
        return;
    }
    
    CHSuper(1, UIView, addSubview, subView);
}

static void WillEnterForeground(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // not required; for example only
}

static void ExternallyPostedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // not required; for example only
}

CHConstructor // code block that runs immediately upon load
{
	@autoreleasepool
	{
		// listen for local notification (not required; for example only)
		CFNotificationCenterRef center = CFNotificationCenterGetLocalCenter();
		CFNotificationCenterAddObserver(center, NULL, WillEnterForeground, CFSTR("UIApplicationWillEnterForegroundNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		
		// listen for system-side notification (not required; for example only)
		// this would be posted using: notify_post("xbx.wechatTweak.eventname");
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, NULL, ExternallyPostedNotification, CFSTR("xbx.wechatTweak.eventname"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		
        CHLoadLateClass(ShakeViewController);
        CHLoadLateClass(ChatRoomInfoViewController);
        CHLoadClass(UIView);
		CHHook(0, ShakeViewController, viewDidLoad);
        CHHook(0, ChatRoomInfoViewController, viewDidLoad);
        CHHook(1, UIView, addSubview);
        CHHook(2, ChatRoomInfoViewController, alertView, clickedButtonAtIndex);
	}
}
