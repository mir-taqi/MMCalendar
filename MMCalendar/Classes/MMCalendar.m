//
//  MMCalendar.m
//  MMCalendar
//
//  Created by Wenchao Ding on 29/1/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

#import "MMCalendar.h"
#import "NSString+Category.h"
#import "MMCalendarHeaderView.h"
#import "MMCalendarWeekdayView.h"
#import "MMCalendarStickyHeader.h"
#import "MMCalendarCollectionViewLayout.h"
#import "MMCalendarScopeHandle.h"

#import "MMCalendarExtensions.h"
#import "MMCalendarDynamicHeader.h"
#import "MMCalendarCollectionView.h"

#import "MMCalendarTransitionCoordinator.h"
#import "MMCalendarCalculator.h"
#import "MMCalendarDelegationFactory.h"

NS_ASSUME_NONNULL_BEGIN

static inline void MMCalendarAssertDateInBounds(NSDate *date, NSCalendar *calendar, NSDate *minimumDate, NSDate *maximumDate) {
    BOOL valid = YES;
    NSInteger minOffset = [calendar components:NSCalendarUnitDay fromDate:minimumDate toDate:date options:0].day;
    valid &= minOffset >= 0;
    if (valid) {
        NSInteger maxOffset = [calendar components:NSCalendarUnitDay fromDate:maximumDate toDate:date options:0].day;
        valid &= maxOffset <= 0;
    }
    if (!valid) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy/MM/dd";
        [NSException raise:@"MMCalendar date out of bounds exception" format:@"Target date %@ beyond bounds [%@ - %@]", [formatter stringFromDate:date], [formatter stringFromDate:minimumDate], [formatter stringFromDate:maximumDate]];
    }
}

NS_ASSUME_NONNULL_END

typedef NS_ENUM(NSUInteger, MMCalendarOrientation) {
    MMCalendarOrientationLandscape,
    MMCalendarOrientationPortrait
};

@interface MMCalendar ()<UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>
{
    NSMutableArray  *_selectedDates;
}

@property (strong, nonatomic) NSCalendar *gregorian;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) NSDateComponents *components;
@property (strong, nonatomic) NSTimeZone *timeZone;

@property (weak  , nonatomic) UIView                     *contentView;
@property (weak  , nonatomic) UIView                     *daysContainer;
@property (weak  , nonatomic) UIView                     *topBorder;
@property (weak  , nonatomic) UIView                     *bottomBorder;
@property (weak  , nonatomic) MMCalendarScopeHandle      *scopeHandle;
@property (weak  , nonatomic) MMCalendarCollectionView   *collectionView;
@property (weak  , nonatomic) MMCalendarCollectionViewLayout *collectionViewLayout;

@property (strong, nonatomic) MMCalendarTransitionCoordinator *transitionCoordinator;
@property (strong, nonatomic) MMCalendarCalculator       *calculator;

@property (weak  , nonatomic) MMCalendarHeaderTouchDeliver *deliver;

@property (assign, nonatomic) BOOL                       needsAdjustingViewFrame;
@property (assign, nonatomic) BOOL                       needsLayoutForWeekMode;
@property (assign, nonatomic) BOOL                       needsRequestingBoundingDates;
@property (assign, nonatomic) CGFloat                    preferredHeaderHeight;
@property (assign, nonatomic) CGFloat                    preferredWeekdayHeight;
@property (assign, nonatomic) CGFloat                    preferredRowHeight;
@property (assign, nonatomic) MMCalendarOrientation      orientation;

@property (readonly, nonatomic) BOOL floatingMode;
@property (readonly, nonatomic) BOOL hasValidateVisibleLayout;
@property (readonly, nonatomic) NSArray *visibleStickyHeaders;
@property (readonly, nonatomic) MMCalendarOrientation currentCalendarOrientation;

@property (strong, nonatomic) MMCalendarDelegationProxy  *dataSourceProxy;
@property (strong, nonatomic) MMCalendarDelegationProxy  *delegateProxy;

@property (strong, nonatomic) NSIndexPath *lastPressedIndexPath;
@property (strong, nonatomic) NSMapTable *visibleSectionHeaders;

- (void)orientationDidChange:(NSNotification *)notification;

- (CGSize)sizeThatFits:(CGSize)size scope:(MMCalendarScope)scope;

- (void)scrollToDate:(NSDate *)date;
- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated;
- (void)scrollToPageForDate:(NSDate *)date animated:(BOOL)animated;

- (BOOL)isPageInRange:(NSDate *)page;
- (BOOL)isDateInRange:(NSDate *)date;
- (BOOL)isDateSelected:(NSDate *)date;
- (BOOL)isDateInDifferentPage:(NSDate *)date;

- (void)selectDate:(NSDate *)date scrollToDate:(BOOL)scrollToDate atMonthPosition:(MMCalendarMonthPosition)monthPosition;
- (void)enqueueSelectedDate:(NSDate *)date;

- (void)invalidateDateTools;
- (void)invalidateLayout;
- (void)invalidateHeaders;
- (void)invalidateAppearanceForCell:(MMCalendarCell *)cell forDate:(NSDate *)date;

- (void)invalidateViewFrames;

- (void)handleSwipeToChoose:(UILongPressGestureRecognizer *)pressGesture;

- (void)selectCounterpartDate:(NSDate *)date;
- (void)deselectCounterpartDate:(NSDate *)date;

- (void)reloadDataForCell:(MMCalendarCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)adjustMonthPosition;
- (BOOL)requestBoundingDatesIfNecessary;
- (void)configureAppearance;

@end

@implementation MMCalendar

@dynamic selectedDate;
@synthesize scopeGesture = _scopeGesture, swipeToChooseGesture = _swipeToChooseGesture;

#pragma mark - Life Cycle && Initialize

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    if (!_appearance) {
        _appearance = [[MMCalendarAppearance alloc] init];
        _appearance.calendar = self;
    }
    
    if (!_gregorian) {
        _gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    }
   
    if (!_components) {
        _components = [[NSDateComponents alloc] init];
    }
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"yyyy-MM-dd";
    }

    if (!_locale) {
        _locale = [NSLocale currentLocale];
    }
    if (!_timeZone) {
        _timeZone = [NSTimeZone localTimeZone];
    }

    if (!_firstWeekday || _firstWeekday == 0) {
        _firstWeekday = 1;
    }
    [self invalidateDateTools];
    
    if (!_today) {
        _today = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:[NSDate date] options:0];
        _currentPage = [self.gregorian fs_firstDayOfMonth:_today];
    }
    if (!_minimumDate) {
        _minimumDate = [self.formatter dateFromString:@"1970-01-01"];
    }
    
    if (!_maximumDate) {
        _maximumDate = [self.formatter dateFromString:@"2099-12-31"];
    }
    
    _headerHeight     = MMCalendarAutomaticDimension;
    _weekdayHeight    = MMCalendarAutomaticDimension;
    _rowHeight        = MMCalendarStandardRowHeight*MAX(1, MMCalendarDeviceIsIPad*1.5);
    
    _preferredHeaderHeight  = MMCalendarAutomaticDimension;
    _preferredWeekdayHeight = MMCalendarAutomaticDimension;
    _preferredRowHeight     = MMCalendarAutomaticDimension;
    
    _scrollDirection = MMCalendarScrollDirectionHorizontal;
    _scope = MMCalendarScopeMonth;
    if (!_selectedDates) {
        _selectedDates = [NSMutableArray arrayWithCapacity:1];
    }
    if (!_visibleSectionHeaders) {
        _visibleSectionHeaders = [NSMapTable weakToWeakObjectsMapTable];
    }
    
    if (!_dataSourceProxy) {
        _pagingEnabled = YES;
        _scrollEnabled = YES;
        _needsAdjustingViewFrame = YES;
    _needsRequestingBoundingDates = YES;
    _orientation = self.currentCalendarOrientation;
    _placeholderType = MMCalendarPlaceholderTypeFillSixRows;
        
        _dataSourceProxy = [MMCalendarDelegationFactory dataSourceProxy];
        _delegateProxy = [MMCalendarDelegationFactory delegateProxy];
    }
    
    if (!self.contentView) {
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
        contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:contentView];
        self.contentView = contentView;
        
        UIView *daysContainer = [[UIView alloc] initWithFrame:CGRectZero];
        daysContainer.backgroundColor = [UIColor clearColor];
        daysContainer.clipsToBounds = YES;
        [contentView addSubview:daysContainer];
        self.daysContainer = daysContainer;
        
        if (!self.collectionViewLayout) {
            MMCalendarCollectionViewLayout *collectionViewLayout = [[MMCalendarCollectionViewLayout alloc] init];
            collectionViewLayout.calendar = self;
            
            MMCalendarCollectionView *collectionView = [[MMCalendarCollectionView alloc] initWithFrame:CGRectZero
                                                                                  collectionViewLayout:collectionViewLayout];
            collectionView.dataSource = self;
            collectionView.delegate = self;
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.pagingEnabled = YES;
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.showsVerticalScrollIndicator = NO;
            collectionView.allowsMultipleSelection = NO;
            collectionView.clipsToBounds = YES;
            [collectionView registerClass:[MMCalendarCell class] forCellWithReuseIdentifier:MMCalendarDefaultCellReuseIdentifier];
            [collectionView registerClass:[MMCalendarBlankCell class] forCellWithReuseIdentifier:MMCalendarBlankCellReuseIdentifier];
            [collectionView registerClass:[MMCalendarStickyHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
            [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"placeholderHeader"];
            [daysContainer addSubview:collectionView];
            self.collectionView = collectionView;
            self.collectionViewLayout = collectionViewLayout;
        }
    }
    
    if (!MMCalendarInAppExtension) {
        if (!self.topBorder && !self.bottomBorder) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.backgroundColor = MMCalendarStandardLineColor;
            view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin; // Stick to top
            [self addSubview:view];
            self.topBorder = view;
            
            view = [[UIView alloc] initWithFrame:CGRectZero];
            view.backgroundColor = MMCalendarStandardLineColor;
            view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin; // Stick to bottom
            [self addSubview:view];
            self.bottomBorder = view;
        }
    }
    
    [self invalidateLayout];
    
    // Assistants
    if (!self.transitionCoordinator) {
        self.transitionCoordinator = [[MMCalendarTransitionCoordinator alloc] initWithCalendar:self];
    }
    
    if (!self.calculator) {
        self.calculator = [[MMCalendarCalculator alloc] initWithCalendar:self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - Overriden methods

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (!CGRectIsEmpty(bounds) && self.transitionCoordinator.state == MMCalendarTransitionStateIdle) {
        [self invalidateViewFrames];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (!CGRectIsEmpty(frame) && self.transitionCoordinator.state == MMCalendarTransitionStateIdle) {
        [self invalidateViewFrames];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
#if !TARGET_INTERFACE_BUILDER
    if ([key hasPrefix:@"fake"]) {
        return;
    }
#endif
    if (key.length) {
        NSString *setter = [NSString stringWithFormat:@"set%@%@:",[key substringToIndex:1].uppercaseString,[key substringFromIndex:1]];
        SEL selector = NSSelectorFromString(setter);
        if ([self.appearance respondsToSelector:selector]) {
            return [self.appearance setValue:value forKey:key];
        } else if ([self.collectionViewLayout respondsToSelector:selector]) {
            return [self.collectionViewLayout setValue:value forKey:key];
        }
    }
    
    return [super setValue:value forUndefinedKey:key];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_needsAdjustingViewFrame) {
        _needsAdjustingViewFrame = NO;
        
        if (CGSizeEqualToSize(_transitionCoordinator.cachedMonthSize, CGSizeZero)) {
            _transitionCoordinator.cachedMonthSize = self.frame.size;
        }
        
        BOOL needsAdjustingBoundingRect = (self.scope == MMCalendarScopeMonth) &&
                                          (self.placeholderType != MMCalendarPlaceholderTypeFillSixRows) &&
                                          !self.hasValidateVisibleLayout;
        
        if (_scopeHandle) {
            CGFloat scopeHandleHeight = self.transitionCoordinator.cachedMonthSize.height*0.08;
            _contentView.frame = CGRectMake(0, 0, self.fs_width, self.fs_height-scopeHandleHeight);
            _scopeHandle.frame = CGRectMake(0, _contentView.fs_bottom, self.fs_width, scopeHandleHeight);
        } else {
            _contentView.frame = self.bounds;
        }

        CGFloat headerHeight = self.preferredHeaderHeight;
        CGFloat weekdayHeight = self.preferredWeekdayHeight;
        CGFloat rowHeight = self.preferredRowHeight;
        CGFloat padding = 5;
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            rowHeight = MMCalendarFloor(rowHeight*2)*0.5; // Round to nearest multiple of 0.5. e.g. (16.8->16.5),(16.2->16.0)
        }
        
        self.calendarHeaderView.frame = CGRectMake(0, 0, self.fs_width, headerHeight);
        self.calendarWeekdayView.frame = CGRectMake(0, self.calendarHeaderView.fs_bottom, self.contentView.fs_width, weekdayHeight);

        _deliver.frame = CGRectMake(self.calendarHeaderView.fs_left, self.calendarHeaderView.fs_top, self.calendarHeaderView.fs_width, headerHeight+weekdayHeight);
        _deliver.hidden = self.calendarHeaderView.hidden;
        if (!self.floatingMode) {
            switch (self.transitionCoordinator.representingScope) {
                case MMCalendarScopeMonth: {
                    CGFloat contentHeight = rowHeight*6 + padding*2;
                    CGFloat currentHeight = rowHeight*[self.calculator numberOfRowsInMonth:self.currentPage] + padding*2;
                    _daysContainer.frame = CGRectMake(0, headerHeight+weekdayHeight, self.fs_width, currentHeight);
                    _collectionView.frame = CGRectMake(0, 0, _daysContainer.fs_width, contentHeight);
                    if (needsAdjustingBoundingRect) {
                        self.transitionCoordinator.state = MMCalendarTransitionStateChanging;
                        CGRect boundingRect = (CGRect){CGPointZero,[self sizeThatFits:self.frame.size]};
                        [self.delegateProxy calendar:self boundingRectWillChange:boundingRect animated:NO];
                        self.transitionCoordinator.state = MMCalendarTransitionStateIdle;
                    }
                    break;
                }
                case MMCalendarScopeWeek: {
                    CGFloat contentHeight = rowHeight + padding*2;
                    _daysContainer.frame = CGRectMake(0, headerHeight+weekdayHeight, self.fs_width, contentHeight);
                    _collectionView.frame = CGRectMake(0, 0, _daysContainer.fs_width, contentHeight);
                    break;
                }
            }
        } else {
            
            CGFloat contentHeight = _contentView.fs_height;
            _daysContainer.frame = CGRectMake(0, 0, self.fs_width, contentHeight);
            _collectionView.frame = _daysContainer.bounds;
            
        }
        _collectionView.fs_height = MMCalendarHalfFloor(_collectionView.fs_height);
        _topBorder.frame = CGRectMake(0, -1, self.fs_width, 1);
        _bottomBorder.frame = CGRectMake(0, self.fs_height, self.fs_width, 1);
        _scopeHandle.fs_bottom = _bottomBorder.fs_top;
        
    }
    
    if (_needsLayoutForWeekMode) {
        _needsLayoutForWeekMode = NO;
        [self.transitionCoordinator performScopeTransitionFromScope:MMCalendarScopeMonth toScope:MMCalendarScopeWeek animated:NO];
    }
    
}

#if TARGET_INTERFACE_BUILDER
- (void)prepareForInterfaceBuilder
{
    NSDate *date = [NSDate date];
    NSDateComponents *components = [self.gregorian components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    components.day = _appearance.fakedSelectedDay?:1;
    [_selectedDates addObject:[self.gregorian dateFromComponents:components]];
    [self.collectionView reloadData];
}
#endif

- (CGSize)sizeThatFits:(CGSize)size
{
    switch (self.transitionCoordinator.transition) {
        case MMCalendarTransitionNone:
            return [self sizeThatFits:size scope:_scope];
        case MMCalendarTransitionWeekToMonth:
            if (self.transitionCoordinator.state == MMCalendarTransitionStateChanging) {
                return [self sizeThatFits:size scope:MMCalendarScopeMonth];
            }
        case MMCalendarTransitionMonthToWeek:
            break;
    }
    return [self sizeThatFits:size scope:MMCalendarScopeWeek];
}

- (CGSize)sizeThatFits:(CGSize)size scope:(MMCalendarScope)scope
{
    CGFloat headerHeight = self.preferredHeaderHeight;
    CGFloat weekdayHeight = self.preferredWeekdayHeight;
    CGFloat rowHeight = self.preferredRowHeight;
    CGFloat paddings = self.collectionViewLayout.sectionInsets.top + self.collectionViewLayout.sectionInsets.bottom;
    
    if (!self.floatingMode) {
        switch (scope) {
            case MMCalendarScopeMonth: {
                CGFloat height = weekdayHeight + headerHeight + [self.calculator numberOfRowsInMonth:_currentPage]*rowHeight + paddings;
                height += _scopeHandle.fs_height;
                return CGSizeMake(size.width, height);
            }
            case MMCalendarScopeWeek: {
                CGFloat height = weekdayHeight + headerHeight + rowHeight + paddings;
                height += _scopeHandle.fs_height;
                return CGSizeMake(size.width, height);
            }
        }
    } else {
        return CGSizeMake(size.width, self.fs_height);
    }
    return size;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    [self requestBoundingDatesIfNecessary];
    return self.calculator.numberOfSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.floatingMode) {
        NSInteger numberOfRows = [self.calculator numberOfRowsInSection:section];
        return numberOfRows * 7;
    }
    switch (self.transitionCoordinator.representingScope) {
        case MMCalendarScopeMonth: {
            return 42;
        }
        case MMCalendarScopeWeek: {
            return 7;
        }
    }
    return 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    
    switch (self.placeholderType) {
        case MMCalendarPlaceholderTypeNone: {
            if (self.transitionCoordinator.representingScope == MMCalendarScopeMonth && monthPosition != MMCalendarMonthPositionCurrent) {
                UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MMCalendarBlankCellReuseIdentifier forIndexPath:indexPath];
                if([self isArabicCalender]){
                    cell.accessibilityLanguage = @"Arabic";
//                    [cell setTransform:CGAffineTransformMakeScale(-1,1)];
                } else if ([cell.accessibilityLanguage isEqualToString:@"Arabic"]) {
                    cell.accessibilityLanguage = @"English";
//                    [cell setTransform:CGAffineTransformMakeScale(-1,1)];
                }
                
                return cell;
            }
            break;
        }
        case MMCalendarPlaceholderTypeFillHeadTail: {
            if (self.transitionCoordinator.representingScope == MMCalendarScopeMonth) {
                if (indexPath.item >= 7 * [self.calculator numberOfRowsInSection:indexPath.section]) {
                    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MMCalendarBlankCellReuseIdentifier forIndexPath:indexPath];
                    if ([self isArabicCalender]) {
                        cell.accessibilityLanguage = @"Arabic";
//                        [cell setTransform:CGAffineTransformMakeScale(-1,1)];
                    } else if ([cell.accessibilityLanguage isEqualToString:@"Arabic"]) {
                        cell.accessibilityLanguage = @"English";
//                        [cell setTransform:CGAffineTransformMakeScale(-1,1)];
                    }
                    return cell;
                }
            }
            break;
        }
        case MMCalendarPlaceholderTypeFillSixRows: {
            break;
        }
    }

    NSDate *date = [self.calculator dateForIndexPath:indexPath];
    MMCalendarCell *cell = [self.dataSourceProxy calendar:self cellForDate:date atMonthPosition:monthPosition];
    if (!cell) {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:MMCalendarDefaultCellReuseIdentifier forIndexPath:indexPath];
    }
    [self reloadDataForCell:cell atIndexPath:indexPath];
    if ([self isArabicCalender]) {
        cell.accessibilityLanguage = @"Arabic";
//        [cell setTransform:CGAffineTransformMakeScale(-1,1)];
//        cell.titleLabel.text = [self convertEnNumberToFarsi:cell.titleLabel.text];
    } else if ([cell.accessibilityLanguage isEqualToString:@"Arabic"]) {
        cell.accessibilityLanguage = @"English";
//        [cell setTransform:CGAffineTransformMakeScale(-1,1)];
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (self.floatingMode) {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            MMCalendarStickyHeader *stickyHeader = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
            stickyHeader.calendar = self;
            if ([self isArabicCalender]) {
                stickyHeader.accessibilityLanguage = @"Arabic";
//                [stickyHeader setTransform:CGAffineTransformMakeScale(-1,1)];
            } else if ([stickyHeader.accessibilityLanguage isEqualToString:@"Arabic"]) {
                stickyHeader.accessibilityLanguage = @"English";
//                [stickyHeader setTransform:CGAffineTransformMakeScale(-1,1)];
            }
            
            stickyHeader.month = [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:indexPath.section toDate:[self.gregorian fs_firstDayOfMonth:_minimumDate] options:0];
            self.visibleSectionHeaders[indexPath] = stickyHeader;
            [stickyHeader setNeedsLayout];
            return stickyHeader;
        }
    }
    return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"placeholderHeader" forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if (self.floatingMode) {
        if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            self.visibleSectionHeaders[indexPath] = nil;
        }
    }
}

#pragma mark - <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    if (self.placeholderType == MMCalendarPlaceholderTypeNone && monthPosition != MMCalendarMonthPositionCurrent) {
        return NO;
    }
    NSDate *date = [self.calculator dateForIndexPath:indexPath];
    return [self isDateInRange:date] && (![self.delegateProxy respondsToSelector:@selector(calendar:shouldSelectDate:atMonthPosition:)] || [self.delegateProxy calendar:self shouldSelectDate:date atMonthPosition:monthPosition]);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *selectedDate = [self.calculator dateForIndexPath:indexPath];
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    MMCalendarCell *cell;
    if (monthPosition == MMCalendarMonthPositionCurrent) {
        cell = (MMCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
    } else {
        cell = [self cellForDate:selectedDate atMonthPosition:MMCalendarMonthPositionCurrent];
        NSIndexPath *indexPath = [collectionView indexPathForCell:cell];
        if (indexPath) {
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
    if (![_selectedDates containsObject:selectedDate]) {
        cell.selected = YES;
        [cell performSelecting];
    }
    [self enqueueSelectedDate:selectedDate];
    [self.delegateProxy calendar:self didSelectDate:selectedDate atMonthPosition:monthPosition];
    [self selectCounterpartDate:selectedDate];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    if (self.placeholderType == MMCalendarPlaceholderTypeNone && monthPosition != MMCalendarMonthPositionCurrent) {
        return NO;
    }
    NSDate *date = [self.calculator dateForIndexPath:indexPath];
    return [self isDateInRange:date] && (![self.delegateProxy respondsToSelector:@selector(calendar:shouldDeselectDate:atMonthPosition:)]||[self.delegateProxy calendar:self shouldDeselectDate:date atMonthPosition:monthPosition]);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *selectedDate = [self.calculator dateForIndexPath:indexPath];
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    MMCalendarCell *cell;
    if (monthPosition == MMCalendarMonthPositionCurrent) {
        cell = (MMCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
    } else {
        cell = [self cellForDate:selectedDate atMonthPosition:MMCalendarMonthPositionCurrent];
        NSIndexPath *indexPath = [collectionView indexPathForCell:cell];
        if (indexPath) {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
    cell.selected = NO;
    [cell configureAppearance];
    
    [_selectedDates removeObject:selectedDate];
    [self.delegateProxy calendar:self didDeselectDate:selectedDate atMonthPosition:monthPosition];
    [self deselectCounterpartDate:selectedDate];
    
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![cell isKindOfClass:[MMCalendarCell class]]) {
        return;
    }
    NSDate *date = [self.calculator dateForIndexPath:indexPath];
    MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    [self.delegateProxy calendar:self willDisplayCell:(MMCalendarCell *)cell forDate:date atMonthPosition:monthPosition];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.window) return;
    if (self.floatingMode && _collectionView.indexPathsForVisibleItems.count) {
        // Do nothing on bouncing
        if (_collectionView.contentOffset.y < 0 || _collectionView.contentOffset.y > _collectionView.contentSize.height-_collectionView.fs_height) {
            return;
        }
        NSDate *currentPage = _currentPage;
        CGPoint significantPoint = CGPointMake(_collectionView.fs_width*0.5,MIN(self.collectionViewLayout.estimatedItemSize.height*2.75, _collectionView.fs_height*0.5)+_collectionView.contentOffset.y);
        NSIndexPath *significantIndexPath = [_collectionView indexPathForItemAtPoint:significantPoint];
        if (significantIndexPath) {
            currentPage = [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:significantIndexPath.section toDate:[self.gregorian fs_firstDayOfMonth:_minimumDate] options:0];
        } else {
            MMCalendarStickyHeader *significantHeader = [self.visibleStickyHeaders filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MMCalendarStickyHeader * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                return CGRectContainsPoint(evaluatedObject.frame, significantPoint);
            }]].firstObject;
            if (significantHeader) {
                currentPage = significantHeader.month;
            }
        }
        
        if (![self.gregorian isDate:currentPage equalToDate:_currentPage toUnitGranularity:NSCalendarUnitMonth]) {
            [self willChangeValueForKey:@"currentPage"];
            _currentPage = currentPage;
            [self.delegateProxy calendarCurrentPageDidChange:self];
            [self didChangeValueForKey:@"currentPage"];
        }
        
    } else if (self.hasValidateVisibleLayout) {
        CGFloat scrollOffset = 0;
        switch (_collectionViewLayout.scrollDirection) {
            case UICollectionViewScrollDirectionHorizontal: {
                scrollOffset = scrollView.contentOffset.x/scrollView.fs_width;
                break;
            }
            case UICollectionViewScrollDirectionVertical: {
                scrollOffset = scrollView.contentOffset.y/scrollView.fs_height;
                break;
            }
        }
        _calendarHeaderView.scrollOffset = scrollOffset;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (!_pagingEnabled || !_scrollEnabled) {
        return;
    }
    CGFloat targetOffset = 0, contentSize = 0;
    switch (_collectionViewLayout.scrollDirection) {
        case UICollectionViewScrollDirectionHorizontal: {
            targetOffset = targetContentOffset->x;
            contentSize = scrollView.fs_width;
            break;
        }
        case UICollectionViewScrollDirectionVertical: {
            targetOffset = targetContentOffset->y;
            contentSize = scrollView.fs_height;
            break;
        }
    }
    
    NSInteger sections = lrint(targetOffset/contentSize);
    NSDate *targetPage = nil;
    switch (_scope) {
        case MMCalendarScopeMonth: {
            NSDate *minimumPage = [self.gregorian fs_firstDayOfMonth:_minimumDate];
            targetPage = [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:sections toDate:minimumPage options:0];
            break;
        }
        case MMCalendarScopeWeek: {
            NSDate *minimumPage = [self.gregorian fs_firstDayOfWeek:_minimumDate];
            targetPage = [self.gregorian dateByAddingUnit:NSCalendarUnitWeekOfYear value:sections toDate:minimumPage options:0];
            break;
        }
    }
    BOOL shouldTriggerPageChange = [self isDateInDifferentPage:targetPage];
    if (shouldTriggerPageChange) {
        NSDate *lastPage = _currentPage;
        [self willChangeValueForKey:@"currentPage"];
        _currentPage = targetPage;
        [self.delegateProxy calendarCurrentPageDidChange:self];
        if (_placeholderType != MMCalendarPlaceholderTypeFillSixRows) {
            [self.transitionCoordinator performBoundingRectTransitionFromMonth:lastPage toMonth:_currentPage duration:0.25];
        }
        [self didChangeValueForKey:@"currentPage"];
    }
    
    // Disable all inner gestures to avoid missing event
    [scrollView.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != scrollView.panGestureRecognizer) {
            obj.enabled = NO;
        }
    }];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Recover all disabled gestures
    [scrollView.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != scrollView.panGestureRecognizer) {
            obj.enabled = YES;
        }
    }];
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Notification

- (void)orientationDidChange:(NSNotification *)notification
{
    self.orientation = self.currentCalendarOrientation;
}

#pragma mark - Properties

- (void)setCalendarIdentifier:(NSString *)identifier{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:identifier];
    if ([identifier isRTLCalendar]) {
        //TODO: Totall view did change the direction.
        self.accessibilityLanguage = @"Arabic";
//        [self setTransform:CGAffineTransformMakeScale(-1,1)];
    } else if ([self.accessibilityLanguage isEqualToString:@"Arabic"]) {
        self.accessibilityLanguage = @"English";
//        [self setTransform:CGAffineTransformMakeScale(-1,1)];
    }
    
    _today = [calendar dateBySettingHour:0 minute:0 second:0 ofDate:[NSDate date] options:0];
    
    self.gregorian = calendar;
    _currentPage = [calendar fs_firstDayOfMonth:_today];
    
    [self invalidateDateTools];
    [self configureAppearance];
    if (self.hasValidateVisibleLayout) {
        [self invalidateHeaders];
    }
}

- (NSString *)calendarIdentifier{
    return self.gregorian.calendarIdentifier;
}

- (void)setScrollDirection:(MMCalendarScrollDirection)scrollDirection
{
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        
        if (self.floatingMode) return;
        
        switch (_scope) {
            case MMCalendarScopeMonth: {
                _collectionViewLayout.scrollDirection = (UICollectionViewScrollDirection)scrollDirection;
                _calendarHeaderView.scrollDirection = _collectionViewLayout.scrollDirection;
                if (self.hasValidateVisibleLayout) {
                    [_collectionView reloadData];
                    [_calendarHeaderView reloadData];
                }
                _needsAdjustingViewFrame = YES;
                [self setNeedsLayout];
                break;
            }
            case MMCalendarScopeWeek: {
                break;
            }
        }
    }
}

+ (BOOL)automaticallyNotifiesObserversOfScope
{
    return NO;
}

- (void)setScope:(MMCalendarScope)scope
{
    [self setScope:scope animated:NO];
}

- (void)setFirstWeekday:(NSUInteger)firstWeekday
{
    if (_firstWeekday != firstWeekday) {
        _firstWeekday = firstWeekday;
        _needsRequestingBoundingDates = YES;
        [self invalidateDateTools];
        [self invalidateHeaders];
        [self.collectionView reloadData];
        [self configureAppearance];
        
        [self invalidateLayout];
    }
}

- (void)setToday:(NSDate *)today
{
    if (!today) {
        _today = nil;
    } else {
        MMCalendarAssertDateInBounds(today,self.gregorian,self.minimumDate,self.maximumDate);
        _today = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:today options:0];
    }
    if (self.hasValidateVisibleLayout) {
        [self.visibleCells makeObjectsPerformSelector:@selector(setDateIsToday:) withObject:nil];
        if (today) [[_collectionView cellForItemAtIndexPath:[self.calculator indexPathForDate:today]] setValue:@YES forKey:@"dateIsToday"];
        [self.visibleCells makeObjectsPerformSelector:@selector(configureAppearance)];
    }
}

- (void)setCurrentPage:(NSDate *)currentPage
{
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSDate *)currentPage animated:(BOOL)animated
{
    [self requestBoundingDatesIfNecessary];
    if (self.floatingMode || [self isDateInDifferentPage:currentPage]) {
        currentPage = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:currentPage options:0];
        if ([self isPageInRange:currentPage]) {
            [self scrollToPageForDate:currentPage animated:animated];
        }
    }
}

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier
{
    if (!identifier.length) {
        [NSException raise:MMCalendarInvalidArgumentsExceptionName format:@"This identifier must not be nil and must not be an empty string."];
    }
    if (![cellClass isSubclassOfClass:[MMCalendarCell class]]) {
        [NSException raise:@"The cell class must be a subclass of MMCalendarCell." format:@""];
    }
    if ([identifier isEqualToString:MMCalendarBlankCellReuseIdentifier]) {
        [NSException raise:MMCalendarInvalidArgumentsExceptionName format:@"Do not use %@ as the cell reuse identifier.", identifier];
    }
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];

}

- (MMCalendarCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier forDate:(NSDate *)date atMonthPosition:(MMCalendarMonthPosition)position;
{
    if (!identifier.length) {
        [NSException raise:MMCalendarInvalidArgumentsExceptionName format:@"This identifier must not be nil and must not be an empty string."];
    }
    NSIndexPath *indexPath = [self.calculator indexPathForDate:date atMonthPosition:position];
    if (!indexPath) {
        [NSException raise:MMCalendarInvalidArgumentsExceptionName format:@"Attempting to dequeue a cell with invalid date."];
    }
    MMCalendarCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

- (nullable MMCalendarCell *)cellForDate:(NSDate *)date atMonthPosition:(MMCalendarMonthPosition)position
{
    NSIndexPath *indexPath = [self.calculator indexPathForDate:date atMonthPosition:position];
    return (MMCalendarCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}

- (NSDate *)dateForCell:(MMCalendarCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    return [self.calculator dateForIndexPath:indexPath];
}

- (MMCalendarMonthPosition)monthPositionForCell:(MMCalendarCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    return [self.calculator monthPositionForIndexPath:indexPath];
}

- (NSArray<MMCalendarCell *> *)visibleCells
{
    return [self.collectionView.visibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[MMCalendarCell class]];
    }]];
}

- (CGRect)frameForDate:(NSDate *)date
{
    if (!self.superview) {
        return CGRectZero;
    }
    CGRect frame = [_collectionViewLayout layoutAttributesForItemAtIndexPath:[self.calculator indexPathForDate:date]].frame;
    frame = [self.superview convertRect:frame fromView:_collectionView];
    return frame;
}

- (void)setHeaderHeight:(CGFloat)headerHeight
{
    if (_headerHeight != headerHeight) {
        _headerHeight = headerHeight;
        _needsAdjustingViewFrame = YES;
        [self setNeedsLayout];
    }
}

- (void)setWeekdayHeight:(CGFloat)weekdayHeight
{
    if (_weekdayHeight != weekdayHeight) {
        _weekdayHeight = weekdayHeight;
        _needsAdjustingViewFrame = YES;
        [self setNeedsLayout];
    }
}

- (void)setLocale:(NSLocale *)locale
{
    if (![_locale isEqual:locale]) {
        _locale = locale.copy;
        [self invalidateDateTools];
        [self configureAppearance];
        if (self.hasValidateVisibleLayout) {
            [self invalidateHeaders];
        }
    }
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _collectionView.allowsMultipleSelection = allowsMultipleSelection;
}

- (BOOL)allowsMultipleSelection
{
    return _collectionView.allowsMultipleSelection;
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
    _collectionView.allowsSelection = allowsSelection;
}

- (BOOL)allowsSelection
{
    return _collectionView.allowsSelection;
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
    if (_pagingEnabled != pagingEnabled) {
        _pagingEnabled = pagingEnabled;
        
        [self invalidateLayout];
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    if (_scrollEnabled != scrollEnabled) {
        _scrollEnabled = scrollEnabled;
        
        _collectionView.scrollEnabled = scrollEnabled;
        _calendarHeaderView.scrollEnabled = scrollEnabled;
        
        [self invalidateLayout];
    }
}

- (void)setOrientation:(MMCalendarOrientation)orientation
{
    if (_orientation != orientation) {
        _orientation = orientation;
        
        _needsAdjustingViewFrame = YES;
        _preferredWeekdayHeight = MMCalendarAutomaticDimension;
        _preferredRowHeight = MMCalendarAutomaticDimension;
        _preferredHeaderHeight = MMCalendarAutomaticDimension;
        _calendarHeaderView.needsAdjustingMonthPosition = YES;
        _calendarHeaderView.needsAdjustingViewFrame = YES;
        [self setNeedsLayout];
    }
}

- (NSDate *)selectedDate
{
    return _selectedDates.lastObject;
}

- (NSArray *)selectedDates
{
    return [NSArray arrayWithArray:_selectedDates];
}

- (CGFloat)preferredHeaderHeight
{
    if (_headerHeight == MMCalendarAutomaticDimension) {
        if (_preferredWeekdayHeight == MMCalendarAutomaticDimension) {
            if (!self.floatingMode) {
                CGFloat DIYider = MMCalendarStandardMonthlyPageHeight;
                CGFloat contentHeight = self.transitionCoordinator.cachedMonthSize.height*(1-_showsScopeHandle*0.08);
                _preferredHeaderHeight = (MMCalendarStandardHeaderHeight/DIYider)*contentHeight;
                _preferredHeaderHeight -= (_preferredHeaderHeight-MMCalendarStandardHeaderHeight)*0.5;
            } else {
                _preferredHeaderHeight = MMCalendarStandardHeaderHeight*MAX(1, MMCalendarDeviceIsIPad*1.5);
            }
        }
        return _preferredHeaderHeight;
    }
    return _headerHeight;
}

- (CGFloat)preferredWeekdayHeight
{
    if (_weekdayHeight == MMCalendarAutomaticDimension) {
        if (_preferredWeekdayHeight == MMCalendarAutomaticDimension) {
            if (!self.floatingMode) {
                CGFloat DIYider = MMCalendarStandardMonthlyPageHeight;
                CGFloat contentHeight = self.transitionCoordinator.cachedMonthSize.height*(1-_showsScopeHandle*0.08);
                _preferredWeekdayHeight = (MMCalendarStandardWeekdayHeight/DIYider)*contentHeight;
            } else {
                _preferredWeekdayHeight = MMCalendarStandardWeekdayHeight*MAX(1, MMCalendarDeviceIsIPad*1.5);
            }
        }
        return _preferredWeekdayHeight;
    }
    return _weekdayHeight;
}

- (CGFloat)preferredRowHeight
{
    if (_preferredRowHeight == MMCalendarAutomaticDimension) {
        CGFloat headerHeight = self.preferredHeaderHeight;
        CGFloat weekdayHeight = self.preferredWeekdayHeight;
        CGFloat contentHeight = self.transitionCoordinator.cachedMonthSize.height-headerHeight-weekdayHeight-_scopeHandle.fs_height;
        CGFloat padding = 5;
        if (!self.floatingMode) {
            _preferredRowHeight = (contentHeight-padding*2)/6.0;
        } else {
            _preferredRowHeight = _rowHeight;
        }
    }
    return _preferredRowHeight;
}

- (BOOL)floatingMode
{
    return _scope == MMCalendarScopeMonth && _scrollEnabled && !_pagingEnabled;
}

- (void)setShowsScopeHandle:(BOOL)showsScopeHandle
{
    if (_showsScopeHandle != showsScopeHandle) {
        _showsScopeHandle = showsScopeHandle;
        [self invalidateLayout];
    }
}

- (UIPanGestureRecognizer *)scopeGesture
{
    if (!_scopeGesture) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self.transitionCoordinator action:@selector(handleScopeGesture:)];
        panGesture.delegate = self.transitionCoordinator;
        panGesture.minimumNumberOfTouches = 1;
        panGesture.maximumNumberOfTouches = 2;
        panGesture.enabled = NO;
        [self.daysContainer addGestureRecognizer:panGesture];
        _scopeGesture = panGesture;
    }
    return _scopeGesture;
}

- (UILongPressGestureRecognizer *)swipeToChooseGesture
{
    if (!_swipeToChooseGesture) {
        UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToChoose:)];
        pressGesture.enabled = NO;
        pressGesture.numberOfTapsRequired = 0;
        pressGesture.numberOfTouchesRequired = 1;
        pressGesture.minimumPressDuration = 0.7;
        [self.daysContainer addGestureRecognizer:pressGesture];
        [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:pressGesture];
        _swipeToChooseGesture = pressGesture;
    }
    return _swipeToChooseGesture;
}

- (void)setDataSource:(id<MMCalendarDataSource>)dataSource
{
    self.dataSourceProxy.delegation = dataSource;
}

- (id<MMCalendarDataSource>)dataSource
{
    return self.dataSourceProxy.delegation;
}

- (void)setDelegate:(id<MMCalendarDelegate>)delegate
{
    self.delegateProxy.delegation = delegate;
}

- (id<MMCalendarDelegate>)delegate
{
    return self.delegateProxy.delegation;
}

#pragma mark - Public methods

- (void)reloadData
{
    _needsRequestingBoundingDates = YES;
    if ([self requestBoundingDatesIfNecessary] || !self.collectionView.indexPathsForVisibleItems.count) {
        [self invalidateHeaders];
    }
    [self.collectionView reloadData];
}

- (void)setScope:(MMCalendarScope)scope animated:(BOOL)animated
{
    if (self.floatingMode) return;
    if (self.transitionCoordinator.state != MMCalendarTransitionStateIdle) return;
    
    MMCalendarScope prevScope = _scope;
    [self willChangeValueForKey:@"scope"];
    _scope = scope;
    [self didChangeValueForKey:@"scope"];
    
    if (prevScope == scope) return;
    
    if (!self.hasValidateVisibleLayout && prevScope == MMCalendarScopeMonth && scope == MMCalendarScopeWeek) {
        _needsLayoutForWeekMode = YES;
        [self setNeedsLayout];
    } else if (self.transitionCoordinator.state == MMCalendarTransitionStateIdle) {
        [self.transitionCoordinator performScopeTransitionFromScope:prevScope toScope:scope animated:animated];
    }

}

- (void)setPlaceholderType:(MMCalendarPlaceholderType)placeholderType
{
    if (_placeholderType != placeholderType) {
        _placeholderType = placeholderType;
        if (self.hasValidateVisibleLayout) {
            _preferredRowHeight = MMCalendarAutomaticDimension;
            [_collectionView reloadData];
        }
    }
}

- (void)selectDate:(NSDate *)date
{
    [self selectDate:date scrollToDate:YES];
}

- (void)selectDate:(NSDate *)date scrollToDate:(BOOL)scrollToDate
{
    [self selectDate:date scrollToDate:scrollToDate atMonthPosition:MMCalendarMonthPositionCurrent];
}

- (void)deselectDate:(NSDate *)date
{
    date = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];
    if (![_selectedDates containsObject:date]) {
        return;
    }
    [_selectedDates removeObject:date];
    [self deselectCounterpartDate:date];
    NSIndexPath *indexPath = [self.calculator indexPathForDate:date];
    if ([_collectionView.indexPathsForSelectedItems containsObject:indexPath]) {
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
        MMCalendarCell *cell = (MMCalendarCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        cell.selected = NO;
        [cell configureAppearance];
    }
}

- (void)selectDate:(NSDate *)date scrollToDate:(BOOL)scrollToDate atMonthPosition:(MMCalendarMonthPosition)monthPosition
{
    if (!self.allowsSelection || !date) return;
        
    [self requestBoundingDatesIfNecessary];
    
    MMCalendarAssertDateInBounds(date,self.gregorian,self.minimumDate,self.maximumDate);
    
    NSDate *targetDate = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];
    NSIndexPath *targetIndexPath = [self.calculator indexPathForDate:targetDate];
    
    BOOL shouldSelect = YES;
    // 跨月份点击
    if (monthPosition==MMCalendarMonthPositionPrevious||monthPosition==MMCalendarMonthPositionNext) {
        if (self.allowsMultipleSelection) {
            if ([self isDateSelected:targetDate]) {
                BOOL shouldDeselect = ![self.delegateProxy respondsToSelector:@selector(calendar:shouldDeselectDate:atMonthPosition:)] || [self.delegateProxy calendar:self shouldDeselectDate:targetDate atMonthPosition:monthPosition];
                if (!shouldDeselect) {
                    return;
                }
            } else {
                shouldSelect &= (![self.delegateProxy respondsToSelector:@selector(calendar:shouldSelectDate:atMonthPosition:)] || [self.delegateProxy calendar:self shouldSelectDate:targetDate atMonthPosition:monthPosition]);
                if (!shouldSelect) {
                    return;
                }
                [_collectionView selectItemAtIndexPath:targetIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                [self collectionView:_collectionView didSelectItemAtIndexPath:targetIndexPath];
            }
        } else {
            shouldSelect &= (![self.delegateProxy respondsToSelector:@selector(calendar:shouldSelectDate:atMonthPosition:)] || [self.delegateProxy calendar:self shouldSelectDate:targetDate atMonthPosition:monthPosition]);
            if (shouldSelect) {
                if ([self isDateSelected:targetDate]) {
                    [self.delegateProxy calendar:self didSelectDate:targetDate atMonthPosition:monthPosition];
                } else {
                    NSDate *selectedDate = self.selectedDate;
                    if (selectedDate) {
                        [self deselectDate:selectedDate];
                    }
                    [_collectionView selectItemAtIndexPath:targetIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                    [self collectionView:_collectionView didSelectItemAtIndexPath:targetIndexPath];
                }
            } else {
                return;
            }
        }
        
    } else if (![self isDateSelected:targetDate]){
        if (self.selectedDate && !self.allowsMultipleSelection) {
            [self deselectDate:self.selectedDate];
        }
        [_collectionView selectItemAtIndexPath:targetIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        MMCalendarCell *cell = (MMCalendarCell *)[_collectionView cellForItemAtIndexPath:targetIndexPath];
        [cell performSelecting];
        [self enqueueSelectedDate:targetDate];
        [self selectCounterpartDate:targetDate];
        
    } else if (![_collectionView.indexPathsForSelectedItems containsObject:targetIndexPath]) {
        [_collectionView selectItemAtIndexPath:targetIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    if (scrollToDate) {
        if (!shouldSelect) {
            return;
        }
        [self scrollToPageForDate:targetDate animated:YES];
    }
}

- (void)handleScopeGesture:(UIPanGestureRecognizer *)sender
{
    if (self.floatingMode) return;
    [self.transitionCoordinator handleScopeGesture:sender];
}

#pragma mark - Private methods

- (void)scrollToDate:(NSDate *)date
{
    [self scrollToDate:date animated:NO];
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated
{
    if (!_minimumDate || !_maximumDate) {
        return;
    }
    animated &= _scrollEnabled; // No animation if _scrollEnabled == NO;
    
    date = [self.calculator safeDateForDate:date];
    NSInteger scrollOffset = [self.calculator indexPathForDate:date atMonthPosition:MMCalendarMonthPositionCurrent].section;
    
    if (!self.floatingMode) {
        switch (_collectionViewLayout.scrollDirection) {
            case UICollectionViewScrollDirectionVertical: {
                [_collectionView setContentOffset:CGPointMake(0, scrollOffset * _collectionView.fs_height) animated:animated];
                break;
            }
            case UICollectionViewScrollDirectionHorizontal: {
                [_collectionView setContentOffset:CGPointMake(scrollOffset * _collectionView.fs_width, 0) animated:animated];
                break;
            }
        }
        
    } else if (self.hasValidateVisibleLayout) {
        [_collectionViewLayout layoutAttributesForElementsInRect:_collectionView.bounds];
        CGRect headerFrame = [_collectionViewLayout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:scrollOffset]].frame;
        CGPoint targetOffset = CGPointMake(0, MIN(headerFrame.origin.y,MAX(0,_collectionViewLayout.collectionViewContentSize.height-_collectionView.fs_bottom)));
        [_collectionView setContentOffset:targetOffset animated:animated];
    }
    if (!animated) {
        self.calendarHeaderView.scrollOffset = scrollOffset;
    }
}

- (void)scrollToPageForDate:(NSDate *)date animated:(BOOL)animated
{
    if (!date) return;
    if (![self isDateInRange:date]) {
        date = [self.calculator safeDateForDate:date];
        if (!date) return;
    }
    
    if (!self.floatingMode) {
        if ([self isDateInDifferentPage:date]) {
            [self willChangeValueForKey:@"currentPage"];
            NSDate *lastPage = _currentPage;
            switch (self.transitionCoordinator.representingScope) {
                case MMCalendarScopeMonth: {
                    _currentPage = [self.gregorian fs_firstDayOfMonth:date];
                    break;
                }
                case MMCalendarScopeWeek: {
                    _currentPage = [self.gregorian fs_firstDayOfWeek:date];
                    break;
                }
            }
            if (self.hasValidateVisibleLayout) {
                [self.delegateProxy calendarCurrentPageDidChange:self];
                if (_placeholderType != MMCalendarPlaceholderTypeFillSixRows && self.transitionCoordinator.state == MMCalendarTransitionStateIdle) {
                    [self.transitionCoordinator performBoundingRectTransitionFromMonth:lastPage toMonth:_currentPage duration:0.33];
                }
            }
            [self didChangeValueForKey:@"currentPage"];
        }
        [self scrollToDate:_currentPage animated:animated];
    } else {
        [self scrollToDate:[self.gregorian fs_firstDayOfMonth:date] animated:animated];
    }
}


- (BOOL)isDateInRange:(NSDate *)date
{
    BOOL flag = YES;
    flag &= [self.gregorian components:NSCalendarUnitDay fromDate:date toDate:self.minimumDate options:0].day <= 0;
    flag &= [self.gregorian components:NSCalendarUnitDay fromDate:date toDate:self.maximumDate options:0].day >= 0;;
    return flag;
}

- (BOOL)isPageInRange:(NSDate *)page
{
    BOOL flag = YES;
    switch (self.transitionCoordinator.representingScope) {
        case MMCalendarScopeMonth: {
            NSDateComponents *c1 = [self.gregorian components:NSCalendarUnitDay fromDate:[self.gregorian fs_firstDayOfMonth:self.minimumDate] toDate:page options:0];
            flag &= (c1.day>=0);
            if (!flag) break;
            NSDateComponents *c2 = [self.gregorian components:NSCalendarUnitDay fromDate:page toDate:[self.gregorian fs_lastDayOfMonth:self.maximumDate] options:0];
            flag &= (c2.day>=0);
            break;
        }
        case MMCalendarScopeWeek: {
            NSDateComponents *c1 = [self.gregorian components:NSCalendarUnitDay fromDate:[self.gregorian fs_firstDayOfWeek:self.minimumDate] toDate:page options:0];
            flag &= (c1.day>=0);
            if (!flag) break;
            NSDateComponents *c2 = [self.gregorian components:NSCalendarUnitDay fromDate:page toDate:[self.gregorian fs_lastDayOfWeek:self.maximumDate] options:0];
            flag &= (c2.day>=0);
            break;
        }
        default:
            break;
    }
    return flag;
}

- (BOOL)isDateSelected:(NSDate *)date
{
    return [_selectedDates containsObject:date] || [_collectionView.indexPathsForSelectedItems containsObject:[self.calculator indexPathForDate:date]];
}

- (BOOL)isDateInDifferentPage:(NSDate *)date
{
    if (self.floatingMode) {
        return ![self.gregorian isDate:date equalToDate:_currentPage toUnitGranularity:NSCalendarUnitMonth];
    }
    switch (_scope) {
        case MMCalendarScopeMonth:
            return ![self.gregorian isDate:date equalToDate:_currentPage toUnitGranularity:NSCalendarUnitMonth];
        case MMCalendarScopeWeek:
            return ![self.gregorian isDate:date equalToDate:_currentPage toUnitGranularity:NSCalendarUnitWeekOfYear];
    }
}

- (BOOL)hasValidateVisibleLayout
{
#if TARGET_INTERFACE_BUILDER
    return YES;
#else
    return self.superview  && !CGRectIsEmpty(_collectionView.frame) && !CGSizeEqualToSize(_collectionViewLayout.collectionViewContentSize, CGSizeZero);
#endif
}

- (void)invalidateDateTools
{
    _gregorian.locale = _locale;
    _gregorian.timeZone = _timeZone;
    _gregorian.firstWeekday = _firstWeekday;
    _components.calendar = _gregorian;
    _components.timeZone = _timeZone;
    _formatter.calendar = _gregorian;
    _formatter.timeZone = _timeZone;
    _formatter.locale = _locale;
}

- (void)invalidateLayout
{
    if (!self.floatingMode) {
        
        if (!_calendarHeaderView) {
            
            MMCalendarHeaderView *headerView = [[MMCalendarHeaderView alloc] initWithFrame:CGRectZero];
            headerView.scrollEnabled = _scrollEnabled;
            [_contentView addSubview:headerView];
            self.calendarHeaderView = headerView;
        }
        self.calendarHeaderView.calendar = self;
        
        if (!_calendarWeekdayView) {
            MMCalendarWeekdayView *calendarWeekdayView = [[MMCalendarWeekdayView alloc] initWithFrame:CGRectZero];
            calendarWeekdayView.calendar = self;
            [_contentView addSubview:calendarWeekdayView];
            _calendarWeekdayView = calendarWeekdayView;
        }
        
        if (_scrollEnabled) {
            if (!_deliver) {
                MMCalendarHeaderTouchDeliver *deliver = [[MMCalendarHeaderTouchDeliver alloc] initWithFrame:CGRectZero];
                deliver.header = _calendarHeaderView;
                deliver.calendar = self;
                [_contentView addSubview:deliver];
                self.deliver = deliver;
            }
        } else if (_deliver) {
            [_deliver removeFromSuperview];
        }
        
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        if (self.showsScopeHandle) {
            if (!_scopeHandle) {
                MMCalendarScopeHandle *handle = [[MMCalendarScopeHandle alloc] initWithFrame:CGRectZero];
                handle.calendar = self;
                [self addSubview:handle];
                self.scopeHandle = handle;
                _needsAdjustingViewFrame = YES;
                [self setNeedsLayout];
            }
        } else {
            if (_scopeHandle) {
                [self.scopeHandle removeFromSuperview];
                _needsAdjustingViewFrame = YES;
                [self setNeedsLayout];
            }
        }
#pragma GCC diagnostic pop
        
        _collectionView.pagingEnabled = YES;
        _collectionViewLayout.scrollDirection = (UICollectionViewScrollDirection)self.scrollDirection;
        
    } else {
        
        [self.calendarHeaderView removeFromSuperview];
        [self.deliver removeFromSuperview];
        [self.calendarWeekdayView removeFromSuperview];
        [self.scopeHandle removeFromSuperview];
        
        _collectionView.pagingEnabled = NO;
        _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
    }
    
    _preferredHeaderHeight = MMCalendarAutomaticDimension;
    _preferredWeekdayHeight = MMCalendarAutomaticDimension;
    _preferredRowHeight = MMCalendarAutomaticDimension;
    _needsAdjustingViewFrame = YES;
    [self setNeedsLayout];
}

- (void)invalidateHeaders
{
    [self.calendarHeaderView.collectionView reloadData];
    [self.visibleStickyHeaders makeObjectsPerformSelector:@selector(configureAppearance)];
}

- (void)invalidateAppearanceForCell:(MMCalendarCell *)cell forDate:(NSDate *)date
{
#define MMCalendarInvalidateCellAppearance(SEL1,SEL2) \
    cell.SEL1 = [self.delegateProxy calendar:self appearance:self.appearance SEL2:date];
    
#define MMCalendarInvalidateCellAppearanceWithDefault(SEL1,SEL2,DEFAULT) \
    if ([self.delegateProxy respondsToSelector:@selector(calendar:appearance:SEL2:)]) { \
        cell.SEL1 = [self.delegateProxy calendar:self appearance:self.appearance SEL2:date]; \
    } else { \
        cell.SEL1 = DEFAULT; \
    }
    
    MMCalendarInvalidateCellAppearance(preferredFillDefaultColor,fillDefaultColorForDate);
    MMCalendarInvalidateCellAppearance(preferredFillSelectionColor,fillSelectionColorForDate);
    MMCalendarInvalidateCellAppearance(preferredTitleDefaultColor,titleDefaultColorForDate);
    MMCalendarInvalidateCellAppearance(preferredTitleSelectionColor,titleSelectionColorForDate);

    MMCalendarInvalidateCellAppearanceWithDefault(preferredTitleOffset,titleOffsetForDate,CGPointInfinity);
    if (cell.subtitle) {
        MMCalendarInvalidateCellAppearance(preferredSubtitleDefaultColor,subtitleDefaultColorForDate);
        MMCalendarInvalidateCellAppearance(preferredSubtitleSelectionColor,subtitleSelectionColorForDate);
        MMCalendarInvalidateCellAppearanceWithDefault(preferredSubtitleOffset,subtitleOffsetForDate,CGPointInfinity);
    }
    if (cell.numberOfEvents) {
        MMCalendarInvalidateCellAppearance(preferredEventDefaultColors,eventDefaultColorsForDate);
        MMCalendarInvalidateCellAppearance(preferredEventSelectionColors,eventSelectionColorsForDate);
        MMCalendarInvalidateCellAppearanceWithDefault(preferredEventOffset,eventOffsetForDate,CGPointInfinity);
    }
    MMCalendarInvalidateCellAppearance(preferredBorderDefaultColor,borderDefaultColorForDate);
    MMCalendarInvalidateCellAppearance(preferredBorderSelectionColor,borderSelectionColorForDate);
    MMCalendarInvalidateCellAppearanceWithDefault(preferredBorderRadius,borderRadiusForDate,-1);

    if (cell.image) {
        MMCalendarInvalidateCellAppearanceWithDefault(preferredImageOffset,imageOffsetForDate,CGPointInfinity);
    }
    
#undef MMCalendarInvalidateCellAppearance
#undef MMCalendarInvalidateCellAppearanceWithDefault
    
}
-(NSString*)arabicToWestern:(NSString *)numericString {
    NSMutableString *s = [NSMutableString stringWithString:numericString];
    NSString *arabic = @"١٢٣٤٥٦٧٨٩٠";
    NSString *western = @"1234567890";
    for (uint i = 0; i<arabic.length; i++) {
        NSString *a = [arabic substringWithRange:NSMakeRange(i, 1)];
        NSString *w = [western substringWithRange:NSMakeRange(i, 1)];
        [s replaceOccurrencesOfString:a withString:w
                              options:NSCaseInsensitiveSearch
                                range:NSMakeRange(0, s.length)];
    }
    return [NSString stringWithString:s];
}
-(NSString*)westernToArabic:(NSString *)numericString {
    NSMutableString *s = [NSMutableString stringWithString:numericString];
    NSString *arabic = @"1234567890";
    NSString *western = @"١٢٣٤٥٦٧٨٩٠";
    for (uint i = 0; i<arabic.length; i++) {
        NSString *a = [arabic substringWithRange:NSMakeRange(i, 1)];
        NSString *w = [western substringWithRange:NSMakeRange(i, 1)];
        [s replaceOccurrencesOfString:a withString:w
                              options:NSCaseInsensitiveSearch
                                range:NSMakeRange(0, s.length)];
    }
    return [NSString stringWithString:s];
}
- (void)reloadDataForCell:(MMCalendarCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.calendar = self;
    NSDate *date = [self.calculator dateForIndexPath:indexPath];
    cell.image = [self.dataSourceProxy calendar:self imageForDate:date];
    cell.numberOfEvents = [self.dataSourceProxy calendar:self numberOfEventsForDate:date];
    cell.titleLabel.text = [self.dataSourceProxy calendar:self titleForDate:date] ?: @([self.gregorian component:NSCalendarUnitDay fromDate:date]).stringValue;
    if (!_isLanguageRTL){
    cell.titleLabel.text = [self westernToArabic:cell.titleLabel.text];
    }
    cell.subtitle  = [self.dataSourceProxy calendar:self subtitleForDate:date];
    cell.selected = [_selectedDates containsObject:date];
    cell.dateIsToday = self.today?[self.gregorian isDate:date inSameDayAsDate:self.today]:NO;
    cell.weekend = [self.gregorian isDateInWeekend:date];
    cell.monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
    switch (self.transitionCoordinator.representingScope) {
        case MMCalendarScopeMonth: {
            cell.placeholder = (cell.monthPosition == MMCalendarMonthPositionPrevious || cell.monthPosition == MMCalendarMonthPositionNext) || ![self isDateInRange:date];
            if (cell.placeholder) {
                cell.selected &= _pagingEnabled;
                cell.dateIsToday &= _pagingEnabled;
            }
            break;
        }
        case MMCalendarScopeWeek: {
            cell.placeholder = ![self isDateInRange:date];
            break;
        }
    }
    // Synchronize selecion state to the collection view, otherwise delegate methods would not be triggered.
    if (cell.selected) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    [self invalidateAppearanceForCell:cell forDate:date];
    [cell configureAppearance];
}


- (void)handleSwipeToChoose:(UILongPressGestureRecognizer *)pressGesture
{
    switch (pressGesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[pressGesture locationInView:self.collectionView]];
            if (indexPath && ![indexPath isEqual:self.lastPressedIndexPath]) {
                NSDate *date = [self.calculator dateForIndexPath:indexPath];
                MMCalendarMonthPosition monthPosition = [self.calculator monthPositionForIndexPath:indexPath];
                if (![self.selectedDates containsObject:date] && [self collectionView:self.collectionView shouldSelectItemAtIndexPath:indexPath]) {
                    [self selectDate:date scrollToDate:NO atMonthPosition:monthPosition];
                    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
                } else if (self.collectionView.allowsMultipleSelection && [self collectionView:self.collectionView shouldDeselectItemAtIndexPath:indexPath]) {
                    [self deselectDate:date];
                    [self collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath];
                }
            }
            self.lastPressedIndexPath = indexPath;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.lastPressedIndexPath = nil;
            break;
        }
        default:
            break;
    }
   
}

- (void)selectCounterpartDate:(NSDate *)date
{
    if (_placeholderType == MMCalendarPlaceholderTypeNone) return;
    if (self.scope == MMCalendarScopeWeek) return;
    NSInteger numberOfDays = [self.gregorian fs_numberOfDaysInMonth:date];
    NSInteger day = [self.gregorian component:NSCalendarUnitDay fromDate:date];
    MMCalendarCell *cell;
    if (day < numberOfDays/2+1) {
        cell = [self cellForDate:date atMonthPosition:MMCalendarMonthPositionNext];
    } else {
        cell = [self cellForDate:date atMonthPosition:MMCalendarMonthPositionPrevious];
    }
    if (cell) {
        cell.selected = YES;
        if (self.collectionView.allowsMultipleSelection) {   
            [self.collectionView selectItemAtIndexPath:[self.collectionView indexPathForCell:cell] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
    [cell configureAppearance];
}

- (void)deselectCounterpartDate:(NSDate *)date
{
    if (_placeholderType == MMCalendarPlaceholderTypeNone) return;
    if (self.scope == MMCalendarScopeWeek) return;
    NSInteger numberOfDays = [self.gregorian fs_numberOfDaysInMonth:date];
    NSInteger day = [self.gregorian component:NSCalendarUnitDay fromDate:date];
    MMCalendarCell *cell;
    if (day < numberOfDays/2+1) {
        cell = [self cellForDate:date atMonthPosition:MMCalendarMonthPositionNext];
    } else {
        cell = [self cellForDate:date atMonthPosition:MMCalendarMonthPositionPrevious];
    }
    if (cell) {
        cell.selected = NO;
        [self.collectionView deselectItemAtIndexPath:[self.collectionView indexPathForCell:cell] animated:NO];
    }
    [cell configureAppearance];
}

- (void)enqueueSelectedDate:(NSDate *)date
{
    if (!self.allowsMultipleSelection) {
        [_selectedDates removeAllObjects];
    }
    if (![_selectedDates containsObject:date]) {
        [_selectedDates addObject:date];
    }
}

- (NSArray *)visibleStickyHeaders
{
    return [self.visibleSectionHeaders.dictionaryRepresentation allValues];
}

- (void)invalidateViewFrames
{
    _needsAdjustingViewFrame = YES;
    
    _preferredHeaderHeight  = MMCalendarAutomaticDimension;
    _preferredWeekdayHeight = MMCalendarAutomaticDimension;
    _preferredRowHeight     = MMCalendarAutomaticDimension;
    
    [self.calendarHeaderView setNeedsAdjustingViewFrame:YES];
    [self setNeedsLayout];
    
}

// The best way to detect orientation
// http://stackoverflow.com/questions/25830448/what-is-the-best-way-to-detect-orientation-in-an-app-extension/26023538#26023538
- (MMCalendarOrientation)currentCalendarOrientation
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize nativeSize = [UIScreen mainScreen].currentMode.size;
    CGSize sizeInPoints = [UIScreen mainScreen].bounds.size;
    MMCalendarOrientation orientation = scale * sizeInPoints.width == nativeSize.width ? MMCalendarOrientationPortrait : MMCalendarOrientationLandscape;
    return orientation;
}

- (void)adjustMonthPosition
{
    [self requestBoundingDatesIfNecessary];
    NSDate *targetPage = self.pagingEnabled?self.currentPage:(self.currentPage?:self.selectedDate);
    [self scrollToPageForDate:targetPage animated:NO];
    self.calendarHeaderView.needsAdjustingMonthPosition = YES;
}

- (BOOL)requestBoundingDatesIfNecessary
{
    if (_needsRequestingBoundingDates) {
        _needsRequestingBoundingDates = NO;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        
        self.formatter.dateFormat = @"yyyy-MM-dd";
        NSDate *newMin = [self.dataSourceProxy minimumDateForCalendar:self]?:[dateFormatter dateFromString:@"1970-01-01"];
        newMin = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:newMin options:0];
        NSDate *newMax = [self.dataSourceProxy maximumDateForCalendar:self]?:[dateFormatter dateFromString:@"2099-12-31"];
        newMax = [self.gregorian dateBySettingHour:0 minute:0 second:0 ofDate:newMax options:0];
        
        NSAssert([self.gregorian compareDate:newMin toDate:newMax toUnitGranularity:NSCalendarUnitDay] != NSOrderedDescending, @"The minimum date of calendar should be earlier than the maximum.");
        
        BOOL res = ![self.gregorian isDate:newMin inSameDayAsDate:_minimumDate] || ![self.gregorian isDate:newMax inSameDayAsDate:_maximumDate];
        _minimumDate = newMin;
        _maximumDate = newMax;
        [self.calculator reloadSections];
        
        return res;
    }
    return NO;
}

- (void)configureAppearance
{
    [self.visibleCells makeObjectsPerformSelector:@selector(configureAppearance)];
    [self.visibleStickyHeaders makeObjectsPerformSelector:@selector(configureAppearance)];
    [self.calendarHeaderView configureAppearance];
    [self.calendarWeekdayView configureAppearance];
}

-(NSString *)convertEnNumberToFarsi:(NSString *) number{
    NSString *text;
    NSDecimalNumber *someNumber = [NSDecimalNumber decimalNumberWithString:number];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:self.locale];
    text = [formatter stringFromNumber:someNumber];
    return text;
}

-(BOOL) isArabicCalender{
    return [self.calendarIdentifier isRTLCalendar];
}

@end


