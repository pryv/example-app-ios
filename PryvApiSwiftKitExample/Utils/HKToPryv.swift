//
//  HKBridge.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 03.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit
import PryvApiSwiftKit

public typealias PryvSample = [String: Any?]

/// Bridge between the date received from HealthKit and the creation of events in Pryv
public class HKDataStructure {
    public let type: HKObjectType
    public var unit: HKUnit?
    public let frequency: HKUpdateFrequency?
    
    // MARK: - public library
    
    /// Create a bridge from the data in HealthKit
    /// - Parameters:
    ///   - type: the type of object received from HK
    ///   - updateFrequency
    /// # Note
    ///     `updateFrequency` is mandatory for every dynamic data HK stream
    public init(type: HKObjectType, frequency: HKUpdateFrequency? = nil) {
        self.type = type
        self.frequency = frequency
    }
    
    /// Return whether background delivery is needed, i.e. if data is dynamic or static
    /// If the data is static, one needs to submit the data to Pryv only if a change happened.
    /// - Returns: true if dynamic, false if static
    public func needsBackgroundDelivery() -> Bool {
        (type as? HKCharacteristicType) == nil
    }
    
    /// Create an API call from the given HealthKit sample or store
    /// - Parameters:
    ///   - sample: the HK sample
    ///   - store: the HK store
    /// - Returns: the API call to create an event with the data from HealthKit
    /// # Note
    ///     At least one of the two attributes needs to be not `nil` 
    public func (from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> PryvSample {
        var params = ["streamId": eventStreamId(), "type": eventType(), "content": eventContent(from: sample, of: store)]
        if let _ = sample { params["tags"] = [String(describing: sample!.uuid)] }
        
        return params
    }
    
    // MARK: - private helpers functions for the library
    
    /// Construct the Pryv event `streamId`
    /// - Returns: the `streamId`
    private func eventStreamId() -> String {
        if let _ = type as? HKCharacteristicType {
            return "characteristic"
        }
        if let quantityType = type as? HKQuantityType {
            switch quantityType.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") {
            case "StepCount", "DistanceWalkingRunning", "DistanceCycling", "PushCount", "DistanceWheelchair", "SwimmingStrokeCount", "DistanceSwimming", "DistanceDownhillSnowSports", "BasalEnergyBurned", "ActiveEnergyBurned", "FlightsClimbed", "NikeFuel", "AppleExerciseTime", "AppleStandTime":
                return "activity"
            case "Height", "BodyMass", "BodyMassIndex", "LeanBodyMass", "BodyFatPercentage", "WaistCircumference":
                return "measurements"
            case "BasalBodyTemperature":
                return "reproductive-health"
            case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                return "hearing"
            case "HeartRate", "RestingHeartRate", "HeartRateVariabilitySDNN", "WalkingHeartRateAverage", "OxygenSaturation", "BodyTemperature", "BloodPressireSystolic", "BloodPressureDiastolic", "RespiratoryRate":
                return "vital"
            case "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                return "nutrition"
            case "BloodAlcoholContent", "BloodGlucose", "ElectrodermalActivity", "ForcedExpiratoryVolume1", "ForcedVitalCapacity", "InhalerUsage", "NumberOfTimesFallen", "PeakExpiratoryFlowRate", "Peripheral£PerfusionIndex":
                return "lab-results"
            case "UvExposure":
                return "UV-exposure"
            default:
                return "diary"
            }
        }
        
        if let correlationType = type as? HKCorrelationType {
            switch correlationType.identifier.replacingOccurrences(of: "HKCorrelationTypeIdentifier", with: "") {
            case "BloodPressure":
                return "vital"
            default:
                return "diary"
            }
        }
        
        return "diary"
    }
    
    /// Translate HK data type to Pryv data type
    /// - Returns: the String corresponding to the Pryv data type of the event
    private func eventType() -> String {
        if let _ = type as? HKCharacteristicType {
            if type.identifier == "HKCharacteristicTypeIdentifierDateOfBirth" {
                return "date/iso-8601"
            }
            return "note/txt"
        }
        
        if let quantityType = type as? HKQuantityType {
            switch quantityType.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") {
            case "StepCount":
                unit = HKUnit.count()
                return "count/steps"
            case "PushCount", "SwimmingStrokeCount", "FlightsClimbed", " NikeFuel", "InhalerUsage", "NumberOfTimesFallen", "UvExposure":
                unit = HKUnit.count()
                return "count/generic"
            case "BasalEnergyBurned", "ActiveEnergyBurned", "DietaryEnergyConsumed":
                unit = HKUnit.kilocalorie()
                return "energy/kcal"
            case "DistanceWalkingRunning", "DistanceCycling", "DistanceWheelchair", "DistanceSwimming", "DistanceDownhillSnowSports":
                unit = HKUnit.meter()
                return "length/m"
            case "AppleExerciseTime", "AppleStandTime":
                unit = HKUnit.minute()
                return "time/min"
            case "Height", "WaistCircumference":
                unit = HKUnit.meterUnit(with: .centi)
                return "length/cm"
            case "BodyMass", "LeanBodyMass":
                unit = HKUnit.gramUnit(with: .kilo)
                return "mass/kg"
            case "BodyMassIndex":
                unit = HKUnit.count()
                return "pressure/kg-m2"
            case "BodyFatPercentage", "OxygenSaturation", "BloodAlcoholContent", "PeripheralPerfusionIndex":
                unit = HKUnit.percent()
                return "ratio/percent"
            case "BasalBodyTemperature", "BodyTemperature":
                unit = HKUnit.degreeCelsius()
                return "temperature/c"
            case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                unit = HKUnit.pascal()
                return "pressure/pa"
            case "HeartRate", "RestingHeartRate", "WalkingHeartRateAverage":
                unit = HKUnit.count()
                return "frequency/bpm"
            case "HeartRateVariabilitySDNN":
                unit = HKUnit.secondUnit(with: .milli)
                return "time/ms"
            case "BloodPressureSystolic", "BloodPressureDiastolic":
                unit = HKUnit.millimeterOfMercury()
                return "pressure/mmhg"
            case "RespiratoryRate":
                unit = HKUnit.count()
                return "frequency/bpm"
            case "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                unit = HKUnit.gram()
                return "mass/g"
            case "BloodGlucose":
                unit = HKUnit.gramUnit(with: .milli)
                return "mass/mg"
            case "ElectrodermalActivity":
                unit = HKUnit.siemen()
                return "electrical-conductivity/s"
            case "ForcedExpiratoryVolume1", "ForcedVitalCapacity":
                unit = HKUnit.liter()
                return "volume/l"
            default:
                return "note/txt"
            }
        }
        
        if let correlationType = type as? HKCorrelationType {
            switch correlationType.identifier.replacingOccurrences(of: "HKCorrelationTypeIdentifier", with: "") {
            case "BloodPressure":
                return "blood-pressure/mmhg-bpm"
            default:
                return "note/txt"
            }
        }
        
        return "note/txt"
    }
    
    /// Translate the content of a HK sample or store to a Pryv event content
    /// - Parameters:
    ///   - sample: the HK sample
    ///   - store: the HK store
    /// - Returns: the Pryv event content corresponding to the content of the sample or store
    /// # Note
    ///     At least one of the two attributes needs to be not `nil`
    private func eventContent(from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> Any? {
        
        if let characteristicType = type as? HKCharacteristicType, let healthStore = store {
            switch characteristicType.identifier.replacingOccurrences(of: "HKCharacteristicTypeIdentifier", with: "") {
            case "BiologicalSex":
                guard let biologicalSex = try? healthStore.biologicalSex().biologicalSex else { return nil }
                switch biologicalSex {
                case .female: return "female"
                case .male: return "male"
                case .notSet: return nil
                case .other: return "other"
                @unknown default: fatalError()
                }
            case "BloodType":
                guard let bloodType = try? healthStore.bloodType().bloodType else { return nil }
                switch bloodType {
                case .notSet: return nil
                case .abNegative: return "AB-"
                case .abPositive: return "AB+"
                case .aNegative: return "A-"
                case .aPositive: return "A+"
                case .bNegative: return "B-"
                case .bPositive: return "B+"
                case .oNegative: return "O-"
                case .oPositive: return "O+"
                @unknown default:
                    fatalError()
                }
            case "DateOfBirth":
                guard let birthdayComponents = try? healthStore.dateOfBirthComponents() else { return nil }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                return formatter.string(from: birthdayComponents.date!)
            case "FitzpatrickSkinType":
                guard let skinType = try? healthStore.fitzpatrickSkinType().skinType else { return nil }
                switch skinType {
                case .notSet: return nil
                case .I: return "Pale white skin"
                case .II: return "White skin"
                case .III: return "White to light brown skin"
                case .IV: return "Beige-olive skin"
                case .V: return "Brown skin"
                case .VI: return "Dark brown to black skin"
                @unknown default:
                    fatalError()
                }
            case "WheelchairUse":
                guard let wheelchairUse = try? healthStore.wheelchairUse().wheelchairUse else { return nil }
                switch wheelchairUse {
                case .no: return "no wheelchair"
                case .yes: return "wheelchair"
                case .notSet: return nil
                @unknown default:
                    fatalError()
                }
            default:
                return nil
            }
        }
        
        if let _ = type as? HKQuantityType, let quantitySample = sample as? HKQuantitySample {
            return quantitySample.quantity.doubleValue(for: unit!)
        }
        
        if let _ = type as? HKCorrelationType, let correlationQuery = sample as? HKCorrelation {
            let systolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!
            let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
            
            let systolic = (correlationQuery.objects(for: systolicType).first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            let diastolic = (correlationQuery.objects(for: diastolicType).first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            
            if let _ = systolic, let _ = diastolic {
                let content: Json = [
                    "systolic": systolic!,
                    "diastolic": diastolic!
                ]
                
                return content
            }
            
            return nil
        }
        
        return nil
    }
}
