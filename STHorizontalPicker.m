/*
 * Copyright 2011 StackThread Software Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "STHorizontalPicker.h"

const int DISTANCE_BETWEEN_ITEMS = 100;
const int TEXT_LAYER_WIDTH = 40;
const int NUMBER_OF_ITEMS = 15;
const float FONT_SIZE = 16.0f;
const float POINTER_WIDTH = 10.0f;
const float POINTER_HEIGHT = 7.0f;

//================================
// UIColor category
//================================
@implementation UIColor (STColorComponents)

- (CGColorSpaceModel)colorSpaceModel {
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (CGFloat)red {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)green {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
    if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[1];
}

- (CGFloat)blue {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[2];
}

- (CGFloat)alpha {
    return CGColorGetAlpha(self.CGColor);
}

@end





//================================
// STHorizontalPicker
//================================

@interface STHorizontalPicker ()

// Private properties

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *scrollViewMarkerContainerView;
@property (nonatomic, retain) NSMutableArray *scrollViewMarkerLayerArray;
@property (nonatomic, retain) CALayer *pointerLayer;

@end;
    
@implementation STHorizontalPicker

@synthesize scrollView, scrollViewMarkerContainerView, scrollViewMarkerLayerArray, name, pointerLayer;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        steps = 15;
        
        float leftPadding = self.frame.size.width/2;
        float rightPadding = leftPadding;
        float contentWidth = leftPadding + (steps * DISTANCE_BETWEEN_ITEMS) + rightPadding + TEXT_LAYER_WIDTH / 2;
        
        scale = [[UIScreen mainScreen] scale];
        
        if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
            self.contentScaleFactor = scale;
        }
        
        // Ensures that the corners are transparent
        self.backgroundColor = [UIColor clearColor];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
        self.scrollView.layer.cornerRadius = 8.0f;
        self.scrollView.layer.borderWidth = 1.0f;
        self.scrollView.layer.borderColor = borderColor.CGColor ? borderColor.CGColor : [UIColor grayColor].CGColor;
        self.scrollView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;        
        self.scrollView.pagingEnabled = NO;
        self.scrollView.delegate = self;
        
        self.scrollViewMarkerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height)];
        self.scrollViewMarkerLayerArray = [NSMutableArray arrayWithCapacity:steps];
        
        fontSize = 16.0;
        
        for (int i = 0; i <= steps; i++) {
            CATextLayer *textLayer = [CATextLayer layer];
            textLayer.contentsScale = scale;
            textLayer.frame = CGRectIntegral(CGRectMake(leftPadding + i * DISTANCE_BETWEEN_ITEMS, self.frame.size.height/2 - self.fontSize / 2 + 1, TEXT_LAYER_WIDTH, 40));
            textLayer.foregroundColor = [UIColor blackColor].CGColor;
            textLayer.alignmentMode = kCAAlignmentCenter;
            textLayer.fontSize = self.fontSize;
            
            textLayer.string = [NSString stringWithFormat:@"%.1f", (float) i + 1];
            [self.scrollViewMarkerLayerArray addObject:textLayer];
            [self.scrollViewMarkerContainerView.layer addSublayer:textLayer];
        }
        
        [self.scrollView addSubview:self.scrollViewMarkerContainerView];        
        [self addSubview:self.scrollView];
        [self snapToMarkerAnimated:NO];
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.contentsScale = scale;
        gradientLayer.cornerRadius = 8.0f;
        gradientLayer.startPoint = CGPointMake(0.0f, 0.0f);
        gradientLayer.endPoint = CGPointMake(1.0f, 0.0f);
        gradientLayer.opacity = 1.0;
        gradientLayer.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0, self.frame.size.height - 2.0);
        gradientLayer.locations = [NSArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0.0f],
                                   [NSNumber numberWithFloat:0.05f],
                                   [NSNumber numberWithFloat:0.3f],
                                   [NSNumber numberWithFloat:0.7f],
                                   [NSNumber numberWithFloat:0.95f],                                   
                                   [NSNumber numberWithFloat:1.0f], nil];
        gradientLayer.colors = [NSArray arrayWithObjects:
                                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.95] CGColor], 
                                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.8] CGColor], 
                                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.1] CGColor], 
                                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.1] CGColor], 
                                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.8] CGColor],
                                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.95] CGColor], nil];
        [self.layer insertSublayer:gradientLayer above:self.scrollView.layer];
        
        self.pointerLayer = [CALayer layer];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor red]] forKey:@"borderRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor green]] forKey:@"borderGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor blue]] forKey:@"borderBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor alpha]] forKey:@"borderAlpha"];        
        self.pointerLayer.opacity = 1.0;
        self.pointerLayer.contentsScale = scale;
        self.pointerLayer.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
        self.pointerLayer.delegate = [[STPointerLayerDelegate alloc] init];
        [self.layer insertSublayer:self.pointerLayer above:gradientLayer];
        [self.pointerLayer setNeedsDisplay];
    }
    return self;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self snapToMarkerAnimated:YES];
    if (delegate && [delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
        [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self snapToMarkerAnimated:YES];
    if (delegate && [delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
        [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
    }    
}

- (void)callDelegateWithNewValueFromOffset:(CGFloat)offset {
    CGFloat itemWidth = (float) DISTANCE_BETWEEN_ITEMS;
    
    CGFloat offSet = offset / itemWidth;
    NSUInteger target = (NSUInteger)(offSet + 0.35f);
    target = target > steps ? steps - 1 : target;
    CGFloat newValue = target * (maximumValue - minimumValue) / steps;
    
    [delegate pickerView:self didSelectValue:newValue];
}

- (void)snapToMarkerAnimated:(BOOL)animated {
    CGFloat itemWidth = (float)DISTANCE_BETWEEN_ITEMS;
    CGFloat position = [self.scrollView contentOffset].x;

    if (position < self.scrollViewMarkerContainerView.frame.size.width - self.frame.size.width / 2) {
        CGFloat newPosition = 0.0f;
        CGFloat offSet = position / itemWidth;
        NSUInteger target = (NSUInteger)(offSet + 0.35f);
        target = target > steps ? steps - 1 : target;
        newPosition = target * itemWidth + TEXT_LAYER_WIDTH / 2;
        [self.scrollView setContentOffset:CGPointMake(newPosition, 0.0f) animated:animated];
    }
}

- (void)removeAllMarkers {
    for (id marker in self.scrollViewMarkerLayerArray) {
        [(CATextLayer *)marker removeFromSuperlayer];
    }
    [self.scrollViewMarkerLayerArray removeAllObjects];
}

- (void)setupMarkers {
    [self removeAllMarkers];
    
    // Calculate the new size of the content
    float leftPadding = self.frame.size.width / 2;
    float rightPadding = leftPadding;
    float contentWidth = leftPadding + (steps * DISTANCE_BETWEEN_ITEMS) + rightPadding + TEXT_LAYER_WIDTH / 2;
    self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
    
    // Set the size of the marker container view
    [self.scrollViewMarkerContainerView setFrame:CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height)];
    
    // Configure the new markers
    self.scrollViewMarkerLayerArray = [NSMutableArray arrayWithCapacity:steps];
    for (int i = 0; i <= steps; i++) {
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.contentsScale = scale;
        textLayer.frame = CGRectIntegral(CGRectMake(leftPadding + i*DISTANCE_BETWEEN_ITEMS, self.frame.size.height / 2 - fontSize / 2 + 1, TEXT_LAYER_WIDTH, 40));
        textLayer.foregroundColor = [UIColor blackColor].CGColor;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.fontSize = fontSize;
        
        textLayer.string = [NSString stringWithFormat:@"%.1f", (float) minimumValue + i * (maximumValue - minimumValue) / steps];
        [self.scrollViewMarkerLayerArray addObject:textLayer];
        [self.scrollViewMarkerContainerView.layer addSublayer:textLayer];
    }
}

- (CGFloat)minimumValue {
    return minimumValue;
}

- (void)setMinimumValue:(CGFloat)newMin {
    minimumValue = newMin;
    [self setupMarkers];
}

- (CGFloat)maximumValue {
    return maximumValue;
}

- (void)setMaximumValue:(CGFloat)newMax {
    maximumValue = newMax;
    [self setupMarkers];
}

- (NSUInteger)steps {
    return steps;
}

- (void)setSteps:(NSUInteger)newSteps {
    steps = newSteps;
    [self setupMarkers];
}

- (CGFloat)value {
    return value;
}

- (UIColor *)borderColor {
    return borderColor;
}

- (void)setBorderColor:(UIColor *)newBorderColor {
    if (newBorderColor != borderColor)
    {
        [newBorderColor retain];
        [borderColor release];
        borderColor = newBorderColor;

        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor red]] forKey:@"borderRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor green]] forKey:@"borderGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor blue]] forKey:@"borderBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[borderColor alpha]] forKey:@"borderAlpha"];
        [self.pointerLayer setNeedsDisplay];
        
        self.scrollView.layer.borderColor = borderColor.CGColor;
    }
}

- (CGFloat)fontSize {
    return fontSize;
}

- (void)setFontSize:(CGFloat)newFontSize {
    fontSize = newFontSize;
    [self setupMarkers];
}

- (void)setValue:(CGFloat)newValue {    
    value = newValue > maximumValue ? maximumValue : newValue;
    value = newValue < minimumValue ? minimumValue : newValue;
    
    CGFloat itemWidth = (float) DISTANCE_BETWEEN_ITEMS;
    CGFloat xValue = newValue / ((maximumValue-minimumValue) / steps) * itemWidth + TEXT_LAYER_WIDTH / 2;
        
    [self.scrollView setContentOffset:CGPointMake(xValue, 0.0f) animated:NO];
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id<STHorizontalPickerDelegate>)newDelegate {
    delegate = newDelegate;
    
    BOOL needsReset = FALSE;
    
    if ([delegate respondsToSelector:@selector(minimumValueForPickerView:)]) {
        minimumValue = [delegate minimumValueForPickerView:self];
        needsReset = TRUE;
    }
    if ([delegate respondsToSelector:@selector(maximumValueForPickerView:)]) {
        maximumValue = [delegate maximumValueForPickerView:self];
        needsReset = TRUE;
    }
    if ([delegate respondsToSelector:@selector(stepCountForPickerView:)]) {
        steps = [delegate stepCountForPickerView:self];
        needsReset = TRUE;
    }
    
    if (needsReset) {
        [self setupMarkers];
    }
}


- (void)dealloc
{
    [super dealloc];
}

@end


//================================
// STPointerLayerDelegate
//================================

@implementation STPointerLayerDelegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGContextSaveGState(context);

    CGContextSetLineWidth(context, 2.0);
	CGContextSetRGBStrokeColor(context, [[layer valueForKey:@"borderRed"] floatValue], [[layer valueForKey:@"borderGreen"] floatValue], [[layer valueForKey:@"borderBlue"] floatValue], [[layer valueForKey:@"borderAlpha"] floatValue]);
    CGContextSetRGBFillColor(context, [[layer valueForKey:@"borderRed"] floatValue], [[layer valueForKey:@"borderGreen"] floatValue], [[layer valueForKey:@"borderBlue"] floatValue], [[layer valueForKey:@"borderAlpha"] floatValue]);
    
    CGContextMoveToPoint(context, layer.frame.size.width / 2 - POINTER_WIDTH / 2, 0);
    CGContextAddLineToPoint(context, layer.frame.size.width / 2, POINTER_HEIGHT);
    CGContextAddLineToPoint(context, layer.frame.size.width / 2 + POINTER_WIDTH / 2, 0);    
    CGContextFillPath(context);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, layer.frame.size.width / 2 - POINTER_WIDTH / 2, layer.frame.size.height);
    CGContextAddLineToPoint(context, layer.frame.size.width / 2, layer.frame.size.height - POINTER_HEIGHT);
    CGContextAddLineToPoint(context, layer.frame.size.width / 2 + POINTER_WIDTH / 2, layer.frame.size.height);    
    CGContextFillPath(context);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

@end