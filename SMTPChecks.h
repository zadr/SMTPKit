//
//  SMTPChecks.h
//  SMTPKit
//
//  Created by Zach Drayer on 11/16/09.
//  Copyright 2009 (Unnamed Company Only Replaced Because The Placeholder Is Ugly). All rights reserved.
//

@interface SMTPChecks : NSObject
+ (BOOL) validEmail:(NSString *)email;
+ (BOOL) canReachHost:(NSString *)host port:(NSInteger) port;
@end
