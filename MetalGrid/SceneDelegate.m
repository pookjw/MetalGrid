//
//  SceneDelegate.m
//  MetalGrid
//
//  Created by Jinwoo Kim on 4/8/23.
//

#import "SceneDelegate.h"
#import "GridViewController.h"

@interface SceneDelegate ()
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [GridViewController new];
    [window makeKeyAndVisible];
    self.window = window;
}

@end
