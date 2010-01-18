//
//  SMTPController.m
//  SMTPKit
//
//  Created by Geoff Pado on 10/19/09.
//  Copyright 2009 Cocoatype, LLC. All rights reserved.
//
//  Modified by Zach Drayer on 11/16/09.
//

#import "SMTPController.h"
#import "SMTPChecks.h"
#import "NSDataAdditions.h"

#define NUL 0

static NSString *lineEnd = @"\r\n";

@interface SMTPController (Internals)
- (void)beginDataSection;
@end

@implementation SMTPController

@synthesize username = _username, password = _password;

- (id)init
{
	if ((self = [super init])) {
		connectSocket = [[AsyncSocket alloc] initWithDelegate:self];
		commandQueue = [[NSMutableArray alloc] init];
		queueBlocking = YES;
	}

	return self;
}

+ (SMTPController *)controllerWithUsername:(NSString *)username password:(NSString *)password
{
	SMTPController *controller = [self init];

	if (controller) {
		controller.username = username;
		controller.password = password;

		self = controller;
	}

	return [self autorelease];
}

#pragma mark Queue Division

- (void)addToQueue:(NSString *)command
{
	if (queueBlocking == NO && [connectSocket isConnected] == YES) {
		[connectSocket writeData:[command dataUsingEncoding:NSASCIIStringEncoding] withTimeout:5.00 tag:0];
	}

	else {
		[commandQueue addObject:command];
	}
}

- (void)runNextCommand
{
	if ([connectSocket isConnected] == NO) {
		return;
	}

	if ([commandQueue count] > 0) {
		[connectSocket writeData:[[commandQueue objectAtIndex:0] dataUsingEncoding:NSASCIIStringEncoding] withTimeout:5.00 tag:0];
		[commandQueue removeObjectAtIndex:0];
	}

	else {
		queueBlocking = NO;
	}
}

#pragma mark Connection Control

- (BOOL)openSMTPConnectionToHost:(NSString *)host port:(UInt16) port error:(NSError **)error {
	if (![SMTPChecks canReachHost:host port:port]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:SMTPControllerErrorCantConnect code:107 userInfo:nil];
		}
		return NO;
	}
	
	[connectSocket connectToHost:host onPort:port error:nil];
	queueBlocking = YES;
	
	return YES;
	
}

- (BOOL)openSMTPConnectionToHost:(NSString *)host error:(NSError **)error
{
	return [self openSMTPConnectionToHost:host port:25 error:error];
}

- (void)introduce
{
	NSString *ehloString = nil;

	if ([connectSocket isConnected] == NO) {
		ehloString = [NSString stringWithFormat:@"EHLO localhost%@", lineEnd];
	}

	else {
		ehloString = [NSString stringWithFormat:@"EHLO %@%@", [connectSocket localHost], lineEnd];
	}

	[self addToQueue:ehloString];
}

- (BOOL)authenticateWithError:(NSError **) error
{
	if (!_username) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:SMTPControllerErrorNoUsername code:104 userInfo:nil];
		}

		_username = @"";
	}

	if (!_password) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:SMTPControllerErrorNoPassword code:105 userInfo:nil];
		}

		_password = @"";
	}

	if ([connectSocket isConnected] == NO) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:SMTPControllerErrorNoOpenConnection code:106 userInfo:nil];
		}

		return NO;
	}
	
	NSString *base64AuthString = [[[NSString stringWithFormat:@"%C%@%C%@", NUL, _username, NUL, _password] dataUsingEncoding:NSASCIIStringEncoding] base64EncodedString];
	NSString *authRequest = [NSString stringWithFormat:@"AUTH PLAIN %@%@", base64AuthString, lineEnd];
	[self addToQueue:authRequest];

	return YES;
}

- (void)quit
{
	[self addToQueue:[NSString stringWithFormat:@"QUIT%@", lineEnd]];
}

- (BOOL)beginMessageFromAddress:(NSString *)fromAddress
{
	if (!fromAddress.length) {
		return NO;
	}

	[self addToQueue:[NSString stringWithFormat:@"MAIL FROM:%@%@", fromAddress, lineEnd]];

	return YES;
}

- (BOOL)addRecipientAtAddress:(NSString *)recipient
{
	if (!recipient.length) {
		return NO;
	}

	if (![SMTPChecks validEmail:recipient])
		return NO;

	[self addToQueue:[NSString stringWithFormat:@"RCPT TO:%@%@", recipient, lineEnd]];

	return YES;
}

- (BOOL)sendMessage:(SMTPMessage *)newMessage error:(NSError **)error
{
	[self introduce];

	// If needed, error gets its value set in authenticateWithError, so we don't need to set it again in here
	if (![self authenticateWithError:error]) {
		return NO;
	}

	if (!newMessage.fromAddress.length) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:STMPMessageErrorNoFromAddress code:100 userInfo:[NSDictionary dictionaryWithObject:newMessage forKey:@"message"]];
		}

		return NO;
	}

	[self beginMessageFromAddress:[newMessage fromAddress]];

	if (!newMessage.recipients.count) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:STMPMessageErrorNoRecipients code:101 userInfo:[NSDictionary dictionaryWithObject:newMessage forKey:@"message"]];
		}

		return NO;
	}

	for (NSString *recipient in [newMessage recipients]) {
		[self addRecipientAtAddress:recipient];
	}

	[self beginDataSection];

	NSString *dataString = [NSString stringWithFormat:@""];
	dataString = [dataString stringByAppendingFormat:@"From: %@%@", [newMessage fromAddress], lineEnd];

	if ([newMessage subject] != nil) {
		dataString = [dataString stringByAppendingFormat:@"Subject: %@%@", [newMessage subject], lineEnd];
		if (error != NULL)
			*error = [NSError errorWithDomain:SMTPMessageErrorNoSubject code:102 userInfo:[NSDictionary dictionaryWithObject:newMessage forKey:@"message"]];
	}

	if ([newMessage body] != nil) {
		dataString = [dataString stringByAppendingFormat:@"%@", [newMessage body]];
		if (error != NULL)
			*error = [NSError errorWithDomain:SMTPMessageErrorNoBody code:103 userInfo:[NSDictionary dictionaryWithObject:newMessage forKey:@"message"]];
	}

	dataString = [dataString stringByAppendingFormat:@"%@.%@", lineEnd, lineEnd];

	[self addToQueue:dataString];

	return YES;
}

- (BOOL)authenticateAndSendMessage:(SMTPMessage *)newMessage error:(NSError **) error
{
	[self introduce];

	// If needed, error gets its value set in authenticateWithError:, so we don't need to set it again in here
	if (![self authenticateWithError:error]) {
		return NO;
	}

	// If needed, error gets its value set in sendMessage:error:, so we don't need to set it again in here
	if (![self sendMessage:newMessage error:error]) {
		return NO;
	}

	[self quit];

	return YES;
}

#pragma mark Data Methods

- (void)beginDataSection
{
	[self addToQueue:[NSString stringWithFormat:@"DATA%@", lineEnd]];
}

#pragma mark Socket Delegate Methods

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	[sock readDataWithTimeout:5.00 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([[data subdataWithRange:NSMakeRange([data length] - 2, 2)] isEqualToData:[lineEnd dataUsingEncoding:NSASCIIStringEncoding]]) {
		[self runNextCommand];
	}

	[sock readDataWithTimeout:5.00 tag:0];
}

@end
