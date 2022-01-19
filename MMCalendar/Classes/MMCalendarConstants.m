//
//  MMCalendarConstane.m
//  MMCalendar
//
//  Created by dingwenchao on 8/28/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//
//  https://github.com/Husseinhj
//

#import "MMCalendarConstants.h"

CGFloat const MMCalendarStandardHeaderHeight = 40;
CGFloat const MMCalendarStandardWeekdayHeight = 25;
CGFloat const MMCalendarStandardMonthlyPageHeight = 300.0;
CGFloat const MMCalendarStandardWeeklyPageHeight = 108+1/3.0;
CGFloat const MMCalendarStandardCellDiameter = 100/3.0;
CGFloat const MMCalendarStandardSeparatorThickness = 0.5;
CGFloat const MMCalendarAutomaticDimension = -1;
CGFloat const MMCalendarDefaultBounceAnimationDuration = 0.15;
CGFloat const MMCalendarStandardRowHeight = 38;
CGFloat const MMCalendarStandardTitleTextSize = 13.5;
CGFloat const MMCalendarStandardSubtitleTextSize = 10;
CGFloat const MMCalendarStandardWeekdayTextSize = 14;
CGFloat const MMCalendarStandardHeaderTextSize = 16.5;
CGFloat const MMCalendarMaximumEventDotDiameter = 4.8;
CGFloat const MMCalendarStandardScopeHandleHeight = 26;

NSInteger const MMCalendarDefaultHourComponent = 0;

NSString * const MMCalendarDefaultCellReuseIdentifier = @"_MMCalendarDefaultCellReuseIdentifier";
NSString * const MMCalendarBlankCellReuseIdentifier = @"_MMCalendarBlankCellReuseIdentifier";
NSString * const MMCalendarInvalidArgumentsExceptionName = @"Invalid argument exception";

CGPoint const CGPointInfinity = {
    .x =  CGFLOAT_MAX,
    .y =  CGFLOAT_MAX
};

CGSize const CGSizeAutomatic = {
    .width =  MMCalendarAutomaticDimension,
    .height =  MMCalendarAutomaticDimension
};



