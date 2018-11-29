//
//  QCAbletonLinkSettingsViewController.m
//  Link
//
//  Created by Frank Hofmann on 27.11.18.
//

#import "QCAbletonLinkSettingsViewController.h"

@interface QCAbletonLinkSettingsViewController ()
-(IBAction)allow999:(NSButton*)btn;
@end

@implementation QCAbletonLinkSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
   
    /*
    NSButton *btn = [[NSButton alloc] initWithFrame:CGRectMake(10, 100, 100, 100)];
    btn.title = @"allow 999bpm";
    btn.target = self;
    btn.action = @selector(allow999:);
    [self.view addSubview:btn];
    
    NSButton *btn2 = [[NSButton alloc] initWithFrame:CGRectMake(110, 100, 100, 100)];
    btn2.title = @"What?";
    btn2.target = self;
    btn2.action = @selector(allow999:);
    [self.view addSubview:btn2];
     */
}
-(IBAction)allow999:(NSButton*)btn {
    NSAlert *alert = [NSAlert alertWithMessageText:@"blub" defaultButton:btn.title alternateButton:@"alternate" otherButton:@"other" informativeTextWithFormat:@"informational text"];
    [alert runModal];
}
@end
