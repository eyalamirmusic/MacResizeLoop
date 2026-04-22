#import <Cocoa/Cocoa.h>

// A view that owns the animation state and repaints itself whenever `tick` is
// called. All mutation happens on the main thread via the timer below.
@interface BouncingView : NSView
- (void)tick;
@end

@implementation BouncingView {
    NSPoint _position;
    NSPoint _velocity;  // points per tick (30 ticks/sec)
    CGFloat _radius;
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _radius = 25.0;
        _position = NSMakePoint(NSMidX(frame), NSMidY(frame));
        _velocity = NSMakePoint(6.0, 4.5);
    }
    return self;
}

- (void)tick {
    _position.x += _velocity.x;
    _position.y += _velocity.y;

    const NSRect b = self.bounds;
    if (_position.x - _radius < NSMinX(b)) { _position.x = NSMinX(b) + _radius; _velocity.x = -_velocity.x; }
    if (_position.x + _radius > NSMaxX(b)) { _position.x = NSMaxX(b) - _radius; _velocity.x = -_velocity.x; }
    if (_position.y - _radius < NSMinY(b)) { _position.y = NSMinY(b) + _radius; _velocity.y = -_velocity.y; }
    if (_position.y + _radius > NSMaxY(b)) { _position.y = NSMaxY(b) - _radius; _velocity.y = -_velocity.y; }

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor windowBackgroundColor] setFill];
    NSRectFill(dirtyRect);

    NSRect box = NSMakeRect(_position.x - _radius, _position.y - _radius, _radius * 2, _radius * 2);
    [[NSColor systemBlueColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:box] fill];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}
@end

int main(int argc, const char *argv[]) {
    (void)argc; (void)argv;
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;

        const NSRect frame = NSMakeRect(0, 0, 640, 480);
        const NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                        NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable;

        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:style
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        window.title = @"MacResizeLoop";
        window.releasedWhenClosed = NO;  // ARC manages the lifetime
        [window center];

        BouncingView *view = [[BouncingView alloc] initWithFrame:frame];
        view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        window.contentView = view;

        // NSTimer fires on the main run loop. Adding it in common modes keeps it
        // ticking during window live-resize and menu tracking.
        __weak BouncingView *weakView = view;
        NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 / 60.0
                                                repeats:YES
                                                  block:^(NSTimer *t) {
                                                      (void)t;
                                                      [weakView tick];
                                                  }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

        [window makeKeyAndOrderFront:nil];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
