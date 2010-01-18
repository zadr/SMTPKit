//
//  SMTPMessage.m
//  SMTPKit
//
//  Created by Geoff Pado on 10/23/09.
//  Copyright 2009 Cocoatype, LLC. All rights reserved.
//
//  Modified by Zach Drayer on 11/16/09.
//

#import "SMTPMessage.h"
#import "SMTPChecks.h"

@interface SMTPMessage (Private)
@property (nonatomic, retain, readwrite) NSMutableArray *recipients;
@end

@implementation SMTPMessage

@synthesize fromAddress = _fromAddress, recipients = _recipients, subject = _subject, body = _body;

- (id)init
{
	if ((self = [super init])) {
		_recipients = [[NSMutableArray alloc] init];
	}

	return self;
}

- (id)initWithRecipients:(NSMutableArray *)recipients
{
	if ((self = [self init])) {
		for (NSString *recipient in recipients) {
			if ([SMTPChecks validEmail:recipient]) {
				[_recipients addObject:recipient];
			}
		}
	}

	return self;
}

+ (SMTPMessage *)messageFromAddress:(NSString *)fromAddress recipients:(NSMutableArray *)recipients subject:(NSString *)subject body:(NSString *)body
{
	SMTPMessage *message = recipients.count ? [[self alloc] initWithRecipients:recipients] : [[self alloc] init];

	if (message) {
		message.fromAddress = fromAddress;
		message.subject = subject;
		message.body = body;

		self = message;
	}

	return [self autorelease];
}

#pragma mark -

- (void)addRecipient:(NSString *)recipient
{
	if ([SMTPChecks validEmail:recipient])
		[_recipients addObject:recipient];
}

- (void)removeRecipient:(NSString *)recipient
{
	[_recipients removeObject:recipient];
}

- (void)clearRecipients
{
	[_recipients removeAllObjects];
}

#pragma mark -

- (void)setFromAddress:(NSString *)fromAddress
{
	if ([SMTPChecks validEmail:_fromAddress])
		_fromAddress = fromAddress;
}

@end
