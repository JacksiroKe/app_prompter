#import "AppPrompterPlugin.h"
#if __has_include(<app_prompter/app_prompter-Swift.h>)
#import <app_prompter/app_prompter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "app_prompter-Swift.h"
#endif

@implementation AppPrompterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppPrompterPlugin registerWithRegistrar:registrar];
}
@end
