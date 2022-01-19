//
//  MMCalendarDelegationFactory.h
//  MMCalendar
//
//  Created by dingwenchao on 19/12/2016.
//  Copyright © 2016 wenchaoios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMCalendarDelegationProxy.h"

@interface MMCalendarDelegationFactory : NSObject

+ (MMCalendarDelegationProxy *)dataSourceProxy;
+ (MMCalendarDelegationProxy *)delegateProxy;

@end
