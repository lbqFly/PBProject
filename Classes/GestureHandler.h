//
//  GestureHandler.h
//  Demo
//
//  Created by 赖炳强 on 2018/9/10.
//  Copyright © 2018年 赖炳强. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 手势枚举
 
 - TouchStateNone: TouchStateNone
 - TouchStatePan: 平移手势
 - TouchStateRotation: 旋转手势
 - TouchStateScale: 缩放手势
 */
typedef NS_ENUM(NSInteger, TouchState) {
    TouchStateNone = 0,
    TouchStatePan,
    TouchStateRotation,
    TouchStateScale,
};

/**
 平移手势结构体
 */
typedef struct  {
    CGFloat tx;
    CGFloat ty;
}PanDistance;

/**
 缩放手势结构体
 */
typedef struct  {
    CGFloat xScale;
    CGFloat yScale;
}ScaleDistance;

/**
 view的state结构体
 */
typedef struct  {
    PanDistance pan;
    ScaleDistance scale;
    CGFloat rotation;
}ViewTransform;

/**
 当前手势状态回调
 
 @param touchState 手势
 */
typedef void(^TouchStateCallBack)(TouchState touchState, ViewTransform viewTransform);


@interface GestureHandler : NSObject

@property (nonatomic, assign) TouchState touchState;

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event View:(UIView *)view;

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event CallBack:(TouchStateCallBack)callBack;

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

@end
