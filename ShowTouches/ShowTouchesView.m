#import "ShowTouchesView.h"
#include <math.h>

#define CLAMP(f) (fmax(0, fmin(1, f)))

static BOOL _havePreciseLocationInView;
static BOOL _haveForce;
static BOOL _haveAzimuthAngleInView;
static BOOL _haveAltitudeAngle;

@interface ShowTouchesView () {
	NSMutableSet *_touches;
}

@end

@implementation ShowTouchesView

+ (void)initialize
{
	_havePreciseLocationInView = [UITouch instancesRespondToSelector:@selector(preciseLocationInView:)];
	_haveForce = [UITouch instancesRespondToSelector:@selector(force)];
	_haveAzimuthAngleInView = [UITouch instancesRespondToSelector:@selector(azimuthAngleInView:)];
	_haveAltitudeAngle = [UITouch instancesRespondToSelector:@selector(altitudeAngle)];
}

- (id)initWithFrame:(CGRect)rect
{
	if (!(self = [super initWithFrame:rect]))
		return nil;
	
	_touches = [NSMutableSet new];
	[self setBackgroundColor:[UIColor colorWithWhite:.15 alpha:1]];
	[self setMultipleTouchEnabled:YES];
	[self setUserInteractionEnabled:YES];
	[self setIsAccessibilityElement:YES];
	[self setAccessibilityTraits:UIAccessibilityTraitAllowsDirectInteraction];
	
	return self;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
}

- (void)announceTouches
{
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
		[NSString stringWithFormat:@"%u", (unsigned)[_touches count]]);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[_touches unionSet:touches];
	[self setNeedsDisplay];
	[self announceTouches];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[_touches minusSet:touches];
	[self setNeedsDisplay];
	[self announceTouches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[_touches minusSet:touches];
	[self setNeedsDisplay];
	[self announceTouches];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];

	if (!_touches)
		return;
	
	CGRect bounds = [self bounds];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	BOOL haveForce = _haveForce &&
		[[self traitCollection] forceTouchCapability] == UIForceTouchCapabilityAvailable;
	
	/* coordinates for cross line points; extending to max(width, height) in every
	   direction to account for rotation */
	float maxsz = fmax(bounds.size.width, bounds.size.height);
	CGPoint linepts[] = {
		CGPointMake(0, -maxsz), CGPointMake(0, maxsz),
		CGPointMake(-maxsz,0 ), CGPointMake(maxsz, 0),
	};

	for (UITouch *touch in _touches) {
		CGPoint pos = _havePreciseLocationInView ?
			[touch preciseLocationInView:self] :
			[touch locationInView:self];
		
		float r, g, b;
		if (haveForce) {
			float force = force = [touch force];
			/* redder for force>1, bluer for force <1 */
			r = CLAMP(force);
			g = CLAMP(force<1 ? force : 2-force);
			b = CLAMP(2-force);
		} else {
			r = g = b = 1;
		}
		
		CGContextSaveGState(ctx);
		CGContextTranslateCTM(ctx, pos.x+.5, pos.y+.5);
		
		float rd = [touch majorRadius];
		float rdt = [touch majorRadiusTolerance];
		if (!rd)
			rd = 20;
		
		/* shadow circle */
		CGContextSetRGBFillColor(ctx, r, g, b, .3);
		CGContextFillEllipseInRect(ctx, CGRectMake(-rd-rdt, -rd-rdt, (rd+rdt)*2, (rd+rdt)*2));
		
		if (_haveAzimuthAngleInView)
			CGContextRotateCTM(ctx, [touch azimuthAngleInView:self]);
		
		if (_haveAltitudeAngle) {
			float angle = [touch altitudeAngle];
			if (angle < M_PI/2-0.005 || angle > M_PI/2+0.005) {
				/* shadow cross line indicating altitude angle */
				CGContextSaveGState(ctx);
				CGContextRotateCTM(ctx, angle);
				CGContextSetGrayStrokeColor(ctx, 0, 1);
				CGContextStrokeLineSegments(ctx, &linepts[0], 2);
				CGContextStrokeLineSegments(ctx, &linepts[2], 2);
				CGContextRestoreGState(ctx);
			}
		}
		
		/* cross line indicating azimuth angle */
		CGContextSetRGBStrokeColor(ctx, r, g, b, 1);
		CGContextStrokeLineSegments(ctx, &linepts[0], 2);
		CGContextStrokeLineSegments(ctx, &linepts[2], 2);
		
		/* radius circle */
		if (rd) {
			CGContextSetRGBFillColor(ctx, r, g, b, 1);
			CGContextFillEllipseInRect(ctx, CGRectMake(-rd, -rd, rd*2, rd*2));
		}
		
		CGContextRestoreGState(ctx);
	}
}

@end
