//
//  MMCalendarConstane.h
//  MMCalendar
//
//  Created by dingwenchao on 8/28/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//
//  https://github.com/Husseinhj
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - Constants

CG_EXTERN CGFloat const MMCalendarStandardHeaderHeight;
CG_EXTERN CGFloat const MMCalendarStandardWeekdayHeight;
CG_EXTERN CGFloat const MMCalendarStandardMonthlyPageHeight;
CG_EXTERN CGFloat const MMCalendarStandardWeeklyPageHeight;
CG_EXTERN CGFloat const MMCalendarStandardCellDiameter;
CG_EXTERN CGFloat const MMCalendarStandardSeparatorThickness;
CG_EXTERN CGFloat const MMCalendarAutomaticDimension;
CG_EXTERN CGFloat const MMCalendarDefaultBounceAnimationDuration;
CG_EXTERN CGFloat const MMCalendarStandardRowHeight;
CG_EXTERN CGFloat const MMCalendarStandardTitleTextSize;
CG_EXTERN CGFloat const MMCalendarStandardSubtitleTextSize;
CG_EXTERN CGFloat const MMCalendarStandardWeekdayTextSize;
CG_EXTERN CGFloat const MMCalendarStandardHeaderTextSize;
CG_EXTERN CGFloat const MMCalendarMaximumEventDotDiameter;
CG_EXTERN CGFloat const MMCalendarStandardScopeHandleHeight;

UIKIT_EXTERN NSInteger const MMCalendarDefaultHourComponent;

UIKIT_EXTERN NSString * const MMCalendarDefaultCellReuseIdentifier;
UIKIT_EXTERN NSString * const MMCalendarBlankCellReuseIdentifier;
UIKIT_EXTERN NSString * const MMCalendarInvalidArgumentsExceptionName;

CG_EXTERN CGPoint const CGPointInfinity;
CG_EXTERN CGSize const CGSizeAutomatic;

#if TARGET_INTERFACE_BUILDER
#define MMCalendarDeviceIsIPad NO
#else
#define MMCalendarDeviceIsIPad [[UIDevice currentDevice].model hasPrefix:@"iPad"]
#endif

#define MMCalendarStandardSelectionColor   FSColorRGBA(31,119,219,1.0)
#define MMCalendarStandardTodayColor       FSColorRGBA(198,51,42 ,1.0)
#define MMCalendarStandardTitleTextColor   FSColorRGBA(14,69,221 ,1.0)
#define MMCalendarStandardEventDotColor    FSColorRGBA(31,119,219,0.75)

#define MMCalendarStandardLineColor        [[UIColor lightGrayColor] colorWithAlphaComponent:0.30]
#define MMCalendarStandardSeparatorColor   [[UIColor lightGrayColor] colorWithAlphaComponent:0.60]
#define MMCalendarStandardScopeHandleColor [[UIColor lightGrayColor] colorWithAlphaComponent:0.50]

#define FSColorRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define MMCalendarInAppExtension [[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]

#define MMCalendarFloor(c) floorf(c)
#define MMCalendarRound(c) roundf(c)
#define MMCalendarCeil(c) ceilf(c)
#define MMCalendarMod(c1,c2) fmodf(c1,c2)

#define MMCalendarHalfRound(c) (MMCalendarRound(c*2)*0.5)
#define MMCalendarHalfFloor(c) (MMCalendarFloor(c*2)*0.5)
#define MMCalendarHalfCeil(c) (MMCalendarCeil(c*2)*0.5)

#define MMCalendarUseWeakSelf __weak __typeof__(self) MMCalendarWeakSelf = self;
#define MMCalendarUseStrongSelf __strong __typeof__(self) self = MMCalendarWeakSelf;


#pragma mark - Deprecated

#define MMCalendarDeprecated(instead) DEPRECATED_MSG_ATTRIBUTE(" Use " # instead " instead")

MMCalendarDeprecated('borderRadius')
typedef NS_ENUM(NSUInteger, MMCalendarCellShape) {
    MMCalendarCellShapeCircle    = 0,
    MMCalendarCellShapeRectangle = 1
};

typedef NS_ENUM(NSUInteger, MMCalendarUnit) {
    MMCalendarUnitMonth = NSCalendarUnitMonth,
    MMCalendarUnitWeekOfYear = NSCalendarUnitWeekOfYear,
    MMCalendarUnitDay = NSCalendarUnitDay
};

static inline void MMCalendarSliceCake(CGFloat cake, NSInteger count, CGFloat *pieces) {
    CGFloat total = cake;
    for (int i = 0; i < count; i++) {
        NSInteger remains = count - i;
        CGFloat piece = MMCalendarRound(total/remains*2)*0.5;
        total -= piece;
        pieces[i] = piece;
    }
}



