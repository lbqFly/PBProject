//
//  GestureHandler.m
//  Demo
//
//  Created by 赖炳强 on 2018/9/10.
//  Copyright © 2018年 赖炳强. All rights reserved.
//

#import "GestureHandler.h"

@interface GestureHandler ()

@property (nonatomic, weak) UIView *view;

@end

@implementation GestureHandler {
    CGFloat _rotation;//当前选择图例旋转的角度
    CGFloat _xScale;//当前选中图例x方向的缩放量
    CGFloat _yScale;//当前选中图例y方向的缩放量
    CGFloat _tx;//当前选中图例x方向的平移量
    CGFloat _ty;//当前选中图例y方向的平移量
    NSMutableArray<UITouch *> *_touches;
}

- (instancetype)init {
    if (self = [super init]) {
        //监听是否触发home键挂起程序.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        _touchState = TouchStateNone;
        _rotation = 0.0;
        _xScale = 1.0;
        _yScale = 1.0;
        _tx = 0.0;
        _ty = 0.0;
        _touches = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    //监听是否触发home键挂起程序.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(NSNotification *)noti {
    [_touches removeAllObjects];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event View:(UIView *)view {
    self.view = view;
    
    NSMutableArray<UITouch *> *newTouches = [NSMutableArray array];
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *value;
    while (value = [enumerator nextObject]) {
        [newTouches addObject:value];
    }
    
    [_touches addObjectsFromArray:newTouches];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event CallBack:(TouchStateCallBack)callBack {
    NSAssert(touches.count != 0, @"touches not exist!");
//    NSLog(@"touches:%zd",touches.count);
    ViewTransform transform;
    transform.pan.tx = _tx;
    transform.pan.ty = _ty;
    transform.scale.xScale = _xScale;
    transform.scale.yScale = _yScale;
    transform.rotation = _rotation;
    
    NSMutableArray<UITouch *> *newTouches = [NSMutableArray array];
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *value;
    while (value = [enumerator nextObject]) {
        [newTouches addObject:value];
    }
    
    TouchState state = [self getCurrentTouchState:newTouches.copy];
    
    switch (state) {
        case TouchStatePan:
        {
            PanDistance pan = [self getTouchPanDistabce:newTouches.firstObject];
            transform.pan = pan;
        }
            break;
        case TouchStateRotation:
        {
            double rotation;
            if (newTouches.count == 1) {
                rotation = [self getTouchRotation:_touches.firstObject Touch2:newTouches.firstObject];
            }else {
                rotation = [self getTouchRotation:newTouches.firstObject Touch2:newTouches[1]];
            }
            transform.rotation = rotation;
        }
            break;
        case TouchStateScale:
        {
            ScaleDistance scale;
            if (newTouches.count == 1) {
                scale = [self getTouchScale:_touches.firstObject Touch2:newTouches.firstObject];
            }else {
                scale = [self getTouchScale:newTouches.firstObject Touch2:newTouches[1]];
            }
            transform.scale = scale;
        }
            break;
            
        default:
            break;
    }
    
    if (callBack) {
        callBack(self.touchState, transform);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableArray<UITouch *> *newTouches = [NSMutableArray array];
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *value;
    while (value = [enumerator nextObject]) {
        [newTouches addObject:value];
    }
    [_touches removeObjectsInArray:newTouches];
}

- (BOOL)touchIsRotation:(CGPoint)preP1 Point1:(CGPoint)point1 PreP2:(CGPoint)preP2 Point2:(CGPoint)point2 {
    CGFloat x1 = preP1.x - preP2.x,x2 = point1.x - point2.x;
    CGFloat y1 = preP1.y - preP2.y,y2 = point1.y - point2.y;
    
    if ((x1 * x2 + y1 * y2) / (sqrt(pow(x1,2) + pow(y1,2)) * sqrt(pow(x2,2) + pow(y2,2))) <= cos(M_PI / 240)) {
        return YES;
    }
    return NO;
}

- (TouchState)getCurrentTouchState:(NSArray<UITouch *> *)touches {
    TouchState state = TouchStateNone;
    
    if (touches.count == 1) {
        if (_touches.count == 1) {
            state = TouchStatePan;
        }else {
            UITouch *touch1 = _touches.firstObject;
            UITouch *touch2 = touches.firstObject;
            CGPoint preP1, point1, preP2, point2;
            if (@available(iOS 9.1, *)) {
                preP1 = [touch1 preciseLocationInView:self.view];
                point1 = [touch1 preciseLocationInView:self.view];
                preP2 = [touch2 precisePreviousLocationInView:self.view];
                point2 = [touch2 preciseLocationInView:self.view];
            } else {
                preP1 = [touch1 locationInView:self.view];
                point1 = [touch1 locationInView:self.view];
                preP2 = [touch2 previousLocationInView:self.view];
                point2 = [touch2 locationInView:self.view];
            }
            
            BOOL isRotation = [self touchIsRotation:preP1 Point1:point1 PreP2:preP2 Point2:point2];
            
            if (isRotation) {
                state = TouchStateRotation;
            }else {
                state = TouchStateScale;
            }
        }
    }else {
        UITouch *touch1 = touches.firstObject;
        UITouch *touch2 = touches[1];
        CGPoint preP1, point1, preP2, point2;
        if (@available(iOS 9.1, *)) {
            preP1 = [touch1 precisePreviousLocationInView:self.view];
            point1 = [touch1 preciseLocationInView:self.view];
            preP2 = [touch2 precisePreviousLocationInView:self.view];
            point2 = [touch2 preciseLocationInView:self.view];
        } else {
            preP1 = [touch1 previousLocationInView:self.view];
            point1 = [touch1 locationInView:self.view];
            preP2 = [touch2 previousLocationInView:self.view];
            point2 = [touch2 locationInView:self.view];
        }
        
        BOOL isRotation = [self touchIsRotation:preP1 Point1:point1 PreP2:preP2 Point2:point2];
        
        if (isRotation) {
            state = TouchStateRotation;
        }else {
            state = TouchStateScale;
        }
    }
    return state;
}

- (double)getTouchRotation:(UITouch *)touch1 Touch2:(UITouch *)touch2 {
    CGPoint preP1, point1, preP2, point2;
    if (@available(iOS 9.1, *)) {
        preP1 = [touch1 precisePreviousLocationInView:self.view];
        point1 = [touch1 preciseLocationInView:self.view];
        preP2 = [touch2 precisePreviousLocationInView:self.view];
        point2 = [touch2 preciseLocationInView:self.view];
    } else {
        preP1 = [touch1 previousLocationInView:self.view];
        point1 = [touch1 locationInView:self.view];
        preP2 = [touch2 previousLocationInView:self.view];
        point2 = [touch2 locationInView:self.view];
    }
    
    CGFloat x1 = preP1.x - preP2.x,x2 = point1.x - point2.x;
    CGFloat y1 = preP1.y - preP2.y,y2 = point1.y - point2.y;
    
    double rotation;
    double tempRotation = acos((x1 * x2 + y1 * y2) / (sqrt(pow(x1,2) + pow(y1,2)) * sqrt(pow(x2,2) + pow(y2,2))));
    if (x1 * y2 - x2 * y1 > 0) {
        rotation = tempRotation;
    }else {
        rotation = -tempRotation;
    }
    rotation *= 1.5;
    _rotation += rotation;
    return _rotation;
}


- (ScaleDistance)getTouchScale:(UITouch *)touch1 Touch2:(UITouch *)touch2 {
    ScaleDistance scaleDistance;
    scaleDistance.xScale = 1;
    scaleDistance.yScale = 1;

    CGPoint preP1, point1, preP2, point2;
    if (@available(iOS 9.1, *)) {
        preP1 = [touch1 precisePreviousLocationInView:self.view];
        point1 = [touch1 preciseLocationInView:self.view];
        preP2 = [touch2 precisePreviousLocationInView:self.view];
        point2 = [touch2 preciseLocationInView:self.view];
    } else {
        preP1 = [touch1 previousLocationInView:self.view];
        point1 = [touch1 locationInView:self.view];
        preP2 = [touch2 previousLocationInView:self.view];
        point2 = [touch2 locationInView:self.view];
    }
    
    double difference = sqrt(pow((point2.x - point1.x),2) + pow((point2.y - point1.y),2)) - sqrt(pow((preP1.x - preP2.x),2) + pow((preP1.y - preP2.y),2));
    double scale = difference / sqrt(pow((preP1.x - preP2.x),2) + pow((preP1.y - preP2.y),2));
    
    CGPoint vector1 ,vector2 = CGPointMake(0 * cos(_rotation) - (-1) * sin(_rotation), 0 * sin(_rotation) + (-1) * cos(_rotation));

    vector1 =CGPointMake(point1.x - point2.x, point1.y - point2.y);
    
    double cos_radio = fabs((vector1.x * vector2.x + vector1.y * vector2.y) / (sqrt(pow(vector1.x, 2) + pow(vector1.y, 2)) * sqrt(pow(vector2.x, 2) + pow(vector2.y, 2))));
    
    double xScale = scale * sqrt(1 - pow(cos_radio, 2));
    double yScale = scale * cos_radio;
    
    if (isnan(xScale)) {
        xScale = 0;
    }
    if (isnan(yScale)) {
        yScale = 0;
    }
    
    _xScale *= (xScale + 1);
    //    _xScale = MIN(_xScale, xScaleMax);
    _yScale *= (yScale + 1);
    //    _yScale = MIN(_yScale, yScaleMax);
   
    scaleDistance.xScale = _xScale;
    scaleDistance.yScale = _yScale;
    
    return scaleDistance;
}

- (PanDistance)getTouchPanDistabce:(UITouch *)touch {
    PanDistance panDistance;
    panDistance.tx = 0;
    panDistance.ty = 0;
    
    CGPoint preP,point;
    if (@available(iOS 9.1, *)) {
        preP = [touch precisePreviousLocationInView:self.view];
        point = [touch preciseLocationInView:self.view];
    } else {
        preP = [touch previousLocationInView:self.view];
        point = [touch locationInView:self.view];
    }
    
    _tx += point.x - preP.x;
    _ty += point.y - preP.y;
    panDistance.tx = _tx;
    panDistance.ty = _ty;
    return panDistance;
}

@end
