//
//  MMCalendarTransitionCoordinator.h
//  MMCalendar
//
//  Created by dingwenchao on 3/13/16.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

#import "MMCalendar.h"
#import "MMCalendarCollectionView.h"
#import "MMCalendarCollectionViewLayout.h"
#import "MMCalendarScopeHandle.h"

typedef NS_ENUM(NSUInteger, MMCalendarTransition) {
    MMCalendarTransitionNone,
    MMCalendarTransitionMonthToWeek,
    MMCalendarTransitionWeekToMonth
};
typedef NS_ENUM(NSUInteger, MMCalendarTransitionState) {
    MMCalendarTransitionStateIdle,
    MMCalendarTransitionStateChanging,
    MMCalendarTransitionStateFinishing,
};

@interface MMCalendarTransitionCoordinator : NSObject <UIGestureRecognizerDelegate>

@property (weak, nonatomic) MMCalendar *calendar;
@property (weak, nonatomic) MMCalendarCollectionView *collectionView;
@property (weak, nonatomic) MMCalendarCollectionViewLayout *collectionViewLayout;

@property (assign, nonatomic) MMCalendarTransition transition;
@property (assign, nonatomic) MMCalendarTransitionState state;

@property (assign, nonatomic) CGSize cachedMonthSize;

@property (readonly, nonatomic) MMCalendarScope representingScope;

- (instancetype)initWithCalendar:(MMCalendar *)calendar;

- (void)performScopeTransitionFromScope:(MMCalendarScope)fromScope toScope:(MMCalendarScope)toScope animated:(BOOL)animated;
- (void)performBoundingRectTransitionFromMonth:(NSDate *)fromMonth toMonth:(NSDate *)toMonth duration:(CGFloat)duration;

- (void)handleScopeGesture:(id)sender;

@end


@interface MMCalendarTransitionAttributes : NSObject

@property (assign, nonatomic) CGRect sourceBounds;
@property (assign, nonatomic) CGRect targetBounds;
@property (strong, nonatomic) NSDate *sourcePage;
@property (strong, nonatomic) NSDate *targetPage;
@property (assign, nonatomic) NSInteger focusedRowNumber;
@property (assign, nonatomic) NSDate *focusedDate;
@property (strong, nonatomic) NSDate *firstDayOfMonth;

@end

