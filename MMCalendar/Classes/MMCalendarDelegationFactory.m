//
//  MMCalendarDelegationFactory.m
//  MMCalendar
//
//  Created by dingwenchao on 19/12/2016.
//  Copyright © 2016 wenchaoios. All rights reserved.
//

#import "MMCalendarDelegationFactory.h"

#define MMCalendarSelectorEntry(SEL1,SEL2) NSStringFromSelector(@selector(SEL1)):NSStringFromSelector(@selector(SEL2))

@implementation MMCalendarDelegationFactory

+ (MMCalendarDelegationProxy *)dataSourceProxy
{
    MMCalendarDelegationProxy *delegation = [[MMCalendarDelegationProxy alloc] init];
    delegation.protocol = @protocol(MMCalendarDataSource);
    delegation.deprecations = @{MMCalendarSelectorEntry(calendar:numberOfEventsForDate:, calendar:hasEventForDate:)};
    return delegation;
}

+ (MMCalendarDelegationProxy *)delegateProxy
{
    MMCalendarDelegationProxy *delegation = [[MMCalendarDelegationProxy alloc] init];
    delegation.protocol = @protocol(MMCalendarDelegateAppearance);
    delegation.deprecations = @{
                                MMCalendarSelectorEntry(calendarCurrentPageDidChange:, calendarCurrentMonthDidChange:),
                                MMCalendarSelectorEntry(calendar:shouldSelectDate:atMonthPosition:, calendar:shouldSelectDate:),
                                MMCalendarSelectorEntry(calendar:didSelectDate:atMonthPosition:, calendar:didSelectDate:),
                                MMCalendarSelectorEntry(calendar:shouldDeselectDate:atMonthPosition:, calendar:shouldDeselectDate:),
                                MMCalendarSelectorEntry(calendar:didDeselectDate:atMonthPosition:, calendar:didDeselectDate:)
                               };
    return delegation;
}

@end

#undef MMCalendarSelectorEntry

