//
//  MMCalendar+Deprecated.m
//  MMCalendar
//
//  Created by dingwenchao on 4/29/16.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

#import "MMCalendar.h"
#import "NSString+Category.h"
#import "MMCalendarExtensions.h"
#import "MMCalendarDynamicHeader.h"

#pragma mark - Deprecate

@implementation MMCalendar (Deprecated)

// identifier, lineHeightMultiplier;

- (void)setShowsPlaceholders:(BOOL)showsPlaceholders
{
    self.placeholderType = showsPlaceholders ? MMCalendarPlaceholderTypeFillSixRows : MMCalendarPlaceholderTypeNone;
}

- (BOOL)showsPlaceholders
{
    return self.placeholderType == MMCalendarPlaceholderTypeFillSixRows;
}

#pragma mark - Public methods

- (NSInteger)yearOfDate:(NSDate *)date
{
    if (!date) return NSNotFound;
    NSDateComponents *component = [self.gregorian components:NSCalendarUnitYear fromDate:date];
    return component.year;
}

- (NSInteger)monthOfDate:(NSDate *)date
{
    if (!date) return NSNotFound;
    NSDateComponents *component = [self.gregorian components:NSCalendarUnitMonth
                                                   fromDate:date];
    return component.month;
}

- (NSInteger)dayOfDate:(NSDate *)date
{
    if (!date) return NSNotFound;
    NSDateComponents *component = [self.gregorian components:NSCalendarUnitDay
                                                   fromDate:date];
    return component.day;
}

- (NSInteger)weekdayOfDate:(NSDate *)date
{
    if (!date) return NSNotFound;
    NSDateComponents *component = [self.gregorian components:NSCalendarUnitWeekday fromDate:date];
    return component.weekday;
}

- (NSInteger)weekOfDate:(NSDate *)date
{
    if (!date) return NSNotFound;
    NSDateComponents *component = [self.gregorian components:NSCalendarUnitWeekOfYear fromDate:date];
    return component.weekOfYear;
}

- (NSDate *)dateByIgnoringTimeComponentsOfDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    return [self.gregorian dateFromComponents:components];
}

- (NSDate *)tomorrowOfDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour fromDate:date];
    components.day++;
    components.hour = MMCalendarDefaultHourComponent;
    return [self.gregorian dateFromComponents:components];
}

- (NSDate *)yesterdayOfDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour fromDate:date];
    components.day--;
    components.hour = MMCalendarDefaultHourComponent;
    return [self.gregorian dateFromComponents:components];
}

- (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    NSDateComponents *components = self.components;
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = MMCalendarDefaultHourComponent;
    NSDate *date = [self.gregorian dateFromComponents:components];
    components.year = NSIntegerMax;
    components.month = NSIntegerMax;
    components.day = NSIntegerMax;
    components.hour = NSIntegerMax;
    return date;
}

- (NSDate *)dateByAddingYears:(NSInteger)years toDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = self.components;
    components.year = years;
    NSDate *d = [self.gregorian dateByAddingComponents:components toDate:date options:0];
    components.year = NSIntegerMax;
    return d;
}

- (NSDate *)dateBySubstractingYears:(NSInteger)years fromDate:(NSDate *)date
{
    if (!date) return nil;
    return [self dateByAddingYears:-years toDate:date];
}

- (NSDate *)dateByAddingMonths:(NSInteger)months toDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = self.components;
    components.month = months;
    NSDate *d = [self.gregorian dateByAddingComponents:components toDate:date options:0];
    components.month = NSIntegerMax;
    return d;
}

- (NSDate *)dateBySubstractingMonths:(NSInteger)months fromDate:(NSDate *)date
{
    return [self dateByAddingMonths:-months toDate:date];
}

- (NSDate *)dateByAddingWeeks:(NSInteger)weeks toDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = self.components;
    components.weekOfYear = weeks;
    NSDate *d = [self.gregorian dateByAddingComponents:components toDate:date options:0];
    components.weekOfYear = NSIntegerMax;
    return d;
}

- (NSDate *)dateBySubstractingWeeks:(NSInteger)weeks fromDate:(NSDate *)date
{
    return [self dateByAddingWeeks:-weeks toDate:date];
}

- (NSDate *)dateByAddingDays:(NSInteger)days toDate:(NSDate *)date
{
    if (!date) return nil;
    NSDateComponents *components = self.components;
    components.day = days;
    NSDate *d = [self.gregorian dateByAddingComponents:components toDate:date options:0];
    components.day = NSIntegerMax;
    return d;
}

- (NSDate *)dateBySubstractingDays:(NSInteger)days fromDate:(NSDate *)date
{
    return [self dateByAddingDays:-days toDate:date];
}

- (NSInteger)yearsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitYear
                                                    fromDate:fromDate
                                                      toDate:toDate
                                                     options:0];
    return components.year;
}

- (NSInteger)monthsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitMonth
                                                    fromDate:fromDate
                                                      toDate:toDate
                                                     options:0];
    return components.month;
}

- (NSInteger)weeksFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitWeekOfYear
                                                    fromDate:fromDate
                                                      toDate:toDate
                                                     options:0];
    return components.weekOfYear;
}

- (NSInteger)daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitDay
                                                    fromDate:fromDate
                                                      toDate:toDate
                                                     options:0];
    return components.day;
}

- (BOOL)isDate:(NSDate *)date1 equalToDate:(NSDate *)date2 toCalendarUnit:(MMCalendarUnit)unit
{
    switch (unit) {
        case MMCalendarUnitMonth:
            return [self.gregorian isDate:date1 equalToDate:date2 toUnitGranularity:NSCalendarUnitMonth];
        case MMCalendarUnitWeekOfYear:
            return [self.gregorian isDate:date1 equalToDate:date2 toUnitGranularity:NSCalendarUnitYear];
        case MMCalendarUnitDay:
            return [self.gregorian isDate:date1 inSameDayAsDate:date2];
    }
    return NO;
}

- (BOOL)isDateInToday:(NSDate *)date
{
    return [self isDate:date equalToDate:[NSDate date] toCalendarUnit:MMCalendarUnitDay];
}

- (void)setIdentifier:(NSString *)identifier
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:identifier];
    [self setValue:gregorian forKey:@"gregorian"];
    [self fs_performSelector:NSSelectorFromString(@"invalidateDateTools") withObjects:nil, nil];
    
    if ([[self valueForKey:@"hasValidateVisibleLayout"] boolValue]) {
        [self reloadData];
    }
    [self fs_setVariable:[self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:self.minimumDate options:0] forKey:@"_minimumDate"];
    [self fs_setVariable:[self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:self.currentPage options:0] forKey:@"_currentPage"];
    [self fs_performSelector:NSSelectorFromString(@"scrollToPageForDate:animated") withObjects:self.today, @NO, nil];
    if ([identifier isRTLCalendar]) {
        //TODO: Totall view did change the direction.
        [self setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
}

- (NSString *)identifier
{
    return self.gregorian.calendarIdentifier;
}

- (void)setLineHeightMultiplier:(CGFloat)lineHeightMultiplier
{
    self.rowHeight = MMCalendarStandardRowHeight*MAX(1, MMCalendarDeviceIsIPad*1.5);
}

@end
