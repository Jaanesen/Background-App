//
//  ContentView.swift
//  Background Test
//
//  Created by Jonathan Aanesen on 02/11/2020.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    private var healthStore = HKHealthStore()
    private var notificationHandler = NotificationHandler()
    let heartRateQuantity = HKUnit(from: "count/min")

    @State private var restingHeartRates: Array<Double> = []
    @State private var lastRestingHeartRate: Double = 0.0

    var body: some View {
        NavigationView {
            VStack {
                Text("AVG. RESTING BPM")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
                HStack {
                    Text(restingHeartRates != [] && restingHeartRates.count >= 1 ? "\(Int(restingHeartRates.average))" : "--")
                        .font(.system(size: 90.0))
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(Color.red)
                }

                Text("Last 7 days:")
                    .font(.body)

                HStack(spacing: 3) {
                    ForEach(restingHeartRates, id: \.self) { num in
                        Text("\(Int(num))")
                            .fontWeight(.regular)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 3)
                .frame(height: 30, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 0.3)
                )
            }.navigationBarTitle(Text("Background App"))
        }
        .onAppear(perform: start)
    }

    // MARK: - Start

    private func start() {
        notificationHandler.NotificationAuthorizationHandler()

        HealthKitSetupAssistant.authorizeHealthKit { authorized, error in
            guard authorized else {
                let baseMessage = "HealthKit Authorization Failed"

                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                    print(baseMessage)
                }
                return
            }
            print("HealthKit Successfully Authorized.")
            startObserver()
        }
    }

    // MARK: - Observer Query

    private func startObserver() {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate) else {
            fatalError("*** Unable to create a resting heart rate type ***")
        }
        let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { _, completionHandler, errorOrNil in
            if errorOrNil != nil {
                fatalError("*** Unable to create query:  \(errorOrNil?.localizedDescription ?? "") ***")
            }
            print("Observer triggered")

            runHeartRateQuery()

            completionHandler()
        }
        healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate) {
            _, error in

            if error != nil {
                fatalError("*** Background Delivery error ***")
            }

            print("Enabled background delivery for resting heart rate")
        }
        healthStore.execute(query)
    }

    // MARK: - Heart Rate query

    private func runHeartRateQuery() {
        let calendar = NSCalendar.current

        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: NSDate() as Date)

        anchorComponents.day! -= 6
        anchorComponents.hour = 3

        guard let anchorDate = Calendar.current.date(from: anchorComponents) else {
            fatalError("*** unable to create a valid date from the given components ***")
        }

        let interval = NSDateComponents()
        interval.day = 1

        let endDate = Date()

        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else {
            fatalError("*** Unable to calculate the start date ***")
        }

        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate) else {
            fatalError("*** Unable to create a step count type ***")
        }

        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: nil,
                                                options: .discreteAverage,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval as DateComponents)

        // Set the results handlers
        query.initialResultsHandler = {
            _, results, error in
            guard let statsCollection = results else {
                fatalError("*** An error occurred while calculating the statistics: \(error?.localizedDescription ?? "") ***")
            }
            print("Fetching heart rates")
            var values: Array<Double> = []
            // Add the average resting heart rate to array
            statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in

                if let quantity = statistics.averageQuantity() {
                    let value = quantity.doubleValue(for: HKUnit(from: "count/min"))
                    values.append(Double(String(format: "%.1f", value))!)
                }
            }
            restingHeartRates = values
            print("Heart rates: \(values)")
            
            if lastRestingHeartRate == 0.0 && restingHeartRates.count > 0 {
                lastRestingHeartRate = restingHeartRates[restingHeartRates.count - 1]
                print("Initial resting heart rate: \(lastRestingHeartRate)")
            }
            if restingHeartRates.count > 0 && lastRestingHeartRate != restingHeartRates[restingHeartRates.count - 1] {
                lastRestingHeartRate = restingHeartRates[restingHeartRates.count - 1]
                print("New resting heart rate: \(lastRestingHeartRate)")
                notificationHandler.SendNormalNotification(title: "Resting heart rate changed!", body: "Your resting heart rate has changed! Your new resting value is: \(lastRestingHeartRate)", timeInterval: 1)
            }
        }

        healthStore.execute(query)
    }

    
}

// MARK: - Extensions

extension Array where Element: BinaryFloatingPoint {
    /// The average value of all the items in the array
    var average: Double {
        if isEmpty {
            return 0.0
        } else {
            let sum = reduce(0, +)
            return Double(sum) / Double(count)
        }
    }
}
