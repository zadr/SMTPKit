//
//  SMTPChecks.m
//  SMTPKit
//
//  Created by Zach Drayer on 11/16/09.
//  Copyright 2009 (Unnamed Company Only Replaced Because The Placeholder Is Ugly). All rights reserved.
//

#import "SMTPChecks.h"
#import <SystemConfiguration/SCNetworkReachability.h>

#import <netdb.h>
#import <netinet/in.h>

@implementation SMTPChecks

// Regex for the predicate taken from Ben McRedmond's DHValidation, found at http://github.com/benofsky/DHValidation
+ (BOOL) validEmail:(NSString *)email
{
	static NSPredicate *emailPredicate = nil;

	if (!emailPredicate)
		emailPredicate = [NSPredicate predicateWithFormat:@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"];

	return [emailPredicate evaluateWithObject:email];
}

+ (BOOL) canReachHost:(NSString *)host port:(NSInteger) port
{
	SCNetworkReachabilityRef hostRef = CFMakeCollectable(SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [host cStringUsingEncoding:NSUTF8StringEncoding]));
	SCNetworkReachabilityFlags reachabilityFlags = 0;

	SCNetworkReachabilityGetFlags(hostRef, &reachabilityFlags);

	if (reachabilityFlags != kSCNetworkFlagsReachable)
		return NO;

	in_addr_t currentIP = 0;

	if (!gethostbyaddr((const void *)&currentIP, sizeof(currentIP), AF_INET))
		return NO;

	int aSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (aSocket == -1)
		return NO;

	struct sockaddr_in socketIn;
	socketIn.sin_port = port;
	socketIn.sin_addr.s_addr = currentIP;
	socketIn.sin_family = AF_INET;

	if (bind(aSocket, (struct sockaddr *)&socketIn, sizeof(struct sockaddr_in))) {
	   close(aSocket);
	   return NO;
	}

	close(aSocket);
	return YES;
}
@end
