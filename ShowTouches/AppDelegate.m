/* Copyright (c) 2017-2020, Sijmen J. Mulder (see LICENSE.md) */

#import "AppDelegate.h"
#import "ShowTouchesView.h"

@interface AppDelegate () {
	UIWindow *_window;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[application setStatusBarHidden:YES];

	UIViewController *vc = [UIViewController new];
	[vc setView:[ShowTouchesView new]];

	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_window setRootViewController:vc];
	[_window makeKeyAndVisible];

	return YES;
}

@end
