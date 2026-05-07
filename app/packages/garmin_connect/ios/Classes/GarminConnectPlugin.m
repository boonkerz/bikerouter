#import "GarminConnectPlugin.h"
#if __has_include(<garmin_connect/garmin_connect-Swift.h>)
#import <garmin_connect/garmin_connect-Swift.h>
#else
#import "garmin_connect-Swift.h"
#endif

@implementation GarminConnectPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGarminConnectPlugin registerWithRegistrar:registrar];
}
@end
