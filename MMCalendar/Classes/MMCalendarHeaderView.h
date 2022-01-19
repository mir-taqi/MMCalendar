//
//  MMCalendarHeader.h
//  Pods
//
//  Created by Wenchao Ding on 29/1/15.
//
//

#import <UIKit/UIKit.h>


@class MMCalendar, MMCalendarAppearance, MMCalendarHeaderLayout, MMCalendarCollectionView;

@interface MMCalendarHeaderView : UIView

@property (weak, nonatomic) MMCalendarCollectionView *collectionView;
@property (weak, nonatomic) MMCalendarHeaderLayout *collectionViewLayout;
@property (weak, nonatomic) MMCalendar *calendar;

@property (assign, nonatomic) CGFloat scrollOffset;
@property (assign, nonatomic) UICollectionViewScrollDirection scrollDirection;
@property (assign, nonatomic) BOOL scrollEnabled;
@property (assign, nonatomic) BOOL needsAdjustingViewFrame;
@property (assign, nonatomic) BOOL needsAdjustingMonthPosition;

- (void)setScrollOffset:(CGFloat)scrollOffset animated:(BOOL)animated;
- (void)reloadData;
- (void)configureAppearance;

@end


@interface MMCalendarHeaderCell : UICollectionViewCell

@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) MMCalendarHeaderView *header;

@end

@interface MMCalendarHeaderLayout : UICollectionViewFlowLayout

@end

@interface MMCalendarHeaderTouchDeliver : UIView

@property (weak, nonatomic) MMCalendar *calendar;
@property (weak, nonatomic) MMCalendarHeaderView *header;

@end
