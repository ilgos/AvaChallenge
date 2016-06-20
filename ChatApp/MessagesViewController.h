//
//  MessagesViewController.h
//  ChatApp
//
//  Created by Dominick Oddo on 6/11/16.
//  Copyright © 2016 ILGOS LLC. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "JSQMessages.h"

#import <Parse/Parse.h>

@interface MessagesViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) PFObject *conversation;
@property (nonatomic, strong) NSDictionary *users;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonnull, strong) NSMutableArray *parseMessageObjects;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end
