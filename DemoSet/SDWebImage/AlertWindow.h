//
//  AlertWindow.h
//  DemoSet
//
//  Created by CaoFeng on 17/3/10.
//  Copyright © 2017年 深圳中业兴融互联网金融服务有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)();

@interface AlertWindow : UIWindow

- (instancetype)initWithFrame:(CGRect)frame completionBlock:(CompletionBlock)completionBlock;

@end
