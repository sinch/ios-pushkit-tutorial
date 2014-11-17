/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

@class SINLocalNotification;
@protocol SINCall;
@protocol SINCallClientDelegate;

/**
 * SINCallClient provides the entry point to the calling functionality of the Sinch SDK.
 * A SINCallClient can be acquired via SINClient.
 *
 * ### Example
 *
 * 	[sinchClient setSupportCalling:YES];
 * 	[sinchClient start];
 * 	...
 *
 * 	// Place outgoing call.
 * 	id<SINCallClient> callClient = [sinchClient callClient];
 * 	id<SINCall> call = [callClient callUserWithId:@"<REMOTE USERID>"];
 *
 * 	// Set the call delegate that handles all the call state changes
 * 	call.delegate= ... ;
 *
 * 	// ...
 *
 * 	// Hang up the call
 * 	[call hangup];
 *
 */
@protocol SINCallClient <NSObject>

/**
 * The object that acts as the delegate of the call client.
 *
 * The delegate object handles call state change events and must
 * adopt the SINCallClientDelegate protocol.
 *
 * @see SINCallClientDelegate
 */
@property (nonatomic, weak) id<SINCallClientDelegate> delegate;

/**
 * Calls the user with the given id.
 *
 * @param userId The application specific id of the user to call.
 *
 * @exception NSInternalInconsistencyException Throws an exception if attempting
 *                                             to initiate a call before the
 *                                             SINClient is started.
 *                                             @see -[SINClientDelegate clientDidStart:].
 * @return SINCall Outgoing call
 */
- (id<SINCall>)callUserWithId:(NSString *)userId;

/**
* Calls the user with the given id and the given headers.
*
* @param userId The application specific id of the user to call.
*
* @param headers NSString key-value pairs to pass with the call.
*                The total size of header keys + values (when encoded with NSUTF8StringEncoding)
*                must not exceed 1024 bytes.
*
* @exception NSInternalInconsistencyException Throws an exception if attempting
*                                             to initiate a call before the
*                                             SINClient is started.
*                                             @see -[SINClientDelegate clientDidStart:].
*
* @exception NSInvalidArgumentException Throws an exception if headers are not strictly 
*                                       containing only keys and values that are of type NSString.
*
* @return SINCall Outgoing call
*/
- (id<SINCall>)callUserWithId:(NSString *)userId headers:(NSDictionary *)headers;

/**
 * Calls a phone number and terminate the call to the PSTN-network (Publicly Switched
 * Telephone Network).
 *
 * @param phoneNumber The phone number to call.
 *                    The phone number should be given according to E.164 number formatting
 *                    (http://en.wikipedia.org/wiki/E.164) and should be prefixed with a '+'.
 *                    E.g. to call the US phone number 415 555 0101, it should be specified as
 *                    "+14155550101", where the '+' is the required prefix and the US country
 *                    code '1' added before the local subscriber number.
 *
 * @exception NSInternalInconsistencyException Throws an exception if attempting
 *                                             to initiate a call before the
 *                                             SINClient is started.
 *                                             @see -[SINClientDelegate clientDidStart:].
 * @return SINCall Outgoing call
 */
- (id<SINCall>)callPhoneNumber:(NSString *)phoneNumber;

/**
* Calls a phone number and terminate the call to the PSTN-network (Publicly Switched
* Telephone Network).
*
* @param phoneNumber The phone number to call.
*                    The phone number should be given according to E.164 number formatting
*                    (http://en.wikipedia.org/wiki/E.164) and should be prefixed with a '+'.
*                    E.g. to call the US phone number 415 555 0101, it should be specified as
*                    "+14155550101", where the '+' is the required prefix and the US country
*                    code '1' added before the local subscriber number.
*
* @param headers NSString key-value pairs to pass with the call.
*                The total size of header keys + values (when encoded with NSUTF8StringEncoding)
*                must not exceed 1024 bytes.
*
* @exception NSInternalInconsistencyException Throws an exception if attempting
*                                             to initiate a call before the
*                                             SINClient is started.
*                                             @see -[SINClientDelegate clientDidStart:].
*
* @exception NSInvalidArgumentException Throws an exception if headers are not strictly
*                                       containing only keys and values that are of type NSString.
*
* @return SINCall Outgoing call
*/
- (id<SINCall>)callPhoneNumber:(NSString *)phoneNumber headers:(NSDictionary *)headers;

@end

@protocol SINCallClientDelegate <NSObject>

@optional

/**
 * Tells the delegate that an incoming call has been received.
 *
 * To receive further events related to this call, a SINCallDelegate
 * should be assigned to the call.
 *
 * The call has entered the `SINCallStateInitiating` state.
 *
 * @param client The client informing the delegate that an incoming call
 *               was received. The delegate of the incoming call object
 *               should be set by the implementation of this method.
 *
 * @param call The incoming call.
 *
 * @see SINCallClient, SINCall, SINCallDelegate
 */
- (void)client:(id<SINCallClient>)client didReceiveIncomingCall:(id<SINCall>)call;

/**
 * Method for providing presentation related data for a local notification used
 * to notify the application user of an incoming call.
 *
 * The return value will be used by SINCallClient to schedule a
 * 'Local Push Notification', i.e. a UILocalNotification.
 * That UILocalNotification, when triggered and taken action upon by the user,
 * is supposed to be used in conjunction with
 * -[SINClient relayLocalNotification:].
 *
 * This method is declared as optional, but it is still required to implement
 * if support for using an active connection in background is enabled, see
 * -[SINClient setSupportActiveConnectionInBackground:].
 *
 * Hanging up an incoming call while being in the background is a valid operation.
 * This can be useful to dismiss an incoming call while the user is busy, e.g.
 * in a regular phone call. This will effectively prevent the SDK from invoking
 * the -[SINCallClientDelegate client:didReceiveIncomingCall:] method when the app returns to
 * foreground.
 * Invoking -[SINCall answer] is pended until the app returns to the foreground.
 *
 * @param client The client requesting a local notification
 *
 * @param call A SINCall object representing the incoming call.
 *
 * @return SINLocalNotification The delegate is responsible for composing a
 *                              SINLocalNotification which can be used to
 *                              present an incoming call.
 *
 * @see SINLocalNotification
 * @see SINCallClient
 * @see SINCall
 */
- (SINLocalNotification *)client:(id<SINCallClient>)client localNotificationForIncomingCall:(id<SINCall>)call;

@end
