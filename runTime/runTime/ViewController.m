//
//  ViewController.m
//  runTime
//
//  Created by Xuliran on 2019/5/31.
//  Copyright © 2019 Yuedao. All rights reserved.
//

/**
 * runtime 的应用
 * 关联对象(Objective-C Associated Objects)给分类增加属性
 * 方法魔法(Method Swizzling)方法添加和替换和KVO实现
 * 消息转发(热更新)解决Bug(JSPatch)
 * 实现NSCoding的自动归档和自动解档
 * 实现字典和模型的自动转换(MJExtension)
 * 参考文档 https://www.jianshu.com/p/6ebda3cd8052
 */
#import "ViewController.h"
#import <objc/runtime.h>

/**
 * 实现UIView的Category添加自定义属性defaultColor
 */

@interface UIView (DefaultColor)

@property (nonatomic, strong) UIColor *defaultColor;

@end

@implementation UIView (DefaultColor)

@dynamic defaultColor;
static char kDefaultColorKey;

- (void)setDefaultColor:(UIColor *)defaultColor{
    objc_setAssociatedObject(self, &kDefaultColorKey, defaultColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)defaultColor{
    return objc_getAssociatedObject(self, &kDefaultColorKey);
}



@end

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

/**
 * 实现替换viewdDidLoad的方法
 * swizzling 应该只在+load方法中完成
 *  在 Objective-C 的运行时中，每个类有两个方法都会自动调用。+load 是在一个类被初始装载时调用，+initialize 是在应用第一次调用该类的类方法或实例方法前调用的。两个方法都是可选的，并且只有在方法被实现的情况下才会被调用。
 * swizzling应该只在dispatch_once 中完成,由于swizzling 改变了全局的状态，所以我们需要确保每个预防措施在运行时都是可用的。原子操作就是这样一个用于确保代码只会被执行一次的预防措施，就算是在不同的线程中也能确保代码只执行一次。Grand Central Dispatch 的 dispatch_once满足了所需要的需求，并且应该被当做使用swizzling 的初始化单例方法的标准。
 */
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(viewDidLoad);
        SEL swizzledSelector = @selector(jkViewDidLoad);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzleMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // 判断swizzleMethod方法实现是否存在
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
        // 如果swizzleMethod已经存在
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        }else{
            method_exchangeImplementations(originalMethod, swizzleMethod);
        }
    });
}

- (void)jkViewDidLoad{
    
    NSLog(@"替换的方法");
    [super viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"自带的方法");
    // Do any additional setup after loading the view.
    [self performSelector:@selector(foo)];
    
    UIView *test = [UIView new];
    test.defaultColor = [UIColor blackColor];
    NSLog(@"text.defaultColor : %@", test.defaultColor);
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
