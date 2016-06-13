//
//  MessagesViewController.h
//  ChatApp
//
//  Created by Dominick Oddo on 6/11/16.
//  Copyright © 2016 ILGOS LLC. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import <JSQMessages.h>

@interface MessagesViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) NSDictionary *users;
@property (nonatomic, strong) NSMutableArray *messages;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end
