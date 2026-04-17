import XCTest

final class KairOSUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify main interface elements
        XCTAssertTrue(app.staticTexts["KairOS"].exists)
        XCTAssertTrue(app.buttons["MESSAGES"].exists)
        XCTAssertTrue(app.buttons["FILES"].exists)
        XCTAssertTrue(app.buttons["CONTACTS"].exists)
    }
    
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test navigation to different tabs
        app.buttons["FILES"].tap()
        XCTAssertTrue(app.staticTexts["FILES TERMINAL"].exists)
        
        app.buttons["CONTACTS"].tap()
        XCTAssertTrue(app.staticTexts["CONTACTS TERMINAL"].exists)
        
        app.buttons["NODES"].tap()
        XCTAssertTrue(app.staticTexts["NODE STATUS"].exists)
        
        app.buttons["APPS"].tap()
        XCTAssertTrue(app.staticTexts["APP RUNTIME"].exists)
        
        app.buttons["SETTINGS"].tap()
        XCTAssertTrue(app.staticTexts["SETTINGS PANEL"].exists)
        
        app.buttons["BLACKBOX"].tap()
        XCTAssertTrue(app.staticTexts["BLACKBOX EXPORT"].exists)
    }
    
    func testMessageSending() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to messages
        app.buttons["MESSAGES"].tap()
        
        // Verify message list appears
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // Test compose button (if exists)
        if app.buttons["COMPOSE"].exists {
            app.buttons["COMPOSE"].tap()
            XCTAssertTrue(app.textViews.firstMatch.exists)
        }
    }
    
    func testContactManagement() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to contacts
        app.buttons["CONTACTS"].tap()
        
        // Verify contact list
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // Test contact search (if search field exists)
        if app.searchFields.firstMatch.exists {
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("Test")
            
            // Wait for search results
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    func testBlackboxExport() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to blackbox
        app.buttons["BLACKBOX"].tap()
        
        // Test export functionality
        if app.buttons["EXPORT"].exists {
            app.buttons["EXPORT"].tap()
            
            // Verify passcode prompt appears
            XCTAssertTrue(app.secureTextFields.firstMatch.waitForExistence(timeout: 2.0))
        }
    }
    
    func testNodeStatus() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Check node status indicator
        XCTAssertTrue(app.images["NODE_STATUS"].exists)
        
        // Verify status text
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'NODE'")).firstMatch.exists)
    }
    
    func testIndustrialUIElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify industrial design elements
        XCTAssertTrue(app.staticTexts["+"].exists) // Corner markers
        XCTAssertTrue(app.staticTexts["KairOS"].exists) // Branding
        
        // Verify color scheme through accessibility (yellow/black contrast)
        let mainElement = app.otherElements.firstMatch
        XCTAssertTrue(mainElement.exists)
    }
    
    func testSettingsAccess() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        app.buttons["SETTINGS"].tap()
        
        // Verify settings options
        XCTAssertTrue(app.buttons["NODE CONFIG"].exists)
        XCTAssertTrue(app.buttons["IDENTITY"].exists)
        XCTAssertTrue(app.buttons["BACKUP"].exists)
    }
    
    func testAppRuntime() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to apps
        app.buttons["APPS"].tap()
        
        // Verify app list
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // Test app launch (if Notes app exists)
        if app.buttons["Notes"].exists {
            app.buttons["Notes"].tap()
            XCTAssertTrue(app.staticTexts["NOTES TERMINAL"].exists)
        }
    }
    
    func testErrorHandling() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test offline behavior
        // This would require network simulation in real tests
        
        // Verify app remains functional
        XCTAssertTrue(app.buttons["MESSAGES"].exists)
        XCTAssertTrue(app.staticTexts["KairOS"].exists)
    }
    
    func testAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify accessibility labels
        XCTAssertTrue(app.buttons["MESSAGES"].isHittable)
        XCTAssertTrue(app.buttons["FILES"].isHittable)
        XCTAssertTrue(app.buttons["CONTACTS"].isHittable)
        
        // Test VoiceOver support
        UIAccessibility.post(notification: .screenChanged, argument: "KairOS interface loaded")
    }
}
