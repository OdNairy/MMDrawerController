// Copyright (c) 2013 Mutual Mobile (http://mutualmobile.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "MMDrawerVisualState.h"
#import <QuartzCore/QuartzCore.h>

@implementation MMDrawerVisualState
+(MMDrawerControllerDrawerVisualStateBlock)scale3dVisualStateBlock{
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock =
    ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible){
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = (CGFloat) ((1.0 / -500)*percentVisible);
        transform = CATransform3DRotate(transform, (CGFloat) ((-25 * percentVisible)* M_PI / 180), 0, 1, 0);
        transform = CATransform3DScale(transform, (1-0.3*percentVisible), (1-0.3*percentVisible), (1-0.3*percentVisible));
        transform = CATransform3DTranslate(transform, (-120)*percentVisible, 0, 0);
        drawerController.centerViewController.view.layer.transform = transform;

        transform = CATransform3DIdentity;
        CGFloat delta = .5;
        transform = CATransform3DMakeScale(1 + delta * (1 - percentVisible), 1 + delta * (1 - percentVisible), 1 + delta * (1 - percentVisible));
        transform = CATransform3DTranslate(transform, -120 * (1 - percentVisible), 0, 0);
        drawerController.leftDrawerViewController.view.layer.transform = transform;
        drawerController.leftDrawerViewController.view.layer.opacity = .3+.7*powf(percentVisible,2);
        return ;
    };
    return visualStateBlock;
}

+(MMDrawerControllerDrawerVisualStateBlock)slideAndScaleVisualStateBlock{
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock =
    ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible){
        CGFloat minScale = .90;
        CGFloat scale = minScale + (percentVisible*(1.0-minScale));
        CATransform3D scaleTransform =  CATransform3DMakeScale(scale, scale, scale);

        CGFloat maxDistance = 50;
        CGFloat distance = maxDistance * percentVisible;
        CATransform3D translateTransform = CATransform3DIdentity;
        UIViewController * sideDrawerViewController;
        if(drawerSide == MMDrawerSideLeft) {
            sideDrawerViewController = drawerController.leftDrawerViewController;
            translateTransform = CATransform3DMakeTranslation((maxDistance-distance), 0.0, 0.0);
        }
        else if(drawerSide == MMDrawerSideRight){
            sideDrawerViewController = drawerController.rightDrawerViewController;
            translateTransform = CATransform3DMakeTranslation(-(maxDistance-distance), 0.0, 0.0);
        }

        [sideDrawerViewController.view.layer setTransform:CATransform3DConcat(scaleTransform, translateTransform)];
        [sideDrawerViewController.view setAlpha:percentVisible];
    };
    return visualStateBlock;
}

+(MMDrawerControllerDrawerVisualStateBlock)slideVisualStateBlock{
    return [self parallaxVisualStateBlockWithParallaxFactor:1.0];
}


+(MMDrawerControllerDrawerVisualStateBlock)swingingDoorVisualStateBlock{
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock =
    ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible){
        UIViewController * sideDrawerViewController;
        CGPoint anchorPoint;
        CGFloat maxDrawerWidth = 0.0;
        CGFloat xOffset;
        CGFloat angle = 0.0;

        if(drawerSide==MMDrawerSideLeft){

            sideDrawerViewController = drawerController.leftDrawerViewController;
            anchorPoint =  CGPointMake(1.0, .5);
            maxDrawerWidth = MAX(drawerController.maximumLeftDrawerWidth,drawerController.visibleLeftDrawerWidth);
            xOffset = -(maxDrawerWidth/2.0) + (maxDrawerWidth)*percentVisible;
            angle = -M_PI_2+(percentVisible*M_PI_2);
        }
        else {
            sideDrawerViewController = drawerController.rightDrawerViewController;
            anchorPoint = CGPointMake(0.0, .5);
            maxDrawerWidth = MAX(drawerController.maximumRightDrawerWidth,drawerController.visibleRightDrawerWidth);
            xOffset = (maxDrawerWidth/2.0) - (maxDrawerWidth)*percentVisible;
            angle = M_PI_2-(percentVisible*M_PI_2);
        }

        [sideDrawerViewController.view.layer setAnchorPoint:anchorPoint];
        [sideDrawerViewController.view.layer setShouldRasterize:YES];
        [sideDrawerViewController.view.layer setRasterizationScale:[[UIScreen mainScreen] scale]];

        CATransform3D swingingDoorTransform = CATransform3DIdentity;
        if (percentVisible <= 1.f) {

            CATransform3D identity = CATransform3DIdentity;
            identity.m34 = -1.0/1000.0;
            CATransform3D rotateTransform = CATransform3DRotate(identity, angle, 0.0, 1.0, 0.0);

            CATransform3D translateTransform = CATransform3DMakeTranslation(xOffset, 0.0, 0.0);

            CATransform3D concatTransform = CATransform3DConcat(rotateTransform, translateTransform);

            swingingDoorTransform = concatTransform;
        }
        else{
            CATransform3D overshootTransform = CATransform3DMakeScale(percentVisible, 1.f, 1.f);

            NSInteger scalingModifier = 1.f;
            if (drawerSide == MMDrawerSideRight) {
                scalingModifier = -1.f;
            }

            overshootTransform = CATransform3DTranslate(overshootTransform, scalingModifier*maxDrawerWidth/2, 0.f, 0.f);
            swingingDoorTransform = overshootTransform;
        }

        [sideDrawerViewController.view.layer setTransform:swingingDoorTransform];
    };
    return visualStateBlock;
}

+(MMDrawerControllerDrawerVisualStateBlock)parallaxVisualStateBlockWithParallaxFactor:(CGFloat)parallaxFactor{
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock =
    ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible){
        NSParameterAssert(parallaxFactor >= 1.0);
        CATransform3D transform = CATransform3DIdentity;
        UIViewController * sideDrawerViewController;
        if(drawerSide == MMDrawerSideLeft) {
            sideDrawerViewController = drawerController.leftDrawerViewController;
            CGFloat distance = MAX(drawerController.maximumLeftDrawerWidth,drawerController.visibleLeftDrawerWidth);
            if (percentVisible <= 1.f) {
                transform = CATransform3DMakeTranslation((-distance)/parallaxFactor+(distance*percentVisible/parallaxFactor), 0.0, 0.0);
            }
            else{
                transform = CATransform3DMakeScale(percentVisible, 1.f, 1.f);
                transform = CATransform3DTranslate(transform, drawerController.maximumLeftDrawerWidth*(percentVisible-1.f)/2, 0.f, 0.f);
            }
        }
        else if(drawerSide == MMDrawerSideRight){
            sideDrawerViewController = drawerController.rightDrawerViewController;
            CGFloat distance = MAX(drawerController.maximumRightDrawerWidth,drawerController.visibleRightDrawerWidth);
            if(percentVisible <= 1.f){
                transform = CATransform3DMakeTranslation((distance)/parallaxFactor-(distance*percentVisible)/parallaxFactor, 0.0, 0.0);
            }
            else{
                transform = CATransform3DMakeScale(percentVisible, 1.f, 1.f);
                transform = CATransform3DTranslate(transform, -drawerController.maximumRightDrawerWidth*(percentVisible-1.f)/2, 0.f, 0.f);
            }
        }

        [sideDrawerViewController.view.layer setTransform:transform];
    };
    return visualStateBlock;
}

@end
