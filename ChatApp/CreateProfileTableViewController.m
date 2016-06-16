//
//  CreateProfileTableViewController.m
//  PostLo
//
//  Created by Dominick Oddo on 11/15/15.
//  Copyright © 2015 ILGOS LLC. All rights reserved.
//

#import "CreateProfileTableViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface CreateProfileTableViewController () <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) IBOutlet PFImageView *imageView;
@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UIButton *addPhotoButton;
@property (strong, nonatomic) UITableViewCell *usernameCell;
@property (strong, nonatomic) UILabel *usernameErrorLabel;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) PFQuery *searchQuery;
@end

@implementation CreateProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (self.usernameTextField.text.length > 0 && self.imageView.image) {
        [self.doneButton setEnabled:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell1" forIndexPath:indexPath];
        self.imageView = (PFImageView *)[cell viewWithTag:1];
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imageView.layer.borderWidth = 0.5f;
        
        PFUser *currentUser = [PFUser currentUser];
        if ([currentUser objectForKey:@"photo"]) {
            self.imageView.file = [currentUser objectForKey:@"photo"];
            [self.imageView loadInBackground];
            [self.addPhotoButton setTitle: @"" forState: UIControlStateNormal];
        }
        else {
            self.addPhotoButton = (UIButton *)[cell viewWithTag:2];
            self.addPhotoButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.addPhotoButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            [self.addPhotoButton setTitle: @"Add\nPhoto" forState: UIControlStateNormal];
            [self.addPhotoButton addTarget:self
                                    action:@selector(clickedAddPhoto)
                          forControlEvents:UIControlEventTouchUpInside];
        }
    }
    if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UsernameCell" forIndexPath:indexPath];
        self.usernameTextField = (UITextField *)[cell viewWithTag:1];
        self.usernameTextField.delegate = self;
        [self.usernameTextField addTarget:self
                                   action:@selector(usernameTextFieldDidChange)
                         forControlEvents:UIControlEventEditingChanged];
        PFUser *currentUser = [PFUser currentUser];
        if ([currentUser objectForKey:@"displayUsername"]) {
            self.usernameTextField.text = [currentUser objectForKey:@"displayUsername"];
        }
        
        self.usernameCell = cell;
        self.usernameErrorLabel = (UILabel *)[cell viewWithTag:2];
        [self.usernameErrorLabel setHidden:YES];
    }
    return cell;
}

-(void)clickedAddPhoto {
    self.imagePickerController = [[UIImagePickerController alloc]init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = YES;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePickerController.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    [self presentViewController:self.imagePickerController animated:NO completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image=[info objectForKey:UIImagePickerControllerEditedImage];
    self.imageView.image = image;
    if (self.usernameTextField.text.length > 0 && self.imageView.image != nil) {
        [self.doneButton setEnabled:YES];
    }
    [self.addPhotoButton setTitle:@"" forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self clickedDone:nil];
    return YES;
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedDone:(id)sender {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [activityIndicator setColor:[UIColor colorWithRed:0.0/255 green:122.0/255 blue:255.0/255 alpha:1]];
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [activityIndicator startAnimating];
    NSString *displayUsername = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.image = self.imageView.image;
    if (self.image == nil) {
        self.navigationItem.rightBarButtonItem = self.doneButton;
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Profile Photo"
                                      message:@"Choose a profile photo to continue."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        PFUser *currentUser = [PFUser currentUser];
        [currentUser setObject:displayUsername forKey:@"displayUsername"];
        PFFile *photoFile;
        UIImage *newImage = [self resizeImage:self.imageView.image toWidth:500.0f andHeight:500.0f];
        NSData *imageData = UIImageJPEGRepresentation(newImage, 0.87f);
        photoFile = [PFFile fileWithName:@"image.png" data:imageData];
        [currentUser setObject:photoFile forKey:@"photo"];
        [currentUser setObject:@"YES" forKey:@"hasInfo"];
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@ %@", error, [error userInfo]);
                [self.usernameCell setBackgroundColor:[UIColor colorWithRed:255.0/255 green:0.0/255 blue:0.0/255 alpha:1.0f]];
                [self.usernameErrorLabel setHidden:NO];
                self.usernameTextField.textColor = [UIColor whiteColor];
                self.navigationItem.rightBarButtonItem = self.doneButton;
                [self.doneButton setEnabled:NO];
            }
            if (succeeded) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = self.doneButton;
            }
        }];
    }
}

-(UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height {
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 25;
}

-(void)usernameTextFieldDidChange {
    if (self.usernameTextField.text.length > 0 && self.imageView.image != nil) {
        [self.doneButton setEnabled:YES];
    }
    [self.usernameErrorLabel setHidden:YES];
    if (self.usernameTextField.text.length > 0) {
        [self.usernameErrorLabel setHidden:YES];
        [self.usernameCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else {
        [self.doneButton setEnabled:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 106.0f;
    }
    if (indexPath.row == 1) {
        return 50.0f;
    }
    return 50;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
