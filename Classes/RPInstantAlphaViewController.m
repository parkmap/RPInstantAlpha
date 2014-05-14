//
//  RPInstantAlphaViewController.m
//  RPInstantAlpha
//
//  Created by Brandon Evans on 2014-05-02.
//  Copyright (c) 2014 Robots and Pencils. All rights reserved.
//

#import "RPInstantAlphaViewController.h"

#import "RPInstantAlphaInstructionsWindowController.h"
#import "RPInstantAlphaImageView.h"
#import "RPThresholdLabelView.h"
#import "RPThresholdLabelWindow.h"

const CGFloat RPInstantAlphaThresholdLabelWidth = 50.0;
const CGFloat RPInstantAlphaThresholdLabelHeight = 25.0;
const CGFloat RPInstantAlphaThresholdLabelCornerRadius = 5.0;
const CGFloat RPInstantAlphaInstructionYPadding = 20.0;

@interface RPInstantAlphaViewController ()

@property (nonatomic, strong) RPInstantAlphaInstructionsWindowController *instructionsWindowController;
@property (nonatomic, strong) NSWindow *thresholdLabelWindow;

@property (nonatomic, strong) NSImage *originalImage;

@property (nonatomic, copy) void(^completion)(NSImage *);

@property (nonatomic, strong) RPThresholdLabelView *labelView;
@end

@implementation RPInstantAlphaViewController

- (instancetype)initWithImage:(NSImage *)image completion:(void(^)(NSImage *))completion {
    self = [super init];
    if (!self) return nil;
    
    _originalImage = image;
    
    _completion = completion;
    
    return self;
}

- (void)showHUD {
    [self.instructionsWindowController.window orderFront:nil];
    NSRect instructionsFrame = ({
        CGRect instructionsFrame = self.instructionsWindowController.window.frame;
        CGRect windowFrame = self.view.window.frame;
        CGFloat x = CGRectGetMinX(windowFrame) + (CGRectGetWidth(self.view.frame) - CGRectGetWidth(instructionsFrame)) / 2;
        CGFloat y = CGRectGetMinY(windowFrame) - CGRectGetHeight(instructionsFrame) - RPInstantAlphaInstructionYPadding;
        instructionsFrame.origin = CGPointMake(x, y);
        instructionsFrame;
    });
    [self.instructionsWindowController.window setFrame:instructionsFrame display:YES];
}

- (void)dismissHUD {
    [self.instructionsWindowController.window close];
}

- (void)loadView {
    __weak __typeof(self) weakSelf = self;
    self.instructionsWindowController = [[RPInstantAlphaInstructionsWindowController alloc] initWithReset:^{
        [weakSelf reset];
    } done:^{
        [weakSelf done];
    }];
    
    NSRect labelRect = NSMakeRect(0.0, 0.0, RPInstantAlphaThresholdLabelWidth, RPInstantAlphaThresholdLabelHeight);
    self.thresholdLabelWindow = [[RPThresholdLabelWindow alloc] initWithContentRect:labelRect];
    
    self.labelView = [[RPThresholdLabelView alloc] initWithFrame:NSInsetRect(labelRect, 1.0, 1.0) cornerRadius:RPInstantAlphaThresholdLabelCornerRadius];
    [self.thresholdLabelWindow setContentView:self.labelView];
    
    RPInstantAlphaImageView *imageView = [[RPInstantAlphaImageView alloc] initWithFrame:NSZeroRect selectionStarted:^(NSPoint mousePoint){
        weakSelf.labelView.threshold = 0.0;
        [weakSelf.thresholdLabelWindow makeKeyAndOrderFront:nil];
        [weakSelf moveThresholdWindowToMousePoint:mousePoint];
    } selectionChanged:^(NSPoint mousePoint, CGFloat threshold) {
        weakSelf.labelView.threshold = threshold;
        [weakSelf moveThresholdWindowToMousePoint:mousePoint];
    } selectionEnded:^(NSImage *image) {
        [weakSelf.thresholdLabelWindow close];
    }];
    
    imageView.image = [self.originalImage copy];
    imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.view = imageView;
}

#pragma mark - Private

- (void)moveThresholdWindowToMousePoint:(NSPoint)mousePoint {
    NSPoint windowOrigin = self.view.window.frame.origin;
    NSPoint mouseRelativeToViewPoint = NSMakePoint(mousePoint.x + windowOrigin.x, mousePoint.y + windowOrigin.y);
    mouseRelativeToViewPoint.y -= RPInstantAlphaThresholdLabelHeight; // Align top-left corner to mouse instead of bottom-left (origin)
    [self.thresholdLabelWindow setFrameOrigin:mouseRelativeToViewPoint];
}

- (void)reset {
    RPInstantAlphaImageView *imageView = (RPInstantAlphaImageView *)self.view;
    imageView.image = [self.originalImage copy];
}

- (void)done {
    RPInstantAlphaImageView *imageView = (RPInstantAlphaImageView *)self.view;
    NSImage *image = imageView.image;
    if (self.completion) self.completion(image);
}

@end
