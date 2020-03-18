#import <WebKit/WebKit.h>

#import "CDVDecimalKeyboard.h"
#import <Cordova/CDVAvailability.h>
#import <Cordova/NSDictionary+CordovaPreferences.h>

@implementation CDVDecimalKeyboard

UIView* keyPlane; // view to which we will add button
CGRect customButtonRect;
UIColor* customButtonBGColor;
UIButton *customButton;
BOOL isAppInBackground=NO;
NSString *customButtonType;

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillAppear:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillDisappear:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    customButtonBGColor = [UIColor clearColor];
}

- (void) appWillResignActive: (NSNotification*) n{
    isAppInBackground = YES;
    [self removeCustomButton];
}

- (void) appDidBecomeActive: (NSNotification*) n{
    if(isAppInBackground == YES){
        isAppInBackground = NO;
        [self processKeyboardShownEvent];
    }
}

- (void) keyboardWillDisappear: (NSNotification*) n {
    [self removeCustomButton];
}

- (void) setDecimalChar {
    [self evaluateJavaScript:@"DecimalKeyboard.getDecimalChar();"
           completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
               if (response) {
                   customButton.titleLabel.font = [UIFont systemFontOfSize:40.0];
                   [customButton setTitleEdgeInsets:UIEdgeInsetsMake(-20.0f, 0.0f, 0.0f, 0.0f)];
                   [customButton setTitle:response forState:UIControlStateNormal];
               }
           }];
}

- (void) setDoneTitle {
    [self evaluateJavaScript:@"DecimalKeyboard.getDoneTitle();"
           completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
//               NSLog(@"%@ DecimalKeyboard.getDoneTitle", response);
               if (response) {
                   customButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
                   [customButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
                   [customButton setTitle:response forState:UIControlStateNormal];
               }
           }];
}

- (void) addCustomButton {
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        return ; /* Device is iPad and this code works only in iPhone*/
    }
    customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if([customButtonType isEqualToString:@"done-button"]){
        [self setDoneTitle];
    } else {
        [self setDecimalChar];
    }

    NSDictionary *settings = self.commandDelegate.settings;

    if ([settings cordovaBoolSettingForKey:@"KeyboardAppearanceDark" defaultValue:NO]) {
        [customButton setTitleColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    } else {
        [customButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }

    [customButton addTarget:self action:@selector(buttonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    [customButton addTarget:self action:@selector(buttonTapped:)
            forControlEvents:UIControlEventTouchDown];
    [customButton addTarget:self action:@selector(buttonPressCancel:)
            forControlEvents:UIControlEventTouchUpOutside];

    customButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    customButton.layer.cornerRadius = 10;
    customButton.clipsToBounds = YES;

    // locate keyboard view
    UIWindow* tempWindow = nil;
    NSArray* openWindows = [[UIApplication sharedApplication] windows];

    for(UIWindow* object in openWindows){
        if([[object description] hasPrefix:@"<UIRemoteKeyboardWindow"] == YES){
            tempWindow = object;
        }
    }

    if(tempWindow ==nil){
        //for ios 8
        for(UIWindow* object in openWindows){
            if([[object description] hasPrefix:@"<UITextEffectsWindow"] == YES){
                tempWindow = object;
            }
        }
    }

    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        customButtonRect = CGRectMake(0.0, 0.0, 0.0, 0.0);
        [self calculateCustomButtonRect:keyboard];
//        NSLog(@"Positioning customButton at %@", NSStringFromCGRect(customButtonRect));
        customButton.frame = customButtonRect;
        [keyPlane addSubview:customButton];
    }
}

- (void) removeCustomButton{
    [customButton removeFromSuperview];
    customButton=nil;
    customButtonType=nil;
}

- (void) keyboardWillAppear: (NSNotification*) n{
    NSDictionary* info = [n userInfo];
    NSNumber* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double dValue = [value doubleValue];

//    NSLog(@"keyboardWillAppear");

    if (0.0 <= dValue) {
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * dValue);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self processKeyboardShownEvent];
        });
    }
}

- (void) processKeyboardShownEvent{
    [self isDecimalOrDone:^(NSString* buttonType) {
        // create custom button
//         NSLog(@"buttonType %@", buttonType);
        customButtonType = buttonType;

        if( customButton == nil ) {
            if([buttonType isEqualToString:@"done-button"] || [buttonType isEqualToString:@"decimal-char"]){
                [self addCustomButton];
            }
        }else{
            if([buttonType isEqualToString:@"done-button"]){
                customButton.hidden=NO;
                [self setDoneTitle];
            } else if([buttonType isEqualToString:@"decimal-char"]){
                customButton.hidden=NO;
                [self setDecimalChar];
            } else{
                [self removeCustomButton];
            }
        }
    }];
}

- (void)buttonPressed:(UIButton *)button {
    [customButton setBackgroundColor: customButtonBGColor];

    if([customButtonType isEqualToString:@"done-button"]){
        [self evaluateJavaScript:@"DecimalKeyboard.onDoneClick();" completionHandler:nil];

    } else if ([customButtonType isEqualToString:@"decimal-char"]){
        [self evaluateJavaScript:@"DecimalKeyboard.addDecimal();" completionHandler:nil];
    }
}

- (void)buttonTapped:(UIButton *)button {
    // [decimalButton setBackgroundColor:UIColor.whiteColor];
}
- (void)buttonPressCancel:(UIButton *)button{
    [customButton setBackgroundColor:customButtonBGColor];
}

- (void) isDecimalOrDone:(void (^)(NSString* buttonType))completionHandler {
    [self evaluateJavaScript:@"DecimalKeyboard.getActiveElementType();"
       completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
           if([response isEqualToString:@"done-button"]) {
               completionHandler(response);
           } else if ([response isEqualToString:@"decimal-char"])  {
               completionHandler(response);
           }
           else {
               completionHandler(nil);
           }
       }];
}



- (void)calculateCustomButtonRect:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if([[subview description] hasPrefix:@"<UIKBKeyplaneView"] == YES) {
            keyPlane = subview;
            for(UIView *v in subview.subviews) {
                if([[v description] hasPrefix:@"<UIKBKeyView"] == YES) {
                    if (customButtonRect.size.width == 0) {
                        customButtonRect = v.frame;  // Initialize by copying button frame
                    } else {
                        customButtonRect.origin.x = MIN(customButtonRect.origin.x, v.frame.origin.x);
                        customButtonRect.origin.y = MAX(customButtonRect.origin.y, v.frame.origin.y);
                        customButtonRect.size.height = MAX(customButtonRect.size.height, v.frame.size.height);
                        customButtonRect.size.width = MAX(customButtonRect.size.width, v.frame.size.width);
                    }
                }
            }
        }
        [self calculateCustomButtonRect:subview];
    }
}

- (void) evaluateJavaScript:(NSString *)script
          completionHandler:(void (^ _Nullable)(NSString * _Nullable response, NSError * _Nullable error))completionHandler {

    if ([self.webView isKindOfClass:WKWebView.class]) {
        WKWebView *webview = (WKWebView*)self.webView;
        [webview evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
            if (completionHandler) {
                if (error) completionHandler(nil, error);
                else completionHandler([NSString stringWithFormat:@"%@", result], nil);
            }
        }];
    }
    
}

@end
