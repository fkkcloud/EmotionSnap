//
//  PCamViewController.h
//  PCam
//
//  Created by Pro on 10/19/13.
//  Copyright (c) 2013 Pro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PCamViewController : UIViewController{
    AVCaptureStillImageOutput *stillImageOutput;
    SystemSoundID mySound;
}

- (IBAction)captureImage:(UIButton *)sender;
- (void)startSession;

@property (weak, nonatomic) IBOutlet UIView *captureView;
@property (weak, nonatomic) IBOutlet UIImageView *suddenView;


@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *deviceInput;
@property (strong, nonatomic) NSValue *val;

@end
