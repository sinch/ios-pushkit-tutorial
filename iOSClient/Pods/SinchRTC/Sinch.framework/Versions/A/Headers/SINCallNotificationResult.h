/*
 * Copyright (c) 2013 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

/**
 * SINCallNotificationResult is used to indicate the result of calling the methods
 * -[SINClient relayLocalNotification:] and
 * -[SINClient relayRemotePushNotificationPayload:]
 * , when the Sinch-specific payload in the notification represents an incoming
 * call.
 *
 * One example of a scenario where SINCallNotificationResult is when a user
 * have been attempted to be reached, but not acted on the notification directly.
 * In that case, the notification result object can indicate that the
 * notification is too old (`isTimedOut`), and also contains the `remoteUserId`
 * which can be used for display purposes.
 **/

@protocol SINCallNotificationResult <NSObject>

/** Indicates whether the notification has timed out or not. */
@property (nonatomic, readonly, assign) BOOL isTimedOut;

/** Identifier of the user from which the call represented by the notification originated. */
@property (nonatomic, readonly, copy) NSString *remoteUserId;

/** A unique identifier pertaining to the call */
@property (nonatomic, readonly, copy) NSString *callId;

@end
