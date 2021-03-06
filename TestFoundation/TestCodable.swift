// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#else
import SwiftFoundation
import SwiftXCTest
#endif

// MARK: - Helper Functions

private func makePersonNameComponents(namePrefix: String? = nil,
                                      givenName: String? = nil,
                                      middleName: String? = nil,
                                      familyName: String? = nil,
                                      nameSuffix: String? = nil,
                                      nickname: String? = nil) -> PersonNameComponents {
    var result = PersonNameComponents()
    result.namePrefix = namePrefix
    result.givenName = givenName
    result.middleName = middleName
    result.familyName = familyName
    result.nameSuffix = nameSuffix
    result.nickname = nickname
    return result
}

func expectRoundTripEquality<T : Codable>(of value: T, encode: (T) throws -> Data, decode: (Data) throws -> T) where T : Equatable {
    let data: Data
    do {
        data = try encode(value)
    } catch {
        fatalError("Unable to encode \(T.self) <\(value)>: \(error)")
    }

    let decoded: T
    do {
        decoded = try decode(data)
    } catch {
        fatalError("Unable to decode \(T.self) <\(value)>: \(error)")
    }

    XCTAssertEqual(value, decoded, "Decoded \(T.self) <\(decoded)> not equal to original <\(value)>")
}

func expectRoundTripEqualityThroughJSON<T : Codable>(for value: T) where T : Equatable {
    let inf = "INF", negInf = "-INF", nan = "NaN"
    let encode = { (_ value: T) throws -> Data in
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: inf,
                                                                      negativeInfinity: negInf,
                                                                      nan: nan)
        return try encoder.encode(value)
    }

    let decode = { (_ data: Data) throws -> T in
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: inf,
                                                                        negativeInfinity: negInf,
                                                                        nan: nan)
        return try decoder.decode(T.self, from: data)
    }

    expectRoundTripEquality(of: value, encode: encode, decode: decode)
}

// MARK: - Helper Types
// A wrapper around a UUID that will allow it to be encoded at the top level of an encoder.
struct UUIDCodingWrapper : Codable, Equatable {
    let value: UUID

    init(_ value: UUID) {
        self.value = value
    }

    static func ==(_ lhs: UUIDCodingWrapper, _ rhs: UUIDCodingWrapper) -> Bool {
        return lhs.value == rhs.value
    }
}

// MARK: - Tests
class TestCodable : XCTestCase {

    // MARK: - PersonNameComponents
    lazy var personNameComponentsValues: [PersonNameComponents] = [
        makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
        makePersonNameComponents(givenName: "John", familyName: "Appleseed", nickname: "Johnny"),
        makePersonNameComponents(namePrefix: "Dr.", givenName: "Jane", middleName: "A.", familyName: "Appleseed", nameSuffix: "Esq.", nickname: "Janie")
    ]

    func test_PersonNameComponents_JSON() {
        for components in personNameComponentsValues {
            expectRoundTripEqualityThroughJSON(for: components)
        }
    }

    // MARK: - UUID
    lazy var uuidValues: [UUID] = [
        UUID(),
        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
        UUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")!,
        UUID(uuid: uuid_t(0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f))
    ]

    func test_UUID_JSON() {
        for uuid in uuidValues {
            // We have to wrap the UUID since we cannot have a top-level string.
            expectRoundTripEqualityThroughJSON(for: UUIDCodingWrapper(uuid))
        }
    }

    // MARK: - URL
    lazy var urlValues: [URL] = [
        URL(fileURLWithPath: NSTemporaryDirectory()),
        URL(fileURLWithPath: "/"),
        URL(string: "http://apple.com")!,
        URL(string: "swift", relativeTo: URL(string: "http://apple.com")!)!,
        URL(fileURLWithPath: "bin/sh", relativeTo: URL(fileURLWithPath: "/"))
    ]

    func test_URL_JSON() {
        for url in urlValues {
            expectRoundTripEqualityThroughJSON(for: url)
        }
    }

    // MARK: - NSRange
    lazy var nsrangeValues: [NSRange] = [
        NSRange(),
        NSRange(location: 0, length: Int.max),
        NSRange(location: NSNotFound, length: 0),
        ]

    func test_NSRange_JSON() {
        for range in nsrangeValues {
            expectRoundTripEqualityThroughJSON(for: range)
        }
    }

    // MARK: - Locale
    lazy var localeValues: [Locale] = [
        Locale(identifier: ""),
        Locale(identifier: "en"),
        Locale(identifier: "en_US"),
        Locale(identifier: "en_US_POSIX"),
        Locale(identifier: "uk"),
        Locale(identifier: "fr_FR"),
        Locale(identifier: "fr_BE"),
        Locale(identifier: "zh-Hant-HK")
    ]

    func test_Locale_JSON() {
        for locale in localeValues {
            expectRoundTripEqualityThroughJSON(for: locale)
        }
    }

    // MARK: - IndexSet
    lazy var indexSetValues: [IndexSet] = [
        IndexSet(),
        IndexSet(integer: 42),
        IndexSet(integersIn: 0 ..< Int.max)
    ]

    func test_IndexSet_JSON() {
        for indexSet in indexSetValues {
            expectRoundTripEqualityThroughJSON(for: indexSet)
        }
    }

    // MARK: - IndexPath
    lazy var indexPathValues: [IndexPath] = [
        IndexPath(), // empty
        IndexPath(index: 0), // single
        IndexPath(indexes: [1, 2]), // pair
        IndexPath(indexes: [3, 4, 5, 6, 7, 8]), // array
    ]

    func test_IndexPath_JSON() {
        for indexPath in indexPathValues {
            expectRoundTripEqualityThroughJSON(for: indexPath)
        }
    }

    // MARK: - AffineTransform
    lazy var affineTransformValues: [AffineTransform] = [
        AffineTransform.identity,
        AffineTransform(),
        AffineTransform(translationByX: 2.0, byY: 2.0),
        AffineTransform(scale: 2.0),

        // Disabled due to a bug: JSONSerialization loses precision for m12 and m21
        // 0.02741213359204429 is serialized to 0.0274121335920443
        //        AffineTransform(rotationByDegrees: .pi / 2),

        AffineTransform(m11: 1.0, m12: 2.5, m21: 66.2, m22: 40.2, tX: -5.5, tY: 3.7),
        AffineTransform(m11: -55.66, m12: 22.7, m21: 1.5, m22: 0.0, tX: -22, tY: -33),
        AffineTransform(m11: 4.5, m12: 1.1, m21: 0.025, m22: 0.077, tX: -0.55, tY: 33.2),
        AffineTransform(m11: 7.0, m12: -2.3, m21: 6.7, m22: 0.25, tX: 0.556, tY: 0.99),
        AffineTransform(m11: 0.498, m12: -0.284, m21: -0.742, m22: 0.3248, tX: 12, tY: 44)
    ]

    func test_AffineTransform_JSON() {
        for transform in affineTransformValues {
            expectRoundTripEqualityThroughJSON(for: transform)
        }
    }

    // MARK: - Decimal
    lazy var decimalValues: [Decimal] = [
        Decimal.leastFiniteMagnitude,
        Decimal.greatestFiniteMagnitude,
        Decimal.leastNormalMagnitude,
        Decimal.leastNonzeroMagnitude,
        Decimal.pi,
        Decimal()
    ]

    func test_Decimal_JSON() {
        for decimal in decimalValues {
            expectRoundTripEqualityThroughJSON(for: decimal)
        }
    }
    
    // MARK: - CGPoint
    lazy var cgpointValues: [CGPoint] = [
        CGPoint(),
        CGPoint.zero,
        CGPoint(x: 10, y: 20),
        CGPoint(x: -10, y: -20),
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGPoint(x: .greatestFiniteMagnitude, y: .greatestFiniteMagnitude),
    ]
    
    func test_CGPoint_JSON() {
        for point in cgpointValues {
            expectRoundTripEqualityThroughJSON(for: point)
        }
    }
    
    // MARK: - CGSize
    lazy var cgsizeValues: [CGSize] = [
        CGSize(),
        CGSize.zero,
        CGSize(width: 30, height: 40),
        CGSize(width: -30, height: -40),
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
    ]
    
    func test_CGSize_JSON() {
        for size in cgsizeValues {
            expectRoundTripEqualityThroughJSON(for: size)
        }
    }
    
    // MARK: - CGRect
    lazy var cgrectValues: [CGRect] = [
        CGRect(),
        CGRect.zero,
        CGRect(origin: CGPoint(x: 10, y: 20), size: CGSize(width: 30, height: 40)),
        CGRect(origin: CGPoint(x: -10, y: -20), size: CGSize(width: -30, height: -40)),
        CGRect.null,
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGRect.infinite
    ]
    
    func test_CGRect_JSON() {
        for rect in cgrectValues {
            expectRoundTripEqualityThroughJSON(for: rect)
        }
    }
    
    // MARK: - CharacterSet
    lazy var characterSetValues: [CharacterSet] = [
        CharacterSet.controlCharacters,
        CharacterSet.whitespaces,
        CharacterSet.whitespacesAndNewlines,
        CharacterSet.decimalDigits,
        CharacterSet.letters,
        CharacterSet.lowercaseLetters,
        CharacterSet.uppercaseLetters,
        CharacterSet.nonBaseCharacters,
        CharacterSet.alphanumerics,
        CharacterSet.decomposables,
        CharacterSet.illegalCharacters,
        CharacterSet.punctuationCharacters,
        CharacterSet.capitalizedLetters,
        CharacterSet.symbols,
        CharacterSet.newlines,
        CharacterSet(charactersIn: "abcd")
    ]
    
    func test_CharacterSet_JSON() {
        for characterSet in characterSetValues {
            expectRoundTripEqualityThroughJSON(for: characterSet)
        }
    }

    // MARK: - TimeZone
    lazy var timeZoneValues: [TimeZone] = {
#if !os(Android)
        var values = [
            TimeZone(identifier: "America/Los_Angeles")!,
            TimeZone(identifier: "UTC")!,
            ]
        
        #if !os(Linux)
            // Disabled due to [SR-5598] bug, which occurs on Linux, and breaks
            // TimeZone.current == TimeZone(identifier: TimeZone.current.identifier) equality,
            // causing encode -> decode -> compare test to fail.
            values.append(TimeZone.current)
        #endif
#else
        var values = [
            TimeZone(identifier: "UTC")!,
            TimeZone.current
            ]
#endif
        return values
    }()

    func test_TimeZone_JSON() {
        for timeZone in timeZoneValues {
            expectRoundTripEqualityThroughJSON(for: timeZone)
        }
    }

    // MARK: - Calendar
    lazy var calendarValues: [Calendar] = {
        var values = [
            Calendar(identifier: .gregorian),
            Calendar(identifier: .buddhist),
            Calendar(identifier: .chinese),
            Calendar(identifier: .coptic),
            Calendar(identifier: .ethiopicAmeteMihret),
            Calendar(identifier: .ethiopicAmeteAlem),
            Calendar(identifier: .hebrew),
            Calendar(identifier: .iso8601),
            Calendar(identifier: .indian),
            Calendar(identifier: .islamic),
            Calendar(identifier: .islamicCivil),
            Calendar(identifier: .japanese),
            Calendar(identifier: .persian),
            Calendar(identifier: .republicOfChina),
            ]

        #if os(Linux)
            // Custom timeZone set to work around [SR-5598] bug, which occurs on Linux, and breaks equality after
            // serializing and deserializing TimeZone.current
            for index in values.indices {
                values[index].timeZone = TimeZone(identifier: "UTC")!
            }
        #endif

        return values
    }()

    func test_Calendar_JSON() {
        for calendar in calendarValues {
            expectRoundTripEqualityThroughJSON(for: calendar)
        }
    }

    // MARK: - DateComponents
    lazy var dateComponents: Set<Calendar.Component> = [
        .era,
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second,
        .weekday,
        .weekdayOrdinal,
        .weekOfMonth,
        .weekOfYear,
        .yearForWeekOfYear,
        .timeZone,
        .calendar,
        // [SR-5576] Disabled due to a bug in Calendar.dateComponents(_:from:) which crashes on Darwin and returns
        // invalid values on Linux if components include .nanosecond or .quarter.
        // .nanosecond,
        // .quarter,
    ]

    func test_DateComponents_JSON() {
        #if os(Linux)
            var calendar = Calendar(identifier: .gregorian)
            // Custom timeZone set to work around [SR-5598] bug, which occurs on Linux, and breaks equality after
            // serializing and deserializing TimeZone.current
            calendar.timeZone = TimeZone(identifier: "UTC")!
        #else
            let calendar = Calendar(identifier: .gregorian)
        #endif

        let components = calendar.dateComponents(dateComponents, from: Date(timeIntervalSince1970: 1501283776))
        expectRoundTripEqualityThroughJSON(for: components)
    }

    // MARK: - Measurement
    func test_Measurement_JSON() {
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitAcceleration.metersPerSecondSquared))
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitMass.kilograms))
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitLength.miles))
    }
}

extension TestCodable {
    static var allTests: [(String, (TestCodable) -> () throws -> Void)] {
        return [
            ("test_PersonNameComponents_JSON", test_PersonNameComponents_JSON),
            ("test_UUID_JSON", test_UUID_JSON),
            ("test_URL_JSON", test_URL_JSON),
            ("test_NSRange_JSON", test_NSRange_JSON),
            ("test_Locale_JSON", test_Locale_JSON),
            ("test_IndexSet_JSON", test_IndexSet_JSON),
            ("test_IndexPath_JSON", test_IndexPath_JSON),
            ("test_AffineTransform_JSON", test_AffineTransform_JSON),
            ("test_Decimal_JSON", test_Decimal_JSON),
            ("test_CGPoint_JSON", test_CGPoint_JSON),
            ("test_CGSize_JSON", test_CGSize_JSON),
            ("test_CGRect_JSON", test_CGRect_JSON),
            ("test_CharacterSet_JSON", test_CharacterSet_JSON),
            ("test_TimeZone_JSON", test_TimeZone_JSON),
            ("test_Calendar_JSON", test_Calendar_JSON),
            ("test_DateComponents_JSON", test_DateComponents_JSON),
            ("test_Measurement_JSON", test_Measurement_JSON),
        ]
    }
}
