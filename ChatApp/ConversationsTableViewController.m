//
//  ConversationsTableViewController.m
//  ChatApp
//
//  Created by Dominick Oddo on 6/15/16.
//  Copyright © 2016 ILGOS LLC. All rights reserved.
//

#import "ConversationsTableViewController.h"
#import "CreateProfileTableViewController.h"
#import "MessagesViewController.h"

#import <Parse/Parse.h>

@interface ConversationsTableViewController ()
@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, strong) PFObject *selectedConversation;
@end

@implementation ConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        PFInstallation *installation = [PFInstallation currentInstallation];
        [installation setObject:[PFUser currentUser] forKey:@"user"];
        [installation setObject:[PFUser currentUser].objectId forKey:@"userObjectID"];
        [installation saveInBackground];
        [[PFUser currentUser] incrementKey:@"RunCount"];
        [[PFUser currentUser] saveInBackground];
        [self retrieveConversations];
        
    }
    else {
        [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
            if (user) {
                [[PFUser currentUser] incrementKey:@"RunCount"];
                PFInstallation *installation = [PFInstallation currentInstallation];
                [installation setObject:[PFUser currentUser] forKey:@"user"];
                [installation setObject:[PFUser currentUser].objectId forKey:@"userObjectID"];
                [installation saveInBackground];
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self retrieveConversations];
                    }
                }];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)retrieveConversations {
    PFQuery *query = [PFQuery queryWithClassName:@"Conversation"];
    [query includeKey:@"creator"];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            NSLog(@"%@", objects);
            self.conversations = (NSMutableArray *)objects;
            [self.tableView reloadData];
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    PFObject *conversation = [self.conversations objectAtIndex:indexPath.row];
    cell.textLabel.text = [conversation objectForKey:@"name"];
    NSDate *now = [NSDate date];
    cell.detailTextLabel.text = [self stringWithStartDate:conversation.createdAt andEndDate:now];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFUser *currentUser = [PFUser currentUser];
    if ([[currentUser objectForKey:@"hasInfo"] isEqualToString:@"YES"]){
        self.selectedConversation = [self.conversations objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"showConversation" sender:self];
    }
    else {
        NSString *alertTitle = @"User Info";
        NSString *alertMessage = @"You need to add a photo and a display name before entering a conversation";
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:alertTitle
                                              message:alertMessage
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *create = [UIAlertAction
                                 actionWithTitle:@"Create"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *action)
                                 {
                                     [self showSettings:nil];
                                 }];
        
        [alertController addAction:create];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * _Nonnull action) {
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                 }];
        
        [alertController addAction:cancel];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0f;
}

- (IBAction)createNewConversation:(id)sender {
    NSString *alertTitle = @"New Conversation";
    NSString *alertMessage = @"Type in the name of the conversation you want to create below";
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:alertTitle
                                          message:alertMessage
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"Conversation name";
     }];
    
    UIAlertAction *create = [UIAlertAction
                            actionWithTitle:@"Create"
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action)
                            {
                               PFUser *currentUser = [PFUser currentUser];
                               UITextField *textField = alertController.textFields.firstObject;
                               NSString *convoName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                               PFObject *convoObject = [PFObject objectWithClassName:@"Conversation"];
                               [convoObject setObject:convoName forKey:@"name"];
                               [convoObject setObject:currentUser forKey:@"creator"];
                               [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                   if (error) {
                                       NSLog(@"%@ %@", error, [error userInfo]);
                                   }
                                   if (succeeded) {
                                       [self.conversations insertObject:convoObject atIndex:0];
                                       [self.tableView reloadData];
                                   }
                               }];
                            }];
    
    [alertController addAction:create];
    
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * _Nonnull action) {
                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(NSString *)stringWithStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate {
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSInteger second = [components second];
    NSString *timeSince;
    if (hour >= (24 * 7)) {
        timeSince = [NSString stringWithFormat:@"%ldw", (long) hour / (24 * 7)];
    }
    else if (hour >= 24) {
        timeSince = [NSString stringWithFormat:@"%ldd", (long)hour / 24];
    }
    else if (hour >= 1) {
        timeSince = [NSString stringWithFormat:@"%ldh", (long)hour];
    }
    else if (minute >= 1) {
        timeSince = [NSString stringWithFormat:@"%ldm", (long)minute];
    }
    else {
        if (second == 0) {
            timeSince = @"1s";
        }
        else {
            timeSince = [NSString stringWithFormat:@"%lds", (long)second];
        }
    }
    return timeSince;
}

- (IBAction)showSettings:(id)sender {
    CreateProfileTableViewController  *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateProfileTableViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MessagesViewController *destinationController = (MessagesViewController *)segue.destinationViewController;
    destinationController.conversation = self.selectedConversation;
}


@end
