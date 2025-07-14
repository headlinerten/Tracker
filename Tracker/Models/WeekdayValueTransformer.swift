import Foundation

@objc
final class WeekdayValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let days = value as? Set<DayOfWeek> else { return nil }
        let dayRawValues = days.map { $0.rawValue }
        return try? JSONEncoder().encode(dayRawValues)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let rawValues = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        
        let days = rawValues.compactMap { DayOfWeek(rawValue: $0) }
        return Set(days)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            WeekdayValueTransformer(),
            forName: NSValueTransformerName(rawValue: String(describing: WeekdayValueTransformer.self))
        )
    }
}
