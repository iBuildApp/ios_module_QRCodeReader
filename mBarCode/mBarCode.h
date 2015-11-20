/****************************************************************************
 *                                                                           *
 *  Copyright (C) 2014-2015 iBuildApp, Inc. ( http://ibuildapp.com )         *
 *                                                                           *
 *  This file is part of iBuildApp.                                          *
 *                                                                           *
 *  This Source Code Form is subject to the terms of the iBuildApp License.  *
 *  You can obtain one at http://ibuildapp.com/license/                      *
 *                                                                           *
 ****************************************************************************/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "functionLibrary.h"
#import <ZBarSDK/ZBarReaderViewController.h>

/**
 *  Main module class for widget mBarCode (QRCode Scanner). Module entry point.
 */
@interface mBarCodeViewController : UIViewController<ZBarReaderDelegate,
                                                     UIActionSheetDelegate,
                                                     MFMailComposeViewControllerDelegate,
                                                     UIAlertViewDelegate,
                                                     MFMessageComposeViewControllerDelegate>

/**
 *  Add link to ibuildapp.com into sharing messages
 */
@property (nonatomic, assign) BOOL    showLink;

/**
 *  Tab bar hiddennes flag
 */
@property (nonatomic, assign) BOOL    tabBarIsHidden;

/**
 *  Inint camera. Ready to get image.
 */
- (void)cameraInit;

/**
 *  Init flash
 */
- (void)initFlash;

@end
