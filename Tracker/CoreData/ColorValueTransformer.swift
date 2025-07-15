import UIKit

@objc
final class ColorValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        do {
            // Используем безопасный архиватор
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            print("Ошибка архивации цвета: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            // Используем безопасный деархиватор
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            return color
        } catch {
            print("Ошибка деархивации цвета: \(error)")
            return nil
        }
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            ColorValueTransformer(),
            forName: NSValueTransformerName(rawValue: String(describing: ColorValueTransformer.self))
        )
    }
}
