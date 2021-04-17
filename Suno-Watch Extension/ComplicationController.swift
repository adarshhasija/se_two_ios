//
//  ComplicationController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 08/04/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import ClockKit
import WatchKit

class ComplicationController : NSObject {
    
}

extension ComplicationController : CLKComplicationDataSource {
    

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        var entry : CLKComplicationTimelineEntry? = nil
        let date = Date()
        if #available(watchOSApplicationExtension 7.0, *) {
            let thumbnailImage = getComplicationImage(complication: complication)
            let text = getComplicationText(complication: complication)
                    
            switch complication.family {
                    case .modularSmall:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateModularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .modularLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            let template = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), body1TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .utilitarianSmall:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: CLKImageProvider(onePieceImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .utilitarianSmallFlat:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), imageProvider: CLKImageProvider(onePieceImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .utilitarianLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            let template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .circularSmall:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .extraLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            let template = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), line2TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .graphicCorner:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .graphicBezel:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image)), textProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .graphicCircular:
                        if let image = thumbnailImage {
                            let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .graphicRectangular:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            let template = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), body1TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }
                    case .graphicExtraLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            let template = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), line2TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                        }

                    default:
                        preconditionFailure("Complication family not supported")
                    }
                    handler(entry)

        } else {
            // Fallback on earlier versions
        }
        
    }
    
    @available(watchOSApplicationExtension 7.0, *)
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        
        //Using this only for battery as we need the extra space for text explanation. Image is not enough
        let supportedFamiliesLarge : [CLKComplicationFamily] =
        [
            //.utilitarianLarge, //Text is too long
            .modularLarge,
            .extraLarge,
            .graphicRectangular,
            .graphicExtraLarge
        ]
        
        var descriptors : [CLKComplicationDescriptor] = []
        let eligibleActions =
        [
            Action.TIME,
            Action.DATE,
            //Action.CAMERA_OCR, //Not including this as it is dependent on iPhone
            Action.BATTERY_LEVEL
        ]
        for action in eligibleActions {
            let siriShortcut = SiriShortcut.shortcutsDictionary[action]!
            let userActivity = SiriShortcut.createUserActivityFromSiriShortcut(siriShortcut: siriShortcut)
            let descriptorTime = CLKComplicationDescriptor(identifier: siriShortcut.activityType, displayName: siriShortcut.title, supportedFamilies: supportedFamiliesLarge, userActivity: userActivity)
            descriptors.append(descriptorTime)
        }
        handler(descriptors)
                            
        //Uncommment this to invalidate the list
        //CLKComplicationServer.sharedInstance().reloadComplicationDescriptors()
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        if #available(watchOSApplicationExtension 7.0, *) {
            let thumbnailImage = getComplicationImage(complication: complication)
            let text = getComplicationText(complication: complication)
                    
                    var template : CLKComplicationTemplate? = nil
                    switch complication.family {
                    case .modularSmall:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateModularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: image))
                        }
                    case .modularLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            template = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), body1TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                        }
                    case .utilitarianSmall:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: CLKImageProvider(onePieceImage: image))
                        }
                    case .utilitarianSmallFlat:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), imageProvider: CLKImageProvider(onePieceImage: image))
                        }
                    case .utilitarianLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title  {
                            template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                        }
                    case .circularSmall:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: image))
                        }
                    case .extraLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            template = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), line2TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                        }
                    case .graphicCorner:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image))
                        }
                    case .graphicBezel:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image)), textProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text))
                        }
                    case .graphicCircular:
                        if let image = thumbnailImage {
                            template = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: image))
                        }
                    case .graphicRectangular:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            template = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), body1TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                        }
                    case .graphicExtraLarge:
                        if let image = thumbnailImage,
                           let userActivityTitle = complication.userActivity?.title {
                            template = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: text, shortText: text, accessibilityLabel: text), line2TextProvider: CLKSimpleTextProvider(text: userActivityTitle, shortText: userActivityTitle, accessibilityLabel: userActivityTitle))
                        }

                    default:
                        preconditionFailure("Complication family not supported")
                    }
                    handler(template)
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    @available(watchOSApplicationExtension 7.0, *)
    func getComplicationImage(complication: CLKComplication) -> UIImage? {
        var image =
            complication.identifier == "com.starsearth.three.getTimeIntent" ? UIImage(systemName: "clock")
            : complication.identifier == "com.starsearth.three.getDateDayOfWeekIntent" ? UIImage(systemName: "calendar")
            : complication.identifier == "com.starsearth.three.getCameraIntent" ? UIImage(systemName: "camera")
            : complication.identifier == "com.starsearth.three.getBatteryLevelIntent" ? UIImage(systemName: "battery.25")
            : UIImage(systemName: "iphone")
        image = image?.withTintColor(UIColor.white)
        return image
    }
    
    @available(watchOSApplicationExtension 7.0, *)
    func getComplicationText(complication: CLKComplication) -> String {
        return
            complication.identifier == "com.starsearth.three.getTimeIntent" ? "TIME"
                : complication.identifier == "com.starsearth.three.getDateDayOfWeekIntent" ? "DATE"
                : complication.identifier == "com.starsearth.three.getCameraIntent" ? "CAMERA"
                : complication.identifier == "com.starsearth.three.getBatteryLevelIntent" ? "BATTERY"
                : "Open App"
    }
    
    func getCurrentBatteryImage() -> UIImage? {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        let level = Int(WKInterfaceDevice.current().batteryLevel * 100)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
        return level > 80 ? UIImage(systemName: "battery.100")
                : (level >= 0 && level < 10) ? UIImage(systemName: "battery.0")
                : UIImage(systemName: "battery.25")
    }
}
