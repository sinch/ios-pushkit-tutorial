#import "LoginViewController.h"
#import "AppDelegate.h"

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.nameTextField becomeFirstResponder];
}

- (IBAction)onLoginButtonPressed:(id)sender {

  if ([self.nameTextField.text length] == 0) {
    return;
  }

  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"starting client");
  [appDelegate initSinchClientWithUserId:self.nameTextField.text];
  [self performSegueWithIdentifier:@"mainView" sender:nil];
}

@end
