//
//  MMCalendarDynamicHeader.h
//  Pods
//
//  Created by DingWenchao on 6/29/15.
//
//  动感头文件，仅供框架内部使用。
//  Private header, don't use it.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "MMCalendar.h"
#import "MMCalendarCell.h"
#import "MMCalendarHeaderView.h"
#import "MMCalendarStickyHeader.h"
#import "MMCalendarCollectionView.h"
#import "MMCalendarCollectionViewLayout.h"
#import "MMCalendarScopeHandle.h"
#import "MMCalendarCalculator.h"
#import "MMCalendarTransitionCoordinator.h"
#import "MMCalendarDelegationProxy.h"

@interface MMCalendar (Dynamic)

@property (readonly, nonatomic) MMCalendarCollectionView *collectionView;
@property (readonly, nonatomic) MMCalendarScopeHandle *scopeHandle;
@property (readonly, nonatomic) MMCalendarCollectionViewLayout *collectionViewLayout;
@property (readonly, nonatomic) MMCalendarTransitionCoordinator *transitionCoordinator;
@property (readonly, nonatomic) MMCalendarCalculator *calculator;
@property (readonly, nonatomic) BOOL floatingMode;
@property (readonly, nonatomic) NSArray *visibleStickyHeaders;
@property (readonly, nonatomic) CGFloat preferredHeaderHeight;
@property (readonly, nonatomic) CGFloat preferredWeekdayHeight;
@property (readonly, nonatomic) UIView *bottomBorder;

@property (readonly, nonatomic) NSCalendar *gregorian;
@property (readonly, nonatomic) NSDateComponents *components;
@property (readonly, nonatomic) NSDateFormatter *formatter;

@property (readonly, nonatomic) UIView *contentView;
@property (readonly, nonatomic) UIView *daysContainer;

@property (assign, nonatomic) BOOL needsAdjustingViewFrame;

- (void)invalidateHeaders;
- (void)adjustMonthPosition;
- (void)configureAppearance;

- (BOOL)isPageInRange:(NSDate *)page;
- (BOOL)isDateInRange:(NSDate *)date;

- (CGSize)sizeThatFits:(CGSize)size scope:(MMCalendarScope)scope;

@end

@interface MMCalendarAppearance (Dynamic)

@property (readwrite, nonatomic) MMCalendar *calendar;

@property (readonly, nonatomic) NSDictionary *backgroundColors;
@property (readonly, nonatomic) NSDictionary *titleColors;
@property (readonly, nonatomic) NSDictionary *subtitleColors;
@property (readonly, nonatomic) NSDictionary *borderColors;

@end

@interface MMCalendarWeekdayView (Dynamic)

@property (readwrite, nonatomic) MMCalendar *calendar;

@end

@interface MMCalendarCollectionViewLayout (Dynamic)

@property (readonly, nonatomic) CGSize estimatedItemSize;

@end

@interface MMCalendarDelegationProxy()<MMCalendarDataSource,MMCalendarDelegate,MMCalendarDelegateAppearance>
@end


