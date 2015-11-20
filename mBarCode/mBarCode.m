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

#import "mBarCode.h"
#import <AVFoundation/AVFoundation.h>
#import "TBXML.h"

#define USE_PRIVATE_APIS = 0

@interface mBarCodeViewController()

/**
 *  TextView to show recognition result
 */
@property (nonatomic, strong) UITextView    *result;

/**
 *  Image picker
 */
@property (nonatomic, strong) ZBarReaderViewController *imgPicker;

/**
 *  String for storage recognized URL
 */
@property (nonatomic, strong) NSString      *URLString;
@end


@implementation mBarCodeViewController
@synthesize result;
@synthesize URLString;
@synthesize showLink;

#pragma mark - Parse and set params

/**
 *  Special parser for processing original xml file
 *
 *  @param xmlElement_ NSValue* xmlElement_
 *  @param params_     NSMutableDictionary* params_
 */
+ (void)parseXML:(NSValue *)xmlElement_
     withParams:(NSMutableDictionary *)params_
{
  TBXMLElement element;
  [xmlElement_ getValue:&element];

  NSMutableArray *contentArray = [[[NSMutableArray alloc] init] autorelease];
  
  NSString *szTitle = @"";
  TBXMLElement *titleElement = [TBXML childElementNamed:@"title" parentElement:&element];
  if ( titleElement )
    szTitle = [TBXML textForElement:titleElement];
  
    // 1. adding a zero element to array
  [contentArray addObject:[NSDictionary dictionaryWithObject:szTitle ? szTitle : @"" forKey:@"title" ] ];
  
  [params_ setObject:contentArray forKey:@"data"];
}

- (void)setParams:(NSMutableDictionary *)params
{
  if(params != nil)
  {
    self.navigationItem.title = [[[params objectForKey:@"data"] objectAtIndex:0] objectForKey:@"title"];
  }
}

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if ( self )
  {
    self.result    = nil;
    self.imgPicker = nil;
    self.URLString = nil;
  }
  return self;
}

- (void)dealloc
{
  self.result    = nil;
  self.URLString = nil;
  [self.imgPicker.view removeFromSuperview];
  self.imgPicker = nil;
  [super dealloc];
}


#pragma mark - Camera
- (void)initFlash
{
  Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
  if (captureDeviceClass != nil)
  {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if ([device hasTorch])
    {
      if ((device.torchMode ==  AVCaptureTorchModeAuto) || (device.torchMode ==  AVCaptureTorchModeOn))
      {
        [device setTorchMode:AVCaptureTorchModeOff];
      }
      else
      {
        [device setTorchMode:AVCaptureTorchModeAuto];
      }
    }
    
    if ([device hasFlash])
    {
      if ((device.flashMode ==  AVCaptureFlashModeAuto) || (device.flashMode ==  AVCaptureFlashModeOn))
      {
        [device setFlashMode:AVCaptureFlashModeOff];
      }
      else
      {
        [device setFlashMode:AVCaptureFlashModeAuto];
      }
    }
    [device unlockForConfiguration];
  }
}

- (void)cameraInit
{
  [self initFlash];
  
  if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
  {
    [self.imgPicker viewWillDisappear:NO];
    [self.imgPicker.view removeFromSuperview];
    [self.imgPicker viewDidDisappear:NO];
    self.imgPicker = [[[ZBarReaderViewController alloc] init] autorelease];
    
    self.imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imgPicker.readerDelegate = self;
    self.imgPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    self.imgPicker.readerView.zoom = 1.0;
    self.imgPicker.readerView.tracksSymbols = YES;
    self.imgPicker.readerView.trackingColor = [UIColor redColor];
    
    self.imgPicker.showsCameraControls = NO;
    self.imgPicker.showsZBarControls = NO;

    self.imgPicker.view.frame = self.view.bounds;
    self.imgPicker.readerView.frame = self.view.bounds;
    
    
    [self.imgPicker viewWillAppear:YES];
    [self.view addSubview:self.imgPicker.view];
    [self.imgPicker viewDidAppear:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
  }
  else
  {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"mBC_noCameraErrorAlertTitle", @"No Camera Available")
                                                    message:NSLocalizedString(@"mBC_noCameraErrorAlertMessage", @"Requires a camera to take pictures")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"mBC_noCameraErrorAlertOkButtonTitle", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    return;
  }
}

#pragma mark - Controls delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self.navigationController popViewControllerAnimated:YES];
}



- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
  [[self.imgPicker readerView] stop];
  
  ZBarSymbol *symbol = nil;
  
  for (symbol in results)
    break;
  
  [self.result removeFromSuperview];
  self.result = [[[UITextView alloc] initWithFrame:self.view.bounds] autorelease];
  self.result.textAlignment = NSTextAlignmentLeft;
  self.result.editable = NO;
  self.result.backgroundColor = [UIColor blackColor];
  self.result.textColor = [UIColor yellowColor];
  self.result.font = [UIFont fontWithName:@"Verdana" size:20.0f];
  [picker.view addSubview:self.result];
  
  NSString *firstButton = [[[NSString alloc] init] autorelease];
  
  if(symbol.data != nil)
  {
    if([symbol.data hasPrefix:@"http://"] ||
       [symbol.data hasPrefix:@"https://"])
    {
      firstButton = NSLocalizedString(@"mBC_openInBrowser", @"Open in a browser");
      self.URLString = [[symbol.data copy] autorelease];
    }
    else
    {
      firstButton =  NSLocalizedString(@"mBC_webSearch", @"Web search");
      NSString * encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)symbol.data, NULL, (CFStringRef)@"!*'();:@&=$,/?%#[]", kCFStringEncodingUTF8 );
      self.URLString = [[[@"http://www.google.com/search?q=" stringByAppendingString:encodedString] copy] autorelease];
      [encodedString release];
    }
    self.result.text = symbol.data;
  }
  
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"mBC_shareCancel", @"Cancel")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:firstButton,
                                NSLocalizedString(@"mBC_shareEmail", @"Share via EMail"),
                                NSLocalizedString(@"mBC_shareSMS", @"Share via SMS"),
                                nil];
  
  [actionSheet showFromToolbar:self.navigationController.toolbar];
  [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self initFlash];
  [self.presentedViewController dismissModalViewControllerAnimated:NO];
  switch (buttonIndex)
  {
    case 0:
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.URLString]];
      [[self.imgPicker readerView] start];
      break;
    case 1:
      [functionLibrary callMailComposerWithRecipients:nil
                                           andSubject:NSLocalizedString(@"mBC_shareEmailSubject", @"Scanned QR-code from iPhone / iBuildApp")
                                              andBody:self.result.text
                                               asHTML:YES
                                       withAttachment:nil
                                             mimeType:@""
                                             fileName:@""
                                       fromController:self
                                             showLink:showLink];
      break;
    case 2:
      [functionLibrary callSMSComposerWithRecipients:nil
                                             andBody:self.result.text
                                      fromController:self];
      break;
    default:
      [[self.imgPicker readerView] start];
      break;
  }
  [self.result removeFromSuperview];
  self.result = nil;
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)composeResult
{
  [[self.imgPicker readerView] start];
  [self dismissModalViewControllerAnimated:YES];
}


- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)composeResult
                        error:(NSError *)error
{
  [[self.imgPicker readerView] start];
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
    // hide tabbar
  self.tabBarIsHidden = [[self.tabBarController tabBar] isHidden];
  if ( !self.tabBarIsHidden )
    [[self.tabBarController tabBar] setHidden:YES];
  
  [self.navigationItem setHidesBackButton:NO animated:NO];
  [self.navigationController setNavigationBarHidden:NO animated:animated];
  [[self.navigationController navigationBar] setBarStyle:UIBarStyleDefault];
  [[self.navigationController navigationBar] setOpaque  :YES];
  [[self.navigationController navigationBar] setAlpha   :1.f];
  [self cameraInit];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self initFlash];
  [[self.imgPicker readerView] stop];
  [self.imgPicker viewWillDisappear:NO];
  [[self.tabBarController tabBar] setHidden:self.tabBarIsHidden];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self.imgPicker viewDidDisappear:NO];
  [super viewDidDisappear:animated];
}

#pragma mark - Interface orientation handlers

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

@end