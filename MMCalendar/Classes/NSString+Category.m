//
//  NSString+Category.m
//  MMCalendar
//
//  Created by Hussein Habibi on 4/12/18.
//  Copyright © 2018 wenchaoios. All rights reserved.
//

#import "NSString+Category.h"

@implementation NSString (Category)

-(BOOL) isRTLCalendar{
    NSArray *rtlId = @[NSCalendarIdentifierIslamicCivil,NSCalendarIdentifierArabic,
                       NSCalendarIdentifierIslamicUmmAlQura,NSCalendarIdentifierIslamic];
    return [rtlId containsObject:self];
}

@end
