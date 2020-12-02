//
// Created by Jamie Lynch on 23/03/2018.
// Copyright (c) 2018 Bugsnag. All rights reserved.
//
#import <objc/runtime.h>

#import "Scenario.h"

void markErrorHandledCallback(const BSG_KSCrashReportWriter *writer) {
    writer->addBooleanElement(writer, "unhandled", false);
}

@implementation Scenario

+ (Scenario *)createScenarioNamed:(NSString *)className
                       withConfig:(BugsnagConfiguration *)config {
    Class clz = NSClassFromString(className);

    if (clz == nil) { // swift class
#if TARGET_OS_IPHONE
        clz = NSClassFromString([NSString stringWithFormat:@"iOSTestApp.%@", className]);
#elif TARGET_OS_MAC
        clz = NSClassFromString([NSString stringWithFormat:@"macOSTestApp.%@", className]);
#endif
    }

    NSAssert(clz != nil, @"Failed to find class named '%@'", className);

    BOOL implementsRun = method_getImplementation(class_getInstanceMethod([Scenario class], @selector(run))) !=
    method_getImplementation(class_getInstanceMethod(clz, @selector(run)));

    NSAssert(implementsRun, @"Class '%@' does not implement the run method", className);

    id obj = [clz alloc];

    NSAssert([obj isKindOfClass:[Scenario class]], @"Class '%@' is not a subclass of Scenario", className);

    return [(Scenario *)obj initWithConfig:config];
}

- (instancetype)initWithConfig:(BugsnagConfiguration *)config {
    if (self = [super init]) {
        self.config = config;
    }
    return self;
}

- (void)run {
}

- (void)startBugsnag {
    [Bugsnag startWithConfiguration:self.config];
}

- (void)didEnterBackgroundNotification {
}

@end
