//
//  SMTPController.h
//  SMTPKit
//
//  Created by Geoff Pado on 10/19/09.
//  Copyright 2009 Cocoatype, LLC. All rights reserved.
//

#import "AsyncSocket.h"
#import "SMTPMessage.h"

static NSString *const SMTPControllerErrorNoUsername = @"SMTPControllerErrorNoUsername"; // 104
static NSString *const SMTPControllerErrorNoPassword = @"SMTPControllerErrorNoPassword"; // 105
static NSString *const SMTPControllerErrorNoOpenConnection = @"SMTPControllerErrorNoOpenConnection"; // 106
static NSString *const SMTPControllerErrorCantConnect = @"SMTPControllerErrorCantConnect"; // 107

@interface SMTPController : NSObject
{
	AsyncSocket *connectSocket;
	NSMutableArray *commandQueue;
	BOOL queueBlocking;

	NSString *_username;
	NSString *_password;
}

@property(readwrite, retain) NSString *username;
@property(readwrite, retain) NSString *password;

+ (SMTPController *)controllerWithUsername:(NSString *)username password:(NSString *)password; // Convenience method to initialize a controller

- (BOOL)openSMTPConnectionToHost:(NSString *)host error:(NSError **)error; // Opens up an SMTP Connection to the host

//common methods
- (BOOL)authenticateWithError:(NSError **) error; // Authenticates with the SMTP server. Doesn't check responses for errors yet.
- (void)quit; // Quits the SMTP connection
- (BOOL)sendMessage:(SMTPMessage *)newMessage error:(NSError **) error; // Sends a message
- (BOOL)authenticateAndSendMessage:(SMTPMessage *)newMessage error:(NSError **) error; // Authenticates, sends the message and then quits

@end
