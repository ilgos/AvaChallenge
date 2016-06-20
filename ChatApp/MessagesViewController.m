//
//  MessagesViewController.m
//  ChatApp
//
//  Created by Dominick Oddo on 6/11/16.
//  Copyright © 2016 ILGOS LLC. All rights reserved.
//

#import "MessagesViewController.h"
#import "SKSConfiguration.h"

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpeechKit/SpeechKit.h>
#import <SpeechKit/SKTransaction.h>
#import <PubNub/PubNub.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MessagesViewController () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, SKTransactionDelegate, PNObjectEventListener, CBPeripheralManagerDelegate>
@property (nonatomic, strong) SKSession *skSession;
@property (nonatomic) PubNub *client;
@property (nonatomic, strong) SKTransaction *skTransaction;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *recordButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (strong, nonatomic) NSString *language;
@property (strong, nonatomic) NSString *recognitionType;
@property (nonatomic) BOOL isRecording;
@property (assign, nonatomic) SKTransactionEndOfSpeechDetection endpointer;
@property (strong, nonatomic) CLBeaconRegion *myBeaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDictionary *myBeaconData;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@end

@implementation MessagesViewController

@synthesize language = _language;
@synthesize recognitionType = _recognitionType;
@synthesize endpointer = _endpointer;

- (IBAction)emitBeacon:(id)sender {

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];

    self.myBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                  major:1
                                                                  minor:1
                                                             identifier:self.conversation.objectId];
    
    // pubnub stuff
    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-c14e87ca-0f8e-4bd8-baeb-46ef3f67e798"
                                                                     subscribeKey:@"sub-c-fec8eca2-33f6-11e6-9060-0619f8945a4f"];
    
    self.client = [PubNub clientWithConfiguration:configuration];
    [self.client addListener:self];
    NSString *conversationID = self.conversation.objectId;
    [self.client subscribeToChannels: @[conversationID] withPresence:NO];
    
    self.title = @"Ava";
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    [self.inputToolbar setHidden:YES];
    self.navigationController.toolbarHidden = NO;
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self senderId];
        [self senderDisplayName];
        [self loadMessages];
        _recognitionType = SKTransactionSpeechTypeDictation;
        _endpointer = SKTransactionEndOfSpeechDetectionShort;
        _language = @"eng-USA";
        
        self.skSession = [[SKSession alloc] initWithURL:[NSURL URLWithString:SKSServerUrl] appToken:SKSAppKey];
    }
}

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    
    // Handle new message stored in message.data.message
    if (message.data.actualChannel) {
        
        // Message has been received on channel group stored in
        // message.data.subscribedChannel
    }
    else {
        
        // Message has been received on channel stored in
        // message.data.subscribedChannel
    }
    NSLog(@"Received message: %@ on channel %@ at %@", message.data.message,
          message.data.subscribedChannel, message.data.timetoken);
    
    NSString *senderId = [message.data.message objectForKey:@"senderId"];
    if (![senderId isEqualToString:self.senderId]) {
        NSString *senderDisplayName = [message.data.message objectForKey:@"senderDisplayName"];
        NSString *text = [message.data.message objectForKey:@"text"];
        
        JSQMessage *jsqmessage = [[JSQMessage alloc] initWithSenderId:senderId
                                                    senderDisplayName:senderDisplayName
                                                                 date:[NSDate date]
                                                                 text:text];
        
        [self.messages addObject:jsqmessage];
        [self.collectionView reloadData];
        [self finishSendingMessageAnimated:YES];
    }
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    
    if (status.category == PNUnexpectedDisconnectCategory) {
        // This event happens when radio / connectivity is lost
    }
    
    else if (status.category == PNConnectedCategory) {
        
        // Connect event. You can do stuff like publish, and know you'll get it.
        // Or just use the connected event to confirm you are subscribed for
        // UI / internal notifications, etc
        
    }
    else if (status.category == PNReconnectedCategory) {
        
        // Happens as part of our regular operation. This event happens when
        // radio / connectivity is lost, then regained.
    }
    else if (status.category == PNDecryptionErrorCategory) {
        
        // Handle messsage decryption error. Probably client configured to
        // encrypt messages and on live data feed it received plain text.
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadMessages {
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"conversation" equalTo:self.conversation];
    [query includeKey:@"sender"];
    [query orderByAscending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@ %@", error, [error userInfo]);
        }
        if (objects) {
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            for (PFObject *object in objects) {
                PFUser *sender = [object objectForKey:@"sender"];
                NSDate *createdAt = object.createdAt;
                NSString *displayName = [sender objectForKey:@"displayUsername"];
                NSString *messageText = [object objectForKey:@"text"];
                JSQMessage *message = [[JSQMessage alloc] initWithSenderId:sender.objectId
                                                         senderDisplayName:displayName
                                                                      date:createdAt
                                                                      text:messageText];
                [tempArray addObject:message];
            }
            self.messages = tempArray;
            [self.collectionView reloadData];
            [self finishSendingMessageAnimated:YES];
        }
    }];
    
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 10 == 0) {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
//    if ([message.senderId isEqualToString:self.senderId]) {
//        return nil;
//    }
    
//    if (indexPath.item - 1 > 0) {
//        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
//        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
//            return nil;
//        }
//    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}


#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
//    if (indexPath.item % 3 == 0) {
//        return kJSQMessagesCollectionViewCellLabelHeightDefault;
//    }
//    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
//    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
//    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
//        return 0.0f;
//    }
    
//    if (indexPath.item - 1 > 0) {
//        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
//        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
//            return 0.0f;
//        }
//    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    // [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:@"321"
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    NSLog(@"%@", message);
    
    [self.messages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Attachment", nil)
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *sendPhoto = [UIAlertAction actionWithTitle:NSLocalizedString(@"Photo", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self addPhotoMediaMessage];
                                                         }];
    [alert addAction:sendPhoto];
    
    UIAlertAction *sendVideo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Video", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self addVideoMediaMessage];
                                                         }];
    [alert addAction:sendVideo];
    
    UIAlertAction *sendAudio = [UIAlertAction actionWithTitle:NSLocalizedString(@"Audio", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          [self addAudioMediaMessage];
                                                      }];
    [alert addAction:sendAudio];
    
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alert addAction:cancelButton];
    
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)addAudioMediaMessage
{
    NSString * sample = [[NSBundle mainBundle] pathForResource:@"jsq_messages_sample" ofType:@"m4a"];
    NSData * audioData = [NSData dataWithContentsOfFile:sample];
    JSQAudioMediaItem *audioItem = [[JSQAudioMediaItem alloc] initWithData:audioData];
    JSQMessage *audioMessage = [JSQMessage messageWithSenderId:@"123"
                                                   displayName:@"123"
                                                         media:audioItem];
    [self.messages addObject:audioMessage];
    [self finishSendingMessageAnimated:YES];
}

- (void)addPhotoMediaMessage
{
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:@"123"
                                                   displayName:@"123"
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
    [self finishSendingMessageAnimated:YES];
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:@"123"
                                                      displayName:@"123"
                                                            media:locationItem];
    [self.messages addObject:locationMessage];
    [self finishSendingMessageAnimated:YES];
}

- (void)addVideoMediaMessage
{
    NSURL *videoURL = [NSURL URLWithString:@"file://"];
    JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
    JSQMessage *videoMessage = [JSQMessage messageWithSenderId:@"123"
                                                   displayName:@"123"
                                                         media:videoItem];
    [self.messages addObject:videoMessage];
    [self finishSendingMessageAnimated:YES];
}

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

- (IBAction)clearConversation:(id)sender {
    [self.messages removeAllObjects];
    [self.collectionView reloadData];
}

- (IBAction)startRecording:(id)sender {
    if ([self.recordButton.title isEqualToString:@"Record"]) {
        [self.recordButton setTitle:@"Stop"];
        NSLog(@"recording");
        self.isRecording = YES;
        self.skTransaction = [_skSession recognizeWithType:self.recognitionType
                                             detection:self.endpointer
                                              language:self.language
                                              delegate:self];
    }
    else {
        self.isRecording = NO;
        [self.recordButton setTitle:@"Record"];
        [self.skTransaction stopRecording];
        [self resetTransaction];
        NSLog(@"stopped");
    }
}


# pragma mark - SKTransactionDelegate

- (void)transactionDidBeginRecording:(SKTransaction *)transaction
{
    [self log:@"transactionDidBeginRecording"];
}

- (void)transactionDidFinishRecording:(SKTransaction *)transaction
{
    [self log:@"transactionDidFinishRecording"];
}

- (void)transaction:(SKTransaction *)transaction didReceiveRecognition:(SKRecognition *)recognition
{
    [self log:[NSString stringWithFormat:@"didReceiveRecognition: %@", recognition.text]];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                             senderDisplayName:self.senderDisplayName
                                                          date:[NSDate date]
                                                          text:recognition.text];
    NSLog(@"%@", message);
    
    PFObject *newMessage = [PFObject objectWithClassName:@"Message"];
    [newMessage setObject:[PFUser currentUser] forKey:@"sender"];
    [newMessage setObject:recognition.text forKey:@"text"];
    [newMessage setObject:self.conversation forKey:@"conversation"];
    [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"succeeded");
            NSDictionary *messageDictionary = @{@"channel" : self.conversation.objectId,
                                                @"text" : recognition.text,
                                                @"senderId" : [PFUser currentUser].objectId,
                                                @"senderDisplayName" : [[PFUser currentUser] objectForKey:@"displayUsername"]};
            
            [self.client publish:messageDictionary toChannel:self.conversation.objectId
                  withCompletion:^(PNPublishStatus *status) {
                      
                      // Check whether request successfully completed or not.
                      if (!status.isError) {
                          NSLog(@"successfully sent publish method with text %@", recognition.text);
                          // Message successfully published to specified channel.
                      }
                      // Request processing failed.
                      else {
                          
                          // Handle message publish error. Check 'category' property to find out possible issue
                          // because of which request did fail.
                          //
                          // Request can be resent using: [status retry];
                      }
                  }];
        }
    }];
    
    [self.messages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}

- (void)transaction:(SKTransaction *)transaction didReceiveServiceResponse:(NSDictionary *)response
{
    [self log:[NSString stringWithFormat:@"didReceiveServiceResponse: %@", response]];
}

- (void)transaction:(SKTransaction *)transaction didFinishWithSuggestion:(NSString *)suggestion
{
    [self log:@"didFinishWithSuggestion"];
    
    if (self.isRecording) {
        [self startTransactionAgain];
    }
}

-(void)startTransactionAgain {
    self.skTransaction = [_skSession recognizeWithType:self.recognitionType
                                             detection:self.endpointer
                                              language:self.language
                                              delegate:self];
}

- (void)transaction:(SKTransaction *)transaction didFailWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    [self log:[NSString stringWithFormat:@"didFailWithError: %@. %@", [error description], suggestion]];
    
    if (self.isRecording) {
        [self startTransactionAgain];
    }
}



#pragma mark - Helpers

- (void)log:(NSString *)message
{
    NSLog(@"%@", message);
//    self.logTextView.text = [self.logTextView.text stringByAppendingFormat:@"%@\n", message];
}

- (void)resetTransaction
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.skTransaction = nil;
//        [_toggleRecogButton setTitle:@"recognizeWithType" forState:UIControlStateNormal];
//        [_toggleRecogButton setEnabled:YES];
    }];
}

- (void)loadEarcons
{
    // Load all of the earcons from disk
    
    NSString* startEarconPath = [[NSBundle mainBundle] pathForResource:@"sk_start" ofType:@"pcm"];
    NSString* stopEarconPath = [[NSBundle mainBundle] pathForResource:@"sk_stop" ofType:@"pcm"];
    NSString* errorEarconPath = [[NSBundle mainBundle] pathForResource:@"sk_error" ofType:@"pcm"];
    
    SKPCMFormat* audioFormat = [[SKPCMFormat alloc] init];
    audioFormat.sampleFormat = SKPCMSampleFormatSignedLinear16;
    audioFormat.sampleRate = 16000;
    audioFormat.channels = 1;
    
    // Attach them to the session
    
    _skSession.startEarcon = [[SKAudioFile alloc] initWithURL:[NSURL fileURLWithPath:startEarconPath] pcmFormat:audioFormat];
    _skSession.endEarcon = [[SKAudioFile alloc] initWithURL:[NSURL fileURLWithPath:stopEarconPath] pcmFormat:audioFormat];
    _skSession.errorEarcon = [[SKAudioFile alloc] initWithURL:[NSURL fileURLWithPath:errorEarconPath] pcmFormat:audioFormat];
}


// sender ID and sender display name

- (NSString *)senderId {
    if ([PFUser currentUser]) {
        return [PFUser currentUser].objectId;
    }
    return @"no one ID";
}

- (NSString *)senderDisplayName {
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        return [currentUser objectForKey:@"displayUsername"];
    }
    return @"no one";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
