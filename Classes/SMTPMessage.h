//
//  SMTPMessage.h
//  SMTPKit
//
//  Created by Geoff Pado on 10/23/09.
//  Copyright 2009 Cocoatype, LLC. All rights reserved.
//

static NSString *const STMPMessageErrorNoFromAddress = @"STMPMessageErrorNoFromAddress"; // 100
static NSString *const STMPMessageErrorNoRecipients = @"STMPMessageErrorNoRecipients"; // 101
static NSString *const SMTPMessageErrorNoSubject = @"SMTPMessageErrorNoSubject"; // 102
static NSString *const SMTPMessageErrorNoBody = @"SMTPMessageErrorNoBody"; // 103

@interface SMTPMessage : NSObject
{
	NSString *_fromAddress;
	NSMutableArray *_recipients;
	NSString *_subject;
	NSString *_body;
}

@property (nonatomic, retain) NSString *fromAddress;
@property (nonatomic, retain, readonly) NSMutableArray *recipients;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *body;

+ (SMTPMessage *)messageFromAddress:(NSString *)fromAddress recipients:(NSMutableArray *)recipients subject:(NSString *)subject body:(NSString *)body; // Convenience method to set up everything for the message at once

- (void)addRecipient:(NSString *)recipient; // Adds a recipient to the list, if the email is valid
- (void)removeRecipient:(NSString *)recipient; // Removes a recipient from the list, doesn't do anything if they're not in it.
- (void)clearRecipients; // Removes all recipients from the list

@end
