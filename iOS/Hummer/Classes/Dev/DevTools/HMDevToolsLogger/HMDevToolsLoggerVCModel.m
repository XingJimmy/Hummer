//
//  HMDevToolsLoggerVCModel.m
//  Hummer
//
//  Created by didi on 2022/2/7.
//

#import "HMDevToolsLoggerVCModel.h"
#import "HMJSContext.h"
#import "HMExceptionModel.h"

#import "HMInterceptor.h"
#import "HMDevToolsJSCallerExecutor.h"


static NSDateFormatter *formatter;

@implementation HMDevToolsLoggerVCModel

- (instancetype)initWithVC:(HMDevToolsLoggerViewController *)vc {
    self = [super init];
    self.vc = vc;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      formatter = NSDateFormatter.new;
      formatter.dateFormat = @"HH:mm:ss.SSS";
    });
    
    return self;
}

- (void)reset {
    [self.dataArray removeAllObjects];
    __weak typeof(self) weakSelf = self;
    [self.vc.context.context addConsoleHandler:^(NSString * _Nullable logString, HMLogLevel logLevel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        HMDevToolsLogger *logger = HMDevToolsLogger.new;
        

        NSString *date = [formatter stringFromDate:NSDate.date];

        logger.logString = [NSString stringWithFormat:@"[%@] %@", date, logString];
        logger.logLevel = logLevel;
        logger.expended = NO;
        [strongSelf.dataArray addObject:logger];
        [strongSelf.vc reloadData];
    } key:self];
    
    [self.vc.context.context addExceptionHandler:^(HMExceptionModel * _Nonnull exceptionModel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        HMDevToolsLogger *logger = HMDevToolsLogger.new;

        NSString *date = [formatter stringFromDate:NSDate.date];
        NSString *info = [NSString stringWithFormat:@"column:%@ line:%@, %@\nexception:%@\n\nstack:%@", exceptionModel.column?:@0, exceptionModel.line?:@0, exceptionModel.name?:@"", exceptionModel.message?:@"", exceptionModel.stack?:@""];

        logger.logString = [NSString stringWithFormat:@"[%@] %@", date, info];
        logger.logLevel = HMLogLevelError;
        logger.expended = NO;
        [strongSelf.dataArray addObject:logger];
        [strongSelf.vc reloadData];

    } key:self];
}

- (NSMutableArray<HMDevToolsLogger *> *)dataArray {
    if (!_dataArray) {
        _dataArray = @[].mutableCopy;
    }
    
    return _dataArray;
}
@end

@interface HMDevToolsCallTreeVCModel ()
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) BOOL needRefresh;
@end
@implementation HMDevToolsCallTreeVCModel

- (void)reset {
    NSArray *inspectors = [HMInterceptor interceptor:HMInterceptorTypeJSCaller];
    if (inspectors.count < 1) {
        return;
    }

    HMDevToolsJSCallerExecutor *callerExcutor;
    for (NSObject *interceptor in inspectors) {
        if ([interceptor isKindOfClass:HMDevToolsJSCallerExecutor.class]) {
            callerExcutor = interceptor;
            break;
        }
    }
    
    if (!callerExcutor) {
        return;
    }
    
    __weak typeof(self) weakself = self;
    callerExcutor.callerNativeInfo = ^(NSString * _Nonnull className, NSString * _Nonnull funtionName, NSString * _Nonnull objRef, NSString * _Nonnull args) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *date = [formatter stringFromDate:NSDate.date];
            
            NSString *content = [NSString stringWithFormat:@"[%@] %@.%@%@", date, className, funtionName, args];
            if (objRef) {
                content = [NSString stringWithFormat:@"[%@](%@) %@.%@%@", date, objRef, className, funtionName, args];
            }
            HMDevToolsLogger *logger = HMDevToolsLogger.new;
            logger.logString = content;
            [self.dataArray addObject:logger];
            self.needRefresh = YES;
        });

    };
    
    callerExcutor.callerJSInfo = ^(NSString * _Nonnull className, NSString * _Nonnull funtionName, NSString * _Nonnull objRef, NSString * _Nonnull args) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *date = [formatter stringFromDate:NSDate.date];
            
            NSString *content = [NSString stringWithFormat:@"[%@](%@) %@.%@%@", date, objRef, className?:@"JS", funtionName, args];
        
            HMDevToolsLogger *logger = HMDevToolsLogger.new;
            logger.logString = content;
            [self.dataArray addObject:logger];
            self.needRefresh = YES;
        });

    };
    
    if (_timer) {
        dispatch_suspend(_timer);
    }
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        if (!self.needRefresh) {
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self.needRefresh = NO;
        });
        
        [self.vc reloadData];
    });
    dispatch_resume(self.timer);
}

@end
