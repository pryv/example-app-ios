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

class HKEvent {
    private let type: HKObjectType!
    private let unit: HKUnit?
    private let updateFrequency: HKUpdateFrequency!
    
    public init(type: HKObjectType?, unit: HKUnit?, updateFrequency: HKUpdateFrequency?) {
        self.type = type
        self.unit = unit
        self.updateFrequency = updateFrequency
    }
    
    public func eventStreamId() -> String {
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
    
    public func eventType() -> String {
        if let _ = type as? HKCharacteristicType {
            return "note/txt"
        }
        
        if let quantityType = type as? HKQuantityType {
            switch quantityType.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") {
            case "StepCount":
                return "count/steps"
            case "PushCount", "SwimmingStrokeCount", "FlightsClimbed", " NikeFuel", "InhalerUsage", "NumberOfTimesFallen", "UvExposure":
                return "count/generic"
            case "BasalEnergyBurned", "ActiveEnergyBurned", "DietaryEnergyConsumed":
                return "energy/cal"
            case "DistanceWalkingRunning", "DistanceCycling", "DistanceWheelchair", "DistanceSwimming", "DistanceDownhillSnowSports":
                return "length/m"
            case "AppleExerciseTime", "AppleStandTime":
                return "time/min"
            case "Height", "WaistCircumference":
                return "length/cm"
            case "BodyMass", "LeanBodyMass":
                return "mass/kg"
            case "BodyMassIndex":
                return "pressure/kg-m2"
            case "BodyFatPercentage", "OxygenSaturation", "BloodAlcoholContent", "PeripheralPerfusionIndex":
                return "ratio/percent"
            case "BasalBodyTemperature", "BodyTemperature":
                return "temperature/c"
            case "EnvironmentalAudioExposure", "HeadphoneAudioExposure":
                return "pressure/pa"
            case "HeartRate", "RestingHeartRate", "WalkingHeartRateAverage":
                return "rate"
            case "HeartRateVariabilitySDNN":
                return "time/ms"
            case "BloodPressureSystolic":
                return "systolic"
            case "BloodPressureDiastolic":
                return "diastolic"
            case "RespiratoryRate":
                return "frequency/hz"
            case "DietaryFatTotal", "DietaryFatSaturated", "DietaryCholesterol", "DietaryCarbohydrates", "DietarySugar", "DietaryProtein", "DietaryCalcium", "DietaryIron", "DietaryPotassium", "DietaryVitaminA", "DietaryVitaminC", "DietaryVitaminD":
                return "mass/g"
            case "BloodGlucose":
                return "density/mg-dl"
            case "ElectrodermalActivity":
                return "electrical-conductivity/s"
            case "ForcedExpiratoryVolume1", "ForcedVitalCapacity":
                return "volume/cm3"
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
    
    public func eventContent(from sample: HKSample? = nil, of store: HKHealthStore? = nil) -> Any? {
        
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
            return quantitySample.quantity.doubleValue(for: unit!) // TODO: set unit from another function
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
    
    public func needsBackgroundDelivery() -> Bool {
        (type as? HKCharacteristicType) != nil
    }
    
    public func event(from sample: HKSample) -> APICall {
        return [
            "method": "events.create",
            "params": [
                "streamId": eventStreamId(),
                "type": eventType(),
                "tags": [String(describing: sample.uuid)],
                "content": eventContent(from: sample)
            ]
        ]
    }
}
