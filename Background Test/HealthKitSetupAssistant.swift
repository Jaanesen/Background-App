//
//  AuthorizeHealthKit.swift
//  Heart Rate WatchKit Extension
//
//  Created by Jonathan Aanesen on 23/09/2020.
//

import HealthKit

class HealthKitSetupAssistant {
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }

    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        // 1. Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }

        // 2. Prepare the data types that will interact with HealthKit
        guard let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(false, HealthkitSetupError.dataTypeNotAvailable)
            return
        }

        // 3. Prepare a list of types you want HealthKit to read and write
        let types: Set<HKSampleType> = [restingHeartRate]
        // 4. Request Authorization
        HKHealthStore().requestAuthorization(toShare: nil,
                                             read: types) { success, error in
            completion(success, error)
        }
    }
}
