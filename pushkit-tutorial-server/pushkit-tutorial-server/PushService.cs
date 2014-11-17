using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Web;
using PushSharp;
using PushSharp.Apple;
using PushSharp.Core;

namespace pushkit_tutorial_server {
    public class PushService {
        private static PushService _context;
        static public PushService Context() {
            if (_context == null) {
                _context = new PushService();
            }
            return _context;
        }

        public PushBroker Broker { get; set; }

        public PushService() {
            Broker = new PushBroker();
            Broker.OnNotificationSent += NotificationSent;
            Broker.OnChannelException += ChannelException;
            Broker.OnServiceException += ServiceException;
            Broker.OnNotificationFailed += NotificationFailed;
            Broker.OnDeviceSubscriptionExpired += DeviceSubscriptionExpired;
            Broker.OnDeviceSubscriptionChanged += DeviceSubscriptionChanged;
            Broker.OnChannelCreated += ChannelCreated;
            Broker.OnChannelDestroyed += ChannelDestroyed;
            var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"yourfile");
            var appleCert = File.ReadAllBytes(path);
            Broker.RegisterAppleService(new ApplePushChannelSettings(false, appleCert, "yourpass", true)); //Extension method
        }
        void DeviceSubscriptionChanged(object sender, string oldSubscriptionId, string newSubscriptionId, INotification notification) {
            //Currently this event will only ever happen for Android GCM
            Debug.WriteLine("Device Registration Changed:  Old-> " + oldSubscriptionId + "  New-> " + newSubscriptionId + " -> " + notification);
        }

        void NotificationSent(object sender, INotification notification) {
            Debug.WriteLine("Sent: " + sender + " -> " + notification);
        }

        void NotificationFailed(object sender, INotification notification, Exception notificationFailureException) {
            Debug.WriteLine("Failure: " + sender + " -> " + notificationFailureException.Message + " -> " + notification);
        }

        void ChannelException(object sender, IPushChannel channel, Exception exception) {
            Debug.WriteLine("Channel Exception: " + sender + " -> " + exception);
        }

        void ServiceException(object sender, Exception exception) {
            Debug.WriteLine("Channel Exception: " + sender + " -> " + exception);
        }

        void DeviceSubscriptionExpired(object sender, string expiredDeviceSubscriptionId, DateTime timestamp, INotification notification) {
            Debug.WriteLine("Device Subscription Expired: " + sender + " -> " + expiredDeviceSubscriptionId);
        }

        void ChannelDestroyed(object sender) {
            Debug.WriteLine("Channel Destroyed for: " + sender);
        }

        void ChannelCreated(object sender, IPushChannel pushChannel) {
            Debug.WriteLine("Channel Created for: " + sender);
        }
    }
}