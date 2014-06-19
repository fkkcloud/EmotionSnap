//
//  PCamViewController.m
//  PCam
//
//  Created by Pro on 10/19/13.
//  Copyright (c) 2013 Pro. All rights reserved.
//

#import "PCamViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PCamViewController ()

@end

@implementation PCamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.captureView];
    
    [self.view addSubview:self.suddenView]; // explicitely put the suddenView to the top by adding one more time!
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://fkkcloud.com/apps/a.jpg"]];
    UIImage *image = [UIImage imageWithData: imageData];
    [self.suddenView setImage:image];
    self->mySound = [self createSoundID: @"scream.aiff"];
    [self startSession];
}


- (void)dissolveImage{
    [self.suddenView setAlpha:0.0];
}


- (AVCaptureSession *)session
{
    if (!_session) {
        _session = [[AVCaptureSession alloc]init];
    }
    return _session;
}

- (AVCaptureDeviceInput *)deviceInput
{
    if (!_deviceInput) {
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
    }
    return _deviceInput;
}


- (void) startSession {
    [self.session addInput:self.deviceInput];

    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [self.captureView layer];
    [rootLayer setMasksToBounds:YES];
    CGRect boundCapture = self.captureView.bounds;
    [previewLayer setFrame:boundCapture];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    [_session startRunning];
    
    stillImageOutput = [AVCaptureStillImageOutput new];
	if ([_session canAddOutput:stillImageOutput])
		[_session addOutput:stillImageOutput];
}

- (SystemSoundID) createSoundID: (NSString*)name
{
    NSString *path = [NSString stringWithFormat: @"%@/%@",
                      [[NSBundle mainBundle] resourcePath], name];
    
    
    NSURL* filePath = [NSURL fileURLWithPath: path isDirectory: NO];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    return soundID;
}


- (AVCaptureDevice *)frontFacingCamera
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


- (void) toggleCameraFront
{
    AVCaptureDeviceInput *newVideoInput;
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:nil];
    [self.session removeInput:self.deviceInput];
    [self.session addInput:newVideoInput];
}


- (IBAction)captureImage:(UIButton *)sender {
    AudioServicesPlaySystemSound(self->mySound);
    [self.suddenView setAlpha:1.0];
    [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(toggleCameraFront) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.9 target:self selector:@selector(imageOutput) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(dissolveImage) userInfo:nil repeats:NO];
}


- (void)imageOutput
{
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        if (error) {
            NSLog(@"Take picture failed");
        }
        else {
            
            CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(imageSampleBuffer);
            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            GLubyte *rawImageBytes = CVPixelBufferGetBaseAddress(cameraFrame);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
            NSData *dataForRawBytes = [NSData dataWithBytes:rawImageBytes length:bytesPerRow * CVPixelBufferGetHeight(cameraFrame)];
            // Do whatever with your bytes
            NSLog(@"%@", dataForRawBytes);
            NSLog(@"%s", rawImageBytes);
            //NSLog(@"%@", imageSampleBuffer);
            
            // SAVING PHOTO INTO LIBRARY!!
            {
                // trivial simple JPEG case
                NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                            imageSampleBuffer,
                                                                            kCMAttachmentMode_ShouldPropagate);
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"Save to camera roll failed");
                    }
                }];
                
                if (attachments)
                    CFRelease(attachments);
                
            }
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            
        }
    }];
}


@end
