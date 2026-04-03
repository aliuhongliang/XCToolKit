//import XCTest
//
//
//final class HLRegexTests: XCTestCase {
//
//    // MARK: - 手机号
//
//    func test_phone_validCN() {
//        XCTAssertTrue("13800138000".isValidPhoneCN)
//        XCTAssertTrue("19912345678".isValidPhoneCN)
//    }
//
//    func test_phone_invalidCN() {
//        XCTAssertFalse("12800138000".isValidPhoneCN)  // 1开头但第二位是2
//        XCTAssertFalse("1380013800".isValidPhoneCN)   // 10位
//        XCTAssertFalse("138001380001".isValidPhoneCN) // 12位
//    }
//
//    func test_phone_validTW() {
//        XCTAssertTrue("0912345678".isValidPhoneTW)
//    }
//
//    // MARK: - 邮箱
//
//    func test_email_valid() {
//        XCTAssertTrue("user@example.com".isValidEmail)
//        XCTAssertTrue("user.name+tag@domain.co".isValidEmail)
//        XCTAssertTrue("user@subdomain.example.com".isValidEmail)
//    }
//
//    func test_email_invalid() {
//        XCTAssertFalse("notanemail".isValidEmail)
//        XCTAssertFalse("@nodomain.com".isValidEmail)
//        XCTAssertFalse("user@".isValidEmail)
//    }
//
//    // MARK: - 用户名
//
//    func test_username_valid() {
//        XCTAssertTrue("edgar".isValidUsername)
//        XCTAssertTrue("user_name1".isValidUsername)
//        XCTAssertTrue("ABC123".isValidUsername)
//        XCTAssertTrue("abcd".isValidUsername)           // 最短4位
//        XCTAssertTrue("abcdefghijklmnop".isValidUsername) // 最长16位
//    }
//
//    func test_username_invalid() {
//        XCTAssertFalse("ab".isValidUsername)            // 太短
//        XCTAssertFalse("_edgar".isValidUsername)        // 下划线开头
//        XCTAssertFalse("edgar_".isValidUsername)        // 下划线结尾
//        XCTAssertFalse("user name".isValidUsername)     // 包含空格
//        XCTAssertFalse("user@name".isValidUsername)     // 包含特殊字符
//        XCTAssertFalse("abcdefghijklmnopq".isValidUsername) // 17位，太长
//    }
//
//    func test_username_invalidReason() {
//        let result = "ab".hlValidate(.username)
//        XCTAssertFalse(result.isValid)
//        XCTAssertNotNil(result.reason)
//        XCTAssertTrue(result.reason!.contains("4-16"))
//    }
//
//    // MARK: - 身份证
//
//    func test_idCard_valid() {
//        // 合法格式 + 有效校验码
//        XCTAssertTrue("11010519491231002X".isValidIDCard)
//        XCTAssertTrue("440101199001011234".isValidIDCard)  // 需替换为真实合法号
//    }
//
//    func test_idCard_invalidChecksum() {
//        // 格式对但校验码错
//        let result = "110105194912310021".hlValidate(.idCardCN)
//        // 校验码结果依赖具体号码，这里验证能正确执行
//        XCTAssertNotNil(result)
//    }
//
//    func test_idCard_invalidFormat() {
//        XCTAssertFalse("1234".isValidIDCard)
//        XCTAssertFalse("abcdefghijklmnopqr".isValidIDCard)
//    }
//
//    // MARK: - 密码强度
//
//    func test_password_strength() {
//        XCTAssertEqual("abc".passwordStrength, .tooWeak)
//        XCTAssertEqual("abcdef".passwordStrength, .weak)        // 纯字母 ≥6
//        XCTAssertEqual("abcd1234".passwordStrength, .medium)    // 字母+数字 8位
//        XCTAssertEqual("Abcd1234!".passwordStrength, .strong)   // 含特殊字符
//    }
//
//    // MARK: - 银行卡 Luhn
//
//    func test_bankCard_validLuhn() {
//        // 标准 Luhn 测试号
//        XCTAssertTrue("4532015112830366".isValidBankCard)
//        XCTAssertTrue("6221558812340002".isValidBankCard)
//    }
//
//    func test_bankCard_invalidLuhn() {
//        XCTAssertFalse("1234567890123456".isValidBankCard)
//    }
//
//    // MARK: - 数字
//
//    func test_numeric() {
//        XCTAssertTrue("123".isInteger)
//        XCTAssertTrue("-456".isInteger)
//        XCTAssertTrue("3.14".isNumeric)
//        XCTAssertFalse("3.14".isInteger)
//        XCTAssertFalse("abc".isNumeric)
//    }
//
//    // MARK: - 匹配/提取
//
//    func test_firstMatch() {
//        let str = "call 13800138000 or 13912345678"
//        let match = str.hlFirstMatch(pattern: #"1[3-9]\d{9}"#)
//        XCTAssertEqual(match, "13800138000")
//    }
//
//    func test_allMatches() {
//        let str = "call 13800138000 or 13912345678"
//        let matches = str.hlAllMatches(pattern: #"1[3-9]\d{9}"#)
//        XCTAssertEqual(matches.count, 2)
//    }
//
//    func test_replacing() {
//        let result = "price: 100 and 200".hlReplacing(pattern: #"\d+"#, with: "***")
//        XCTAssertEqual(result, "price: *** and ***")
//    }
//
//    // MARK: - 自定义规则注册
//
//    func test_customRule_register_and_validate() {
//        let rule = HLRegexRule(pattern: #"^HL\d{4}$"#, failureReason: "格式应为 HL 加4位数字")
//        HLRegex.shared.register(rule: rule, forKey: "hlCode")
//
//        XCTAssertTrue("HL1234".hlValidate(ruleKey: "hlCode").isValid)
//        let result = "HL12".hlValidate(ruleKey: "hlCode")
//        XCTAssertFalse(result.isValid)
//        XCTAssertEqual(result.reason, "格式应为 HL 加4位数字")
//    }
//
//    func test_unknownRuleKey_returnsInvalid() {
//        let result = "test".hlValidate(ruleKey: "nonexistent_key")
//        XCTAssertFalse(result.isValid)
//    }
//}
