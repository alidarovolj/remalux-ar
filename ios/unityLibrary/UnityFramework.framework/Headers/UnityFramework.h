#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// These are the necessary headers for UnityFramework to work correctly.
#import <UnityFramework/UnityAppController.h>
#import <UnityFramework/LifeCycleListener.h>
#import <UnityFramework/RenderPluginDelegate.h>

// Solves "RedefinePlatforms.h can only be used after UndefinePlatforms.h"
#import <UnityFramework/UndefinePlatforms.h>
#import <UnityFramework/RedefinePlatforms.h>


//! Project version number for UnityFramework.
FOUNDATION_EXPORT double UnityFrameworkVersionNumber;

//! Project version string for UnityFramework.
FOUNDATION_EXPORT const unsigned char UnityFrameworkVersionString[];

// Unity Framework Listener Protocol
__attribute__ ((visibility("default")))
@protocol UnityFrameworkListener<NSObject>
@optional
- (void)unityDidUnload:(NSNotification*)notification;
- (void)unityDidQuit:(NSNotification*)notification;
@end

// Main Unity Framework Interface
__attribute__ ((visibility("default")))
@interface UnityFramework : NSObject

- (UnityAppController*)appController;
- (UITextField*)keyboardTextField;

+ (UnityFramework*)getInstance;

- (void)setDataBundleId:(const char*)bundleId;

- (void)runUIApplicationMainWithArgc:(int)argc argv:(char*[])argv;
- (void)runEmbeddedWithArgc:(int)argc argv:(char*[])argv appLaunchOpts:(NSDictionary*)appLaunchOpts;

- (void)unloadApplication;
- (void)quitApplication:(int)exitCode;

- (void)registerFrameworkListener:(id<UnityFrameworkListener>)obj;
- (void)unregisterFrameworkListener:(id<UnityFrameworkListener>)obj;

- (void)showUnityWindow;
- (void)pause:(bool)pause;

- (void)setAbsoluteURL:(const char *)url;
- (void)sendMessageToGOWithName:(const char*)goName functionName:(const char*)name message:(const char*)msg;

@end