import XCTest
final class iClientsUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        app.launch()
    }
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    // MARK: - 1. Launch shows the empty state on first run
    @MainActor
    func test_launch_emptyStoreShowsEmptyState() {
        XCTAssertTrue(
            app.navigationBars["iClients"].waitForExistence(timeout: 5),
            "Should land on the clients screen after launch"
        )
        XCTAssertTrue(
            app.staticTexts["No clients yet"].exists,
            "Empty-store run should surface the empty-state copy"
        )
    }
    // MARK: - 2. Adding a valid client makes it appear in the grid
    @MainActor
    func test_addClient_withValidData_appearsInTheList() {
        tapAddClient()
        fillClientForm(
            companyName: "Acme Corp",
            email: "hello@acme.com",
            phone: "5551234567"
        )
        app.buttons["Add"].tap()
        XCTAssertTrue(
            app.staticTexts["Acme Corp"].waitForExistence(timeout: 2),
            "New client card should appear in the grid"
        )
    }
    // MARK: - 3. Save button stays disabled until every required field is valid
    @MainActor
    func test_addClient_saveButtonDisabled_whenFormIncomplete() {
        tapAddClient()
        let saveButton = app.buttons["Add"]
        XCTAssertFalse(saveButton.isEnabled, "Should be disabled with all fields empty")
        type(into: "companyNameField", text: "Ab")
        XCTAssertFalse(saveButton.isEnabled, "Still disabled — email/phone empty")
        type(into: "emailField", text: "bademail")
        XCTAssertFalse(saveButton.isEnabled, "Still disabled — email has bad format")
        type(into: "phoneField", text: "5551234567")
        XCTAssertFalse(saveButton.isEnabled, "Still disabled — email format still invalid")
        // Fix the email
        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.press(forDuration: 1.0)
        app.menuItems["Select All"].tap()
        emailField.typeText("hello@acme.com")
        XCTAssertTrue(saveButton.isEnabled, "Enabled only once every field is valid")
    }
    // MARK: - 4. Long-press → Edit updates the card
    @MainActor
    func test_editClient_viaContextMenu_updatesCardLabel() {
        tapAddClient()
        fillClientForm(companyName: "Old Name", email: "a@b.co", phone: "5551234567")
        app.buttons["Add"].tap()
        let originalCard = app.staticTexts["Old Name"]
        XCTAssertTrue(originalCard.waitForExistence(timeout: 2))
        originalCard.press(forDuration: 1.2)
        app.buttons["Edit"].tap()
        let field = app.textFields["companyNameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.press(forDuration: 1.0)
        app.menuItems["Select All"].tap()
        field.typeText("New Name")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["New Name"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Old Name"].exists)
    }
    // MARK: - 5. Long-press → Delete removes the card
    @MainActor
    func test_deleteClient_viaContextMenu_removesCard() {
        tapAddClient()
        fillClientForm(companyName: "Delete Me", email: "d@b.co", phone: "5551234567")
        app.buttons["Add"].tap()
        let card = app.staticTexts["Delete Me"]
        XCTAssertTrue(card.waitForExistence(timeout: 2))
        card.press(forDuration: 1.2)
        app.buttons["Delete"].tap()
        XCTAssertFalse(
            card.waitForExistence(timeout: 2),
            "Card should be gone after context-menu delete"
        )
    }
    // MARK: - 6. Drill into a client, add an address, confirm it's listed
    @MainActor
    func test_addAddress_appearsInAddressListForClient() {
        tapAddClient()
        fillClientForm(companyName: "Has Addresses", email: "ha@x.co", phone: "5551234567")
        app.buttons["Add"].tap()
        app.staticTexts["Has Addresses"].tap()
        XCTAssertTrue(app.navigationBars["Has Addresses"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["No addresses yet"].exists)
        app.buttons["Add address"].tap()
        type(into: "streetField", text: "123 Main St")
        type(into: "cityField", text: "Brooklyn")
        type(into: "countryField", text: "United States")
        type(into: "postalCodeField", text: "11201")
        app.buttons["Add"].tap()
        XCTAssertTrue(
            app.staticTexts["123 Main St"].waitForExistence(timeout: 2),
            "New address should appear in the address list"
        )
    }
    // MARK: - 7. Address save stays disabled for invalid country length
    @MainActor
    func test_addAddress_countryLengthValidation_controlsSaveButton() {
        tapAddClient()
        fillClientForm(companyName: "Country Rules", email: "rules@x.co", phone: "5551234567")
        app.buttons["Add"].tap()
        app.staticTexts["Country Rules"].tap()
        app.buttons["Add address"].tap()
        type(into: "streetField", text: "123 Main St")
        type(into: "cityField", text: "Brooklyn")
        type(into: "postalCodeField", text: "11201")
        let addButton = app.buttons["Add"]
        XCTAssertFalse(addButton.isEnabled, "Country is still empty")
        type(into: "countryField", text: "U")
        XCTAssertFalse(addButton.isEnabled, "Country must have at least 2 characters")
        let countryField = app.textFields["countryField"]
        countryField.tap()
        countryField.typeText("nited States and Beyond")
        XCTAssertEqual(countryField.value as? String, "United States and Beyond")
        countryField.typeText(String(repeating: "A", count: 30))
        // Don't assert exact XCUI text value here; assert behavior.
        // If max-length clamping is active, Save/Add should remain enabled.
        let enabledAfterOverflow = NSPredicate(format: "isEnabled == true")
        expectation(for: enabledAfterOverflow, evaluatedWith: addButton)
        waitForExpectations(timeout: 2)
        XCTAssertTrue(addButton.isEnabled, "Country becomes valid at 2...40 characters")
    }
    // MARK: - Helpers
    private func tapAddClient() {
        let addButton = app.buttons["Add client"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
    }
    private func fillClientForm(companyName: String, email: String, phone: String) {
        type(into: "companyNameField", text: companyName)
        type(into: "emailField",        text: email)
        type(into: "phoneField",        text: phone)
    }
    private func type(into identifier: String, text: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 2), "Missing field: \(identifier)")
        field.tap()
        field.typeText(text)
    }
}
