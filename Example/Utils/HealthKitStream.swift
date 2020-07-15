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
    /// - Returns: the json formatted event's parameters and the data for the corresponding attachment, if needed
    /// # Note
    ///     At least one of the two attributes needs to be not `nil`
    public func pryvEvent(from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> (params: PryvSample?, attachmentData: Data?) {
        let (type, content, attachmentData) = pryvContentAndType(from: sample, of: store)
        if content == nil && attachmentData == nil{
            return (params: nil, attachmentData: nil)
        }
        
        var params = ["streamIds": [pryvStreamId().streamId], "type": type, "content": content]
        if let _ = sample { params["tags"] = [String(describing: sample!.uuid)] }
        
        return (params: params, attachmentData: attachmentData)
    }
    
    /// Construct the Pryv event `streamId` and `parentId`, if needed
    /// - Returns: a tuple containing the `parentId` (optional) and the `streamId`
    public func pryvStreamId() -> (parentId: String?, streamId: String) {
        var parentId: String? = nil
        
        switch type {
        case is HKCharacteristicType:
            return (parentId: "characteristic", streamId: type.identifier.replacingOccurrences(of: "HKCharacteristicTypeIdentifier", with: "").lowercasedFirstLetter())
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
            return (parentId: parentId, streamId: streamId.lowercasedFirstLetter())
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
            return (parentId: parentId, streamId: streamId.lowercasedFirstLetter())
        case is HKClinicalType:
            return (parentId: parentId, streamId: "clinical")
        default:
            return (parentId: parentId, streamId: "diary")
        }
    }
    
    /// Translate the content of a HK sample or store to a Pryv event content with its corresponding type and potential attachment
    /// - Parameters:
    ///   - sample: the HK sample
    ///   - store: the HK store
    ///   - summary: the `HKActivitySummary` in case of an `HKActivitySummaryQuery`
    /// - Returns: a tuple containing the Pryv event content corresponding to the content of the sample or store, its type and potential attachment
    /// # Note
    ///     At least one of the two parameters needs to be not `nil`
    public func pryvContentAndType(from sample: HKSample? = nil, of store: HKHealthStore? = nil, activity summary: HKActivitySummary? = nil) -> (type: String, content: Any?, attachmentData: Data?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        var attachmentData: Data? = nil
        
        switch type {
        case is HKCharacteristicType:
            switch type.identifier.replacingOccurrences(of: "HKCharacteristicTypeIdentifier", with: "") {
            case "BiologicalSex":
                var content: Any? = nil
                if let biologicalSex = try? store?.biologicalSex().biologicalSex {
                    switch biologicalSex {
                    case .female: content = "female"
                    case .male: content = "male"
                    case .other: content = "other"
                    default: break
                    }
                }
                return (type: "attributes/biologicalSex", content: content, attachmentData: attachmentData)
                
            case "BloodType":
                var content: Any? = nil
                if let bloodType = try? store?.bloodType().bloodType {
                    switch bloodType {
                    case .abNegative: content = "AB-"
                    case .abPositive: content = "AB+"
                    case .aNegative: content = "A-"
                    case .aPositive: content = "A+"
                    case .bNegative: content = "B-"
                    case .bPositive: content = "B+"
                    case .oNegative: content = "O-"
                    case .oPositive: content = "O+"
                    default: break
                    }
                }
                return (type: "attributes/bloodType", content: content, attachmentData: attachmentData)
                    
            case "DateOfBirth":
                var content: Any? = nil
                if let birthdayComponents = try? store?.dateOfBirthComponents() {
                    content = formatter.string(from: birthdayComponents.date!)
                }
                return (type: "date/iso-8601", content: content, attachmentData: attachmentData)
                    
            case "FitzpatrickSkinType":
                var content: Any? = nil
                if let skinType = try? store?.fitzpatrickSkinType().skinType {
                    switch skinType {
                    case .I: content = "Pale white skin"
                    case .II: content = "White skin"
                    case .III: content = "White to light brown skin"
                    case .IV: content = "Beige-olive skin"
                    case .V: content = "Brown skin"
                    case .VI: content = "Dark brown to black skin"
                    default: break
                    }
                }
                return (type: "attributes/skinType", content: content, attachmentData: attachmentData)
            case "WheelchairUse":
                var content: Any? = nil
                if let wheelchairUse = try? store?.wheelchairUse().wheelchairUse {
                    switch wheelchairUse {
                    case .no: content = false
                    case .yes: content = true
                    default: break
                    }
                }
                return (type: "boolean/bool", content: content, attachmentData: attachmentData)
            default: break
            }
        case is HKQuantityType:
            var pryvType = "note/txt"
            var unit: HKUnit? = nil
            switch type.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") {
            case "StepCount":
                unit = HKUnit.count()
                pryvType = "count/steps"
            case "PushCount", "SwimmingStrokeCount", "FlightsClimbed", "NikeFuel", "InhalerUsage", "NumberOfTimesFallen", "UvExposure", "BodyMassIndex":
                unit = HKUnit.count()
                pryvType = "count/generic"
            case "BasalEnergyBurned", "ActiveEnergyBurned", "DietaryEnergyConsumed":
                unit = HKUnit.kilocalorie()
                pryvType = "energy/kcal"
            case "DistanceWalkingRunning", "DistanceCycling", "DistanceWheelchair", "DistanceSwimming", "DistanceDownhillSnowSports":
                unit = HKUnit.meter()
                pryvType = "length/m"
            case "AppleExerciseTime", "AppleStandTime":
                unit = HKUnit.minute()
                pryvType = "time/min"
            case "Height", "WaistCircumference":
                unit = HKUnit.meterUnit(with: .centi)
                pryvType = "length/cm"
            case "BodyMass", "LeanBodyMass":
                unit = HKUnit.gramUnit(with: .kilo)
                pryvType = "mass/kg"
            case "BodyFatPercentage", "OxygenSaturation", "BloodAlcoholContent", "PeripheralPerfusionIndex":
                unit = HKUnit.percent()
                pryvType = "ratio/percent"
            case "BasalBodyTemperature", "BodyTemperature":
                unit = HKUnit.degreeCelsius()
                pryvType = "temperature/c"
            case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                unit = HKUnit.decibelAWeightedSoundPressureLevel()
                pryvType = "pressure/db"
            case "HeartRate", "RestingHeartRate", "WalkingHeartRateAverage":
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                pryvType = "frequency/bpm"
            case "HeartRateVariabilitySDNN":
                unit = HKUnit.secondUnit(with: .milli)
                pryvType = "time/ms"
            case "BloodPressureSystolic", "BloodPressureDiastolic":
                unit = HKUnit.millimeterOfMercury()
                pryvType = "pressure/mmhg"
            case "RespiratoryRate":
                unit = HKUnit.count()
                pryvType = "frequency/brpm"
            case "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietaryFiber", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietarySodium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                pryvType = "mass/g"
            case "BloodGlucose":
                unit = HKUnit.moleUnit(withMolarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
                pryvType = "density/mmol-l"
            case "ElectrodermalActivity":
                unit = HKUnit.siemenUnit(with: .micro)
                pryvType = "electrical-conductivity/us"
            case "ForcedExpiratoryVolume1", "ForcedVitalCapacity":
                unit = HKUnit.liter()
                pryvType = "volume/l"
            case "Vo2Max":
                unit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: HKUnit.minute()))
                pryvType = "gas-consumption/mlpkgmin"
            case "InsulinDelivery":
                unit = HKUnit.internationalUnit()
                pryvType = "volume/iu"
            case "PeakExpiratoryFlowRate":
                unit = HKUnit.liter().unitDivided(by: HKUnit.minute())
                pryvType = "speed/lpm"
            default: break
            }
            return (type: pryvType, content: (sample as! HKQuantitySample).quantity.doubleValue(for: unit!), attachmentData: attachmentData)
        case is HKCorrelationType:
            switch type.identifier.replacingOccurrences(of: "HKCorrelationTypeIdentifier", with: "") {
            case "BloodPressure":
                var content: Any? = nil
                
                let systolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!
                let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
                let correlation = sample as? HKCorrelation
                let systolic = (correlation?.objects(for: systolicType).first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                let diastolic = (correlation?.objects(for: diastolicType).first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                
                if let _ = systolic, let _ = diastolic {
                    content = [
                        "systolic": systolic!,
                        "diastolic": diastolic!
                    ]
                }
                
                return (type: "blood-pressure/mmhg-bpm", content: content, attachmentData: attachmentData)
            default: break
            }
        case is HKActivitySummaryType:
            let content = [
                "activeEnergyBurned": summary?.activeEnergyBurned,
                "activeEnergyBurnedGoal": summary?.activeEnergyBurnedGoal,
                "appleExerciseTime": summary?.appleExerciseTime,
                "appleExerciseTimeGoal": summary?.appleExerciseTimeGoal,
                "appleStandHours": summary?.appleStandHours,
                "appleStandHoursGoal": summary?.appleStandHoursGoal
            ]
            return (type: "activity/summary", content: content, attachmentData: attachmentData)
        case is HKAudiogramSampleType:
            let audiogramSample = sample as! HKAudiogramSample
            
            var sensitivityPoints = [[String: Any?]]()
            for sensitivityPoint in audiogramSample.sensitivityPoints {
                var newPoint = [String: Any?]()
                newPoint["frequency"] = sensitivityPoint.frequency
                newPoint["leftEarSensitivity"] = sensitivityPoint.leftEarSensitivity
                newPoint["rightEarSensitivity"] = sensitivityPoint.rightEarSensitivity
                
                sensitivityPoints.append(newPoint)
            }
            
            let content: [String: Any?] = [
                "sensitivityPoints": sensitivityPoints,
                "start": formatter.string(from: audiogramSample.startDate),
                "end": formatter.string(from: audiogramSample.endDate),
                "metadata": audiogramSample.metadata,
            ]
            return (type: "audiogram/data", content: content, attachmentData: attachmentData)
        case is HKWorkoutType:
            let workoutSample = sample as! HKWorkout
            
            var events = [[String: Any?]]()
            workoutSample.workoutEvents?.forEach { workoutEvent in
                var event = [String: Any?]()
                event["dateInterval"] = [
                    "start": formatter.string(from: workoutEvent.dateInterval.start),
                    "end": formatter.string(from: workoutEvent.dateInterval.end),
                    "duration": workoutEvent.dateInterval.duration
                ]
                event["type"] = workoutEvent.type.name
                
                events.append(event)
            }
            
            let content: [String: Any?] = [
                "duration": workoutSample.duration,
                "totalDistance": workoutSample.totalDistance?.doubleValue(for: HKUnit.meter()),
                "totalEnergyBurned": workoutSample.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()),
                "activityType": workoutSample.workoutActivityType.name,
                "events": events,
                "totalFlightsClimbed": workoutSample.totalFlightsClimbed?.doubleValue(for: HKUnit.count()),
                "totalSwimmingStrokeCount": workoutSample.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count())
            ]
            return (type: "activity/workout", content: content, attachmentData: attachmentData)
        case is HKCategoryType:
            var pryvType = "note/txt"
            let categorySample = sample as! HKCategorySample
            var content: Any? = nil
            switch type.identifier.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "") {
            case "SexualActivity":
                pryvType = "reproductive-health/sexualActivity"
                if let protectionUsed = categorySample.value(forKey: HKMetadataKeySexualActivityProtectionUsed) as? Bool {
                    content = protectionUsed ? "protectionUsed" : "protectionNotUsed"
                } else {
                    content = "notSet"
                }
            case "IntermenstrualBleeding", "LowHeartRateEvent", "HighHeartRateEvent", "IrregularHeartRhythmEvent", "SleepChanges",
                "MoodChanges", "AppleStandHour", "ToothBrushingEvent", "MindfulSession":
                pryvType = "boolean/bool"
                content = true
            case "MenstrualFlow":
                pryvType = "reproductive-health/menstrualFlow"
                switch categorySample.value {
                case HKCategoryValueMenstrualFlow.none.rawValue: content = "none"
                case HKCategoryValueMenstrualFlow.light.rawValue: content = "light"
                case HKCategoryValueMenstrualFlow.medium.rawValue: content = "medium"
                case HKCategoryValueMenstrualFlow.heavy.rawValue: content = "heavy"
                default: content = "unspecified"
                }
            case "CervicalMucusQuality":
                pryvType = "reproductive-health/mucusQuality"
                switch categorySample.value {
                case HKCategoryValueCervicalMucusQuality.dry.rawValue: content = "dry"
                case HKCategoryValueCervicalMucusQuality.sticky.rawValue: content = "sticky"
                case HKCategoryValueCervicalMucusQuality.creamy.rawValue: content = "creamy"
                case HKCategoryValueCervicalMucusQuality.watery.rawValue: content = "watery"
                case HKCategoryValueCervicalMucusQuality.eggWhite.rawValue: content = "eggWhite"
                default: break
                }
            case "OvulationTestResult":
                pryvType = "reproductive-health/ovulation"
                switch categorySample.value {
                case HKCategoryValueOvulationTestResult.negative.rawValue: content = "negative"
                case HKCategoryValueOvulationTestResult.luteinizingHormoneSurge.rawValue: content = "luteinizingHormoneSurge"
                case HKCategoryValueOvulationTestResult.indeterminate.rawValue: content = "indeterminate"
                case HKCategoryValueOvulationTestResult.estrogenSurge.rawValue: content = "estrogenSurge"
                default: break
                }
//            These cases are in Apple Symptom types, which is only available from iOS 13.6+ on.
//            case "AbdominalCramps", "Acne", "PelvicPain", "BreastPain", "SinusCongestion", "SoreThroat", "LossOfTaste", "LossOfSmell",
//                 "Headache", "LowerBackPain", "Wheezing", "SkippedHeartbeat", "ShortnessOfBreath", "RapidPoundingOrFlutteringHeartbeat",
//                 "Coughing", "ChestTightnessOrPain", "HotFlashes", "GeneralizedBodyAche", "Fever", "Fatigue", "Fainting", "Dizziness",
//                 "Chills", "Vomiting", "Nausea", "Heartburn", "Diarrhea", "Constipation", "Bloating":
//                pryvType = "symptoms/severity"
//                switch categorySample.value {
//                case HKCategoryValueSeverityNotPresent: content = "notPresent"
//                case HKCategoryValueSeverity.mild.rawValue: content = "mild"
//                case HKCategoryValueSeverity.moderate.rawValue: content = "moderate"
//                case HKCategoryValueSeverity.severe.rawValue: content = "severe"
//                case HKCategoryValueSeverity.unspecified.rawValue: content = "unspecified"
//                default: break
//                }
//            case "AppetiteChanges":
//                pryvType = "symptoms/appetiteChanges"
//                switch categorySample.value {
//                case HKCategoryValueAppetiteChanges.decreased.rawValue: content = "decreased"
//                case HKCategoryValueAppetiteChanges.increased.rawValue: content = "increased"
//                case HKCategoryValueAppetiteChanges.noChange.rawValue: content = "noChange"
//                case HKCategoryValueAppetiteChanges.unspecified.rawValue: content = "unspecified"
//                default: break
//                }
            case "SleepAnalysis":
                pryvType = "sleep/analysis"
                switch categorySample.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue: content = "inBed"
                case HKCategoryValueSleepAnalysis.asleep.rawValue: content = "asleep"
                case HKCategoryValueSleepAnalysis.awake.rawValue: content = "awake"
                default: break
                }
            default: break
            }
            return (type: pryvType, content: content, attachmentData: attachmentData)
        case is HKClinicalType:
            let clinicalSample = sample as! HKClinicalRecord
            var content: [String: Any?] = [
                "displayName": clinicalSample.displayName,
                "clinicalType": clinicalSample.clinicalType.identifier.replacingOccurrences(of: "HKClinicalTypeIdentifier", with: "").lowercasedFirstLetter()
            ]
            if let fhir = clinicalSample.fhirResource {
                content["fhir"] = [
                    "identifier": fhir.identifier,
                    "resourceType": fhir.resourceType
                ]
                attachmentData = fhir.data
            }
            return (type: "clinical/fhir", content: content, attachmentData: attachmentData)
        default: break
        }
        
        return (type: "note/txt", content: nil, attachmentData: attachmentData)
    }
    
}
