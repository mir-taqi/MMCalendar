//
//  MMCalendarScopeHandle.h
//  MMCalendar
//
//  Created by dingwenchao on 4/29/16.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMCalendar;

@interface MMCalendarScopeHandle : UIView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UIPanGestureRecognizer *panGesture;
@property (weak, nonatomic) MMCalendar *calendar;

- (void)handlePan:(id)sender;

@end
