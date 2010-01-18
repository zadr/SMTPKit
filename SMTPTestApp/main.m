//
//  main.m
//  SMTPTest
//
//  Created by Geoff Pado on 10/19/09.
//  Copyright 2009 Cocoatype, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SMTPKit/SMTPKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;

	SMTPController *controller = [[SMTPController alloc] init];
	[controller setUsername:@"user@domain.com"];
	[controller setPassword:@"mypass"];

	[controller openSMTPConnectionToHost:@"mail.domain.com" error:&error];

	SMTPMessage *newMessage = [[SMTPMessage alloc] init];
	[newMessage setFromAddress:@"user@domain.com"];
	[newMessage addRecipient:@"bob@gmail.com"];
	[newMessage setSubject:@"Test Message"];
	[newMessage setBody:@"This is a test message."];

	[controller sendMessage:newMessage error:&error];
	[controller quit];

	[newMessage release];
	[controller release];

	// Or

	controller = [SMTPController controllerWithUsername:@"user@domain.com" password:@"mypass"];
	[controller openSMTPConnectionToHost:@"mail.domain.com" error:&error];

	newMessage = [SMTPMessage messageFromAddress:@"user@domain.com" recipients:[NSMutableArray arrayWithObjects:@"john@apple.com", @"bob@gmail.com", @"joe@yahoo.com", nil] subject:@"Test Message" body:@"Test Body"];

	if (![controller authenticateAndSendMessage:newMessage error:&error]) {
		NSLog(@"Error sending message: %@", error);
	}

	[pool release];

    return 0;
}