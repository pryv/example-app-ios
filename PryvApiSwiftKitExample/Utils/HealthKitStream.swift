//
//  HKBridge.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 03.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit
import PryvSwiftKit

public typealias PryvSample = [String: Any?]

/// Bridge between the date received from HealthKit and the creation of events in Pryv
public class HealthKitStream {
    public let type: HKObjectType
    public var unit: HKUnit?
    public let frequency: HKUpdateFrequency?
    
    // MARK: - public library
    
    /// Create a bridge from the data in HealthKit to Pryv's events
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
    
    /// Create Pryv event's parameters from the given HealthKit sample or store
    /// - Parameters:
    ///   - sample: the HK sample
    ///   - store: the HK store
    /// - Returns: the json formatted event's parameters
    /// # Note
    ///     At least one of the two attributes needs to be not `nil` 
    public func pryvEvent(from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> PryvSample {
        var params = ["streamId": pryvStreamId().streamId, "type": eventType(), "content": pryvContent(from: sample, of: store)]
        if let _ = sample { params["tags"] = [String(describing: sample!.uuid)] }
        
        return params
    }
    
    /// Construct the Pryv event `streamId` and `parentId`, if needed
    /// - Returns: a tuple containing the `parentId` (optional) and the `streamId`
    public func pryvStreamId() -> (parentId: String?, streamId: String) {
        var parentId: String? = nil
        
        switch type {
        case is HKCharacteristicType:
            return (parentId: "characteristic", streamId: type.identifier.replacingOccurrences(of: "HKCharacteristicTypeIdentifier", with: "").lowercased())
        case is HKQuantityType:
            let streamId = type.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
            switch streamId {
                case "StepCount", "DistanceWalkingRunning", "DistanceCycling", "PushCount", "DistanceWheelchair", "SwimmingStrokeCount", "DistanceSwimming", "DistanceDownhillSnowSports", "BasalEnergyBurned", "ActiveEnergyBurned", "FlightsClimbed", "NikeFuel", "AppleExerciseTime", "AppleStandTime":
                    parentId = "activity"
                case "Height", "BodyMass", "BodyMassIndex", "LeanBodyMass", "BodyFatPercentage", "WaistCircumference":
                    parentId = "measurements"
                case "BasalBodyTemperature":
                    parentId = "reproductive-health"
                case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                    parentId = "hearing"
                case "HeartRate", "RestingHeartRate", "HeartRateVariabilitySDNN", "WalkingHeartRateAverage", "OxygenSaturation", "BodyTemperature", "BloodPressireSystolic", "BloodPressureDiastolic", "RespiratoryRate", "Vo2Max":
                    parentId = "vital"
                case "DietaryEnergyConsumed", "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietaryFiber", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietarySodium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                    parentId = "nutrition"
                case "BloodAlcoholContent", "BloodGlucose", "ElectrodermalActivity", "ForcedExpiratoryVolume1", "ForcedVitalCapacity", "InhalerUsage", "InsulinDelivery", "NumberOfTimesFallen", "PeakExpiratoryFlowRate", "Peripheral£PerfusionIndex":
                    parentId = "lab-results"
                default: break
            }
            return (parentId: parentId, streamId: streamId.lowercased())
        case is HKCorrelationType:
            let streamId = type.identifier.replacingOccurrences(of: "HKCorrelationTypeIdentifier", with: "")
            switch streamId {
            case "BloodPressure":
                parentId = "vital"
            default: break
            }
            return (parentId: parentId, streamId: streamId)
        case is HKActivitySummaryType:
            return (parentId: parentId, streamId: "activity")
        case is HKAudiogramSampleType:
            return (parentId: "hearing", streamId: "audiogram")
        case is HKWorkoutType:
            return (parentId: parentId, streamId: "workouts")
        case is HKCategoryType:
            let streamId = type.identifier.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "")
            switch type.identifier.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "") {
            case "AppleStandHour":
                parentId = "activity"
            case "SexualActivity", "IntermenstrualBleeding", "MenstrualFlow", "CervicalMucusQuality", "OvulationTestResult":
                parentId = "reproductive-health"
            case "LowHeartRateEvent", "HighHeartRateEvent", "IrregularHeartRhythmEvent":
                parentId = "vital"
            case "ToothBrushingEvent":
                parentId = "self-care"
            case "AbdominalCramps", "Bloating", "Constipation", "Diarrhea", "Heartburn", "Nausea", "Vomiting", "AppetiteChanges", "Chills", "Dizziness", "Fainting", "Fatigue", "Fever", "GeneralizedBodyAche", "HotFlashes", "ChestTightnessOrPain", "Coughing", "RapidPoundingOrFlutteringHeartBeat", "ShortnessOfBreath", "SkippedHeartbeat", "Wheezing", "LowerBackPain", "Headache", "MoodChanges", "LossOfSmell", "LossOfTaste", "RunnyNose", "SoreThroat", "SinusCongestion", "BreastPain", "PelvicPain", "Acne", "SleepChanges":
                parentId = "symptoms"
            default: break
            }
            return (parentId: parentId, streamId: streamId.lowercased())
        case is HKClinicalType:
            return (parentId: parentId, streamId: "clinical")
        default:
            return (parentId: parentId, streamId: "diary")
        }
    }
    
    /// Translate the content of a HK sample or store to a Pryv event content
    /// - Parameters:
    ///   - sample: the HK sample
    ///   - store: the HK store
    /// - Returns: the Pryv event content corresponding to the content of the sample or store
    /// # Note
    ///     At least one of the two attributes needs to be not `nil`
    public func pryvContent(from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> Any? {
        
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
    
    // MARK: - private helpers functions for the library
    
    /// Translate HK data type to Pryv data type
    /// - Returns: the String corresponding to the Pryv data type of the event
    private func eventType() -> String {
        var result = "note/txt"
        
        switch type {
        case is HKCharacteristicType:
            switch type.identifier.replacingOccurrences(of: "HKCharacteristicTypeIdentifier", with: "") {
            case "BiologicalSex":
                result = "attributes/biologicalSex"
            case "BloodType":
                result = "attributes/bloodType"
            case "DateOfBirth":
                result = "date/iso-8601"
            case "FitzpatrickSkinType":
                result = "attributes/skinType"
            case "WheelchairUse":
                result = "boolean/bool"
            default: break
            }
        case is HKQuantityType:
            switch type.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") {
            case "StepCount":
                unit = HKUnit.count()
                result = "count/steps"
            case "PushCount", "SwimmingStrokeCount", "FlightsClimbed", "NikeFuel", "InhalerUsage", "NumberOfTimesFallen", "UvExposure", "BodyMassIndex":
                unit = HKUnit.count()
                result = "count/generic"
            case "BasalEnergyBurned", "ActiveEnergyBurned", "DietaryEnergyConsumed":
                unit = HKUnit.kilocalorie()
                result = "energy/kcal"
            case "DistanceWalkingRunning", "DistanceCycling", "DistanceWheelchair", "DistanceSwimming", "DistanceDownhillSnowSports":
                unit = HKUnit.meter()
                result = "length/m"
            case "AppleExerciseTime", "AppleStandTime":
                unit = HKUnit.minute()
                result = "time/min"
            case "Height", "WaistCircumference":
                unit = HKUnit.meterUnit(with: .centi)
                result = "length/cm"
            case "BodyMass", "LeanBodyMass":
                unit = HKUnit.gramUnit(with: .kilo)
                result = "mass/kg"
            case "BodyFatPercentage", "OxygenSaturation", "BloodAlcoholContent", "PeripheralPerfusionIndex":
                unit = HKUnit.percent()
                result = "ratio/percent"
            case "BasalBodyTemperature", "BodyTemperature":
                unit = HKUnit.degreeCelsius()
                result = "temperature/c"
            case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                unit = HKUnit.decibelAWeightedSoundPressureLevel()
                result = "pressure/db"
            case "HeartRate", "RestingHeartRate", "WalkingHeartRateAverage":
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                result = "frequency/bpm"
            case "HeartRateVariabilitySDNN":
                unit = HKUnit.secondUnit(with: .milli)
                result = "time/ms"
            case "BloodPressureSystolic", "BloodPressureDiastolic":
                unit = HKUnit.millimeterOfMercury()
                result = "pressure/mmhg"
            case "RespiratoryRate":
                unit = HKUnit.count()
                result = "frequency/brpm"
            case "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietaryFiber", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietarySodium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                result = "mass/g"
            case "BloodGlucose":
                unit = HKUnit.moleUnit(withMolarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
                result = "density/mmol-l"
            case "ElectrodermalActivity":
                unit = HKUnit.siemenUnit(with: .micro)
                result = "electrical-conductivity/us"
            case "ForcedExpiratoryVolume1", "ForcedVitalCapacity":
                unit = HKUnit.liter()
                result = "volume/l"
            case "Vo2Max":
                unit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: HKUnit.minute()))
                result = "gas-consumption/mlpkgmin"
            case "InsulinDelivery":
                unit = HKUnit.internationalUnit()
                result = "volume/iu"
            case "PeakExpiratoryFlowRate":
                unit = HKUnit.liter().unitDivided(by: HKUnit.minute())
                result = "speed/lpm"
            default: break
            }
        case is HKCorrelationType:
            switch type.identifier.replacingOccurrences(of: "HKCorrelationTypeIdentifier", with: "") {
            case "BloodPressure":
                return "blood-pressure/mmhg-bpm"
            default: break
            }
        case is HKActivitySummaryType:
            result = "activity/summary"
        case is HKAudiogramSampleType:
            result = "audiogram/data"
        case is HKWorkoutType:
            return "activity/workout"
        case is HKCategoryType:
            switch type.identifier.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "") {
            case "SexualActivity":
                result = "reproductive-health/sexualActivity"
            case "IntermenstrualBleeding", "LowHeartRateEvent", "HighHeartRateEvent", "IrregularHeartRhythmEvent", "SleepChanges",
                "MoodChanges", "AppleStandHour", "ToothBrushingEvent":
                result = "boolean/bool"
            case "MenstrualFlow":
                result = "reproductive-health/menstrualFlow"
            case "CervicalMucusQuality":
                result = "reproductive-health/mucusQuality"
            case "OvulationTestResult":
                result = "reproductive-health/ovulation"
            case "AbdominalCramps", "Acne", "PelvicPain", "BreastPain", "SinusCongestion", "SoreThroat", "LossOfTaste", "LossOfSmell",
                 "Headache", "LowerBackPain", "Wheezing", "SkippedHeartbeat", "ShortnessOfBreath", "RapidPoundingOrFlutteringHeartbeat",
                 "Coughing", "ChestTightnessOrPain", "HotFlashes", "GeneralizedBodyAche", "Fever", "Fatigue", "Fainting", "Dizziness",
                 "Chills", "Vomiting", "Nausea", "Heartburn", "Diarrhea", "Constipation", "Bloating":
                result = "symptoms/severity"
            case "AppetiteChanges":
                result = "symptoms/appetiteChanges"
            case "MindfulSession":
                result = "time/min"
            case "SleepAnalysis":
                result = "sleep/analysis"
            default: break
            }
        case is HKClinicalType:
            result = "clinical/fhir"
        default: break
        }
        
        return result
    }
    
}
