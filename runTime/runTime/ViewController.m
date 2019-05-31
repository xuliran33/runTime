//
//  ViewController.m
//  runTime
//
//  Created by Xuliran on 2019/5/31.
//  Copyright © 2019 Yuedao. All rights reserved.
//

/**
 * runtime 的应用
 */
#import "ViewController.h"
#import <objc/runtime.h>

@interface Person : NSObject

@end

@implementation Person

- (void)foo{
    NSLog(@"Doing foo");
}

@end


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self performSelector:@selector(foo)];
}

/**
 * 动态方法解析
 * if 中给foo方法指向新的方法, 并返回YES
 * 如果返回NO, 则执行 forwardingTargetForSelector 方法
 */

+ (BOOL)resolveInstanceMethod:(SEL)sel{
    // 给 foo 指向新的 方法 fooMethod
//    if (sel == @selector(foo)) {
//        // 如果执行foo函数, 就动态解析, 指定新的IMP
//        class_addMethod([self class], sel, (IMP)fooMethod, "v@:");
//        return YES;
//    }
    return [super resolveInstanceMethod:sel];
}

/**
 * 备用接受者
 */
- (id)forwardingTargetForSelector:(SEL)aSelector{
    // 把消息交给备用对象
//    if (aSelector == @selector(foo)) {
//
//        return [Person new];
//    }
    return [super forwardingTargetForSelector:aSelector];
    
}

/**
 * 完整的消息转发
 * 发送消息给-methodSignatureForSelector:, 获得函数的返回值类型和参数
 * 如果-methodSignatureForSelector:返回nil ，Runtime则会发出 -doesNotRecognizeSelector: 消息，程序这时也就挂掉了
 * 如果返回了一个函数签名，Runtime就会创建一个NSInvocation 对象并发送 -forwardInvocation:消息给目标对象。
 */

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    if ([NSStringFromSelector(aSelector) isEqualToString:@"foo"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];// 签名进入forwardInvocation
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    SEL sel = anInvocation.selector;
    Person *p = [Person new];
    if ([p respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:p];
    }else{
        [self doesNotRecognizeSelector:sel];
    }
}

void fooMethod(id obj, SEL _cmd) {
    NSLog(@"Doing foo");//新的foo函数
}



@end
