//import XCTest
//
//
//final class HLModelTests: XCTestCase {
//
//    // MARK: - Basic decode/encode
//
//    struct User: HLModel {
//        let id: Int
//        let userName: String     // snakeCase: user_name
//        let email: String
//    }
//
//    func test_decodeFromJSONString() throws {
//        let json = """
//        {"id":1,"user_name":"edgar","email":"edgar@test.com"}
//        """
//        let user = try User.decode(from: json)
//        XCTAssertEqual(user.id, 1)
//        XCTAssertEqual(user.userName, "edgar")
//    }
//
//    func test_decodeFromDictionary() throws {
//        let dict: [String: Any] = ["id": 2, "user_name": "hl", "email": "hl@test.com"]
//        let user = try User.decode(from: dict)
//        XCTAssertEqual(user.id, 2)
//    }
//
//    func test_decodedReturnsNilOnInvalidJSON() {
//        let user = User.decoded(from: "not json")
//        XCTAssertNil(user)
//    }
//
//    func test_encodeToJSONString() {
//        let user = User(id: 1, userName: "edgar", email: "e@e.com")
//        let json = user.toJSONString()
//        XCTAssertNotNil(json)
//        XCTAssertTrue(json!.contains("user_name"))  // snakeCase 编码
//    }
//
//    func test_encodeToDictionary() {
//        let user = User(id: 1, userName: "edgar", email: "e@e.com")
//        let dict = user.toDictionary()
//        XCTAssertEqual(dict?["id"] as? Int, 1)
//    }
//
//    func test_safeDecodeArray_skipsInvalidElements() {
//        let json = """
//        [
//          {"id":1,"user_name":"a","email":"a@a.com"},
//          {"id":"broken","user_name":"b","email":"b@b.com"},
//          {"id":3,"user_name":"c","email":"c@c.com"}
//        ]
//        """
//        let users = User.safeDecodeArray(from: json)
//        // id=2 格式错误被跳过，返回 id=1 和 id=3
//        XCTAssertEqual(users.count, 2)
//        XCTAssertEqual(users[0].id, 1)
//        XCTAssertEqual(users[1].id, 3)
//    }
//
//    // MARK: - @Default
//
//    struct Config: HLModel {
//        @Default<DefaultTrue>       var isEnabled: Bool
//        @Default<DefaultZeroInt>    var retryCount: Int
//        @Default<DefaultEmptyString> var tag: String
//    }
//
//    func test_default_missingField_usesDefaultValue() throws {
//        let config = try Config.decode(from: "{}")
//        XCTAssertTrue(config.isEnabled)      // DefaultTrue
//        XCTAssertEqual(config.retryCount, 0) // DefaultZeroInt
//        XCTAssertEqual(config.tag, "")       // DefaultEmptyString
//    }
//
//    func test_default_nullField_usesDefaultValue() throws {
//        let json = """
//        {"is_enabled":null,"retry_count":null}
//        """
//        let config = try Config.decode(from: json)
//        XCTAssertTrue(config.isEnabled)
//        XCTAssertEqual(config.retryCount, 0)
//    }
//
//    // MARK: - @LossyArray
//
//    struct Feed: HLModel {
//        @LossyArray var items: [User]
//    }
//
//    func test_lossyArray_doesNotCrashOnBadElement() throws {
//        let json = """
//        {"items":[
//          {"id":1,"user_name":"ok","email":"ok@ok.com"},
//          "invalid_string",
//          {"id":3,"user_name":"ok2","email":"ok2@ok.com"}
//        ]}
//        """
//        let feed = try Feed.decode(from: json)
//        XCTAssertEqual(feed.items.count, 2)
//    }
//
//    // MARK: - @LossyString
//
//    struct Profile: HLModel {
//        @LossyString var userId: String
//    }
//
//    func test_lossyString_fromInt() throws {
//        let profile = try Profile.decode(from: #"{"user_id":123}"#)
//        XCTAssertEqual(profile.userId, "123")
//    }
//
//    func test_lossyString_fromBool() throws {
//        let profile = try Profile.decode(from: #"{"user_id":true}"#)
//        XCTAssertEqual(profile.userId, "true")
//    }
//
//    // MARK: - @LossyBool
//
//    struct Setting: HLModel {
//        @LossyBool var isActive: Bool
//    }
//
//    func test_lossyBool_fromInt1() throws {
//        let s = try Setting.decode(from: #"{"is_active":1}"#)
//        XCTAssertTrue(s.isActive)
//    }
//
//    func test_lossyBool_fromInt0() throws {
//        let s = try Setting.decode(from: #"{"is_active":0}"#)
//        XCTAssertFalse(s.isActive)
//    }
//
//    func test_lossyBool_fromString() throws {
//        let s = try Setting.decode(from: #"{"is_active":"true"}"#)
//        XCTAssertTrue(s.isActive)
//    }
//
//    // MARK: - @ISO8601Date
//
//    struct Event: HLModel {
//        @ISO8601Date var createdAt: Date?
//    }
//
//    func test_iso8601Date_parsesZulu() throws {
//        let event = try Event.decode(from: #"{"created_at":"2024-01-15T10:30:00Z"}"#)
//        XCTAssertNotNil(event.createdAt)
//    }
//
//    func test_iso8601Date_parsesOffset() throws {
//        let event = try Event.decode(from: #"{"created_at":"2024-01-15T10:30:00+08:00"}"#)
//        XCTAssertNotNil(event.createdAt)
//    }
//
//    func test_iso8601Date_nullIsNil() throws {
//        let event = try Event.decode(from: #"{"created_at":null}"#)
//        XCTAssertNil(event.createdAt)
//    }
//
//    // MARK: - AnyCodable
//
//    struct Analytics: HLModel {
//        let params: [String: AnyCodable]
//    }
//
//    func test_anyCodable_mixedTypes() throws {
//        let json = """
//        {"params":{"count":5,"label":"click","active":true,"rate":0.9}}
//        """
//        let event = try Analytics.decode(from: json)
//        XCTAssertEqual(event.params["count"]?.value as? Int, 5)
//        XCTAssertEqual(event.params["label"]?.value as? String, "click")
//        XCTAssertEqual(event.params["active"]?.value as? Bool, true)
//    }
//}
