//
//  NotificationHandler.swift
//  Background Test
//
//  Created by Jonathan Aanesen on 21/04/2021.
//

import UserNotifications


class NotificationHandler {
    
    func NotificationAuthorizationHandler() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            
            if error != nil {
                print("*** Notification authorization failed ***")
            }
        }
        center.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                    (settings.authorizationStatus == .provisional) else { return }
        }
    }

    func SendNormalNotification(title: String, body: String, timeInterval: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // Create the trigger as a repeating event.
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval, repeats: false)
        
        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { error in
            if error != nil {
                // Handle any errors.
                print("Error occured while delivering notifications to center")
            } else {
                print("Successfully delivered notifications to center")
            }
        }
        
        return
    }

}
