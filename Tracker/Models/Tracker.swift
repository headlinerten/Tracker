import UIKit

enum DayOfWeek: String, CaseIterable {
    case monday = "Понедельник"
    case tuesday = "Вторник"
    case wednesday = "Среда"
    case thursday = "Четверг"
    case friday = "Пятница"
    case saturday = "Суббота"
    case sunday = "Воскресенье"
    
    var shortName: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
}

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: Set<DayOfWeek>
}

extension DayOfWeek {
    var localizedName: String {
        switch self {
        case .monday:
            return NSLocalizedString("schedule.day.monday", comment: "Monday")
        case .tuesday:
            return NSLocalizedString("schedule.day.tuesday", comment: "Tuesday")
        case .wednesday:
            return NSLocalizedString("schedule.day.wednesday", comment: "Wednesday")
        case .thursday:
            return NSLocalizedString("schedule.day.thursday", comment: "Thursday")
        case .friday:
            return NSLocalizedString("schedule.day.friday", comment: "Friday")
        case .saturday:
            return NSLocalizedString("schedule.day.saturday", comment: "Saturday")
        case .sunday:
            return NSLocalizedString("schedule.day.sunday", comment: "Sunday")
        }
    }
}
