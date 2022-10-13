//
//  SendViewController_objc.m
//  SendWithRemitly
//
//  Created by Nick Hodapp on 9/29/22.
//

#import "SendViewController_objc.h"

@interface SendViewController_objc ()

@end

@implementation SendViewController_objc
{
    IBOutlet UITextView* _eventsLog;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [RECEConfiguration loadConfig];
    [RECEConfiguration setCustomerEmail: @"nick+0618@remitly.com"];
    
    if (@available(iOS 15.0, *)) {
        for (UIButton* b in self.view.subviews) {
            if ([b isKindOfClass: [UIButton class]]) {
                b.configuration = UIButtonConfiguration.filledButtonConfiguration;
            }
        }
    }
}

- (IBAction)onShowRemitly:(id)sender {
    RECEViewController* receVc = [RECEViewController new];
    receVc.delegate = self;
    [self presentViewController: receVc animated: YES completion: nil];
}

- (NSString*)timestamp {
    return [NSDateFormatter localizedStringFromDate: [NSDate date] dateStyle: NSDateFormatterShortStyle timeStyle: NSDateFormatterMediumStyle];
}

- (void)logEvent: (NSString*) event {
    [_eventsLog setText: [NSString stringWithFormat: @"%@ - %@\n%@", [self timestamp], event, [_eventsLog text]]];
}

- (void)onUserActivity {
    [self logEvent: @"onUserActivity"];
}

- (void)onTransferSubmitted {
    [self logEvent: @"onTransferSubmitted"];
}

@end
