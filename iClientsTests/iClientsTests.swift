//
//  iClientsTests.swift
//  iClientsTests
//
//  Created by Michael Peralta on 4/21/26.
//

import CoreData
import XCTest

@testable import iClients

// MARK: - ClientRepository tests
@MainActor
final class ClientRepositoryTests: XCTestCase {
    private var controller: PersistenceController!
    private var repo: ClientRepository!
    private var context: NSManagedObjectContext {
        controller.container.viewContext
    }
    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        repo = CoreDataClientRepository(
            context: controller.container.viewContext
        )
    }
    override func tearDown() {
        repo = nil
        controller = nil
        super.tearDown()
    }
    // MARK: fetchAll
    func test_fetchAll_whenStoreIsEmpty_returnsEmptyArray() throws {
        let clients = try repo.fetchAll()
        XCTAssertTrue(clients.isEmpty)
    }
    func test_fetchAll_returnsClientsSortedByCreatedAtDescending() throws {
        let oldest = Client.make(
            in: context,
            companyName: "Oldest",
            email: "",
            phone: ""
        )
        oldest.createdAt = Date(timeIntervalSince1970: 1_000)
        let middle = Client.make(
            in: context,
            companyName: "Middle",
            email: "",
            phone: ""
        )
        middle.createdAt = Date(timeIntervalSince1970: 2_000)
        let newest = Client.make(
            in: context,
            companyName: "Newest",
            email: "",
            phone: ""
        )
        newest.createdAt = Date(timeIntervalSince1970: 3_000)
        try context.save()
        let clients = try repo.fetchAll()
        XCTAssertEqual(
            clients.map { $0.companyName },
            ["Newest", "Middle", "Oldest"],
            "Repository should return clients newest-first"
        )
    }
    // MARK: create
    func test_create_persistsClientWithProvidedFields() throws {
        try repo.create(
            companyName: "Acme Corp",
            email: "hello@acme.com",
            phone: "+1 555 0100"
        )
        let clients = try repo.fetchAll()
        XCTAssertEqual(clients.count, 1)
        let acme = try XCTUnwrap(clients.first)
        XCTAssertEqual(acme.companyName, "Acme Corp")
        XCTAssertEqual(acme.email, "hello@acme.com")
        XCTAssertEqual(acme.phone, "+1 555 0100")
        XCTAssertNotNil(acme.id, "Factory should assign a UUID")
        XCTAssertNotNil(
            acme.createdAt,
            "Factory should assign a createdAt date"
        )
    }
    // MARK: update
    func test_update_modifiesExistingClient() throws {
        try repo.create(
            companyName: "Old Name",
            email: "old@example.com",
            phone: "+1 000 000 0000"
        )
        let client = try XCTUnwrap(try repo.fetchAll().first)
        let originalID = client.id
        let originalCreatedAt = client.createdAt
        try repo.update(
            client,
            companyName: "New Name",
            email: "new@example.com",
            phone: "+1 111 111 1111"
        )
        let fetched = try XCTUnwrap(try repo.fetchAll().first)
        XCTAssertEqual(fetched.companyName, "New Name")
        XCTAssertEqual(fetched.email, "new@example.com")
        XCTAssertEqual(fetched.phone, "+1 111 111 1111")
        XCTAssertEqual(
            fetched.id,
            originalID,
            "id should be preserved across updates"
        )
        XCTAssertEqual(
            fetched.createdAt,
            originalCreatedAt,
            "createdAt should be preserved across updates"
        )
    }
    // MARK: delete
    func test_delete_removesClientFromStore() throws {
        try repo.create(companyName: "To Delete", email: "", phone: "")
        let client = try XCTUnwrap(try repo.fetchAll().first)
        try repo.delete(client)
        XCTAssertEqual(try repo.fetchAll().count, 0)
    }
    func test_delete_cascadesToClientAddresses() throws {
        try repo.create(companyName: "HasAddresses", email: "", phone: "")
        let client = try XCTUnwrap(try repo.fetchAll().first)
        _ = Address.make(
            in: context,
            client: client,
            street: "1 First St",
            city: "Brooklyn",
            country: "USA",
            postalCode: "11201"
        )
        _ = Address.make(
            in: context,
            client: client,
            street: "2 Second St",
            city: "Queens",
            country: "USA",
            postalCode: "11355"
        )
        try context.save()
        let addressFetch: NSFetchRequest<Address> = Address.fetchRequest()
        XCTAssertEqual(
            try context.fetch(addressFetch).count,
            2,
            "Sanity check: both addresses should exist before delete"
        )
        try repo.delete(client)
        XCTAssertEqual(try repo.fetchAll().count, 0)
        XCTAssertEqual(
            try context.fetch(addressFetch).count,
            0,
            "Deleting a client must cascade-delete all of its addresses"
        )
    }
}

// MARK: - ClientFormViewModel tests
@MainActor
final class ClientFormViewModelTests: XCTestCase {
    private var controller: PersistenceController!
    private var repo: ClientRepository!
    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        repo = CoreDataClientRepository(
            context: controller.container.viewContext
        )
    }
    override func tearDown() {
        repo = nil
        controller = nil
        super.tearDown()
    }
    // 1. Create mode starts blank
    func test_init_createMode_startsWithEmptyFields() {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        XCTAssertEqual(vm.companyName, "")
        XCTAssertEqual(vm.email, "")
        XCTAssertEqual(vm.phone, "")
        XCTAssertFalse(vm.isValid)
    }
    // 2. Edit mode pre-populates from the existing client
    func test_init_editMode_prePopulatesAllFieldsFromClient() {
        let client = Client.make(
            in: controller.container.viewContext,
            companyName: "Acme Corp",
            email: "hello@acme.com",
            phone: "+1 555 0100"
        )
        let vm = ClientFormViewModel(mode: .edit(client), repo: repo)
        XCTAssertEqual(vm.companyName, "Acme Corp")
        XCTAssertEqual(vm.email, "hello@acme.com")
        XCTAssertEqual(vm.phone, "+1 555 0100")
        XCTAssertTrue(
            vm.isValid,
            "Pre-populated with valid data should be immediately valid"
        )
    }
    // 3. isValid requires ALL three fields to meet their mins AND formats
    func test_isValid_blocksSaveUntilAllRequirementsMet() {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        vm.companyName = "A"
        XCTAssertFalse(vm.isValid, "Company name below min should fail")
        vm.companyName = "Acme"
        XCTAssertFalse(vm.isValid, "Email still empty should fail")
        vm.email = "bad"
        XCTAssertFalse(vm.isValid, "Email below min length should fail")
        vm.email = "a@b.c"
        XCTAssertFalse(vm.isValid, "Phone still empty should fail")
        vm.phone = "12345"
        XCTAssertFalse(vm.isValid, "Phone below min length should fail")
        vm.phone = "5551234"
        XCTAssertTrue(
            vm.isValid,
            "All fields at/above min with valid formats should pass"
        )
    }
    // 4. Email regex catches the obvious bad formats
    func test_isEmailFormatValid_rejectsMalformedAddresses() {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        for bad in [
            "plainstring", "no at symbol", "a@b", "a@.com", "@b.com",
            "a @b.com",
        ] {
            vm.email = bad
            XCTAssertFalse(
                vm.isEmailFormatValid,
                "Expected '\(bad)' to be rejected by email format check"
            )
        }
        for good in ["a@b.co", "user@example.com", "user+tag@sub.domain.co"] {
            vm.email = good
            XCTAssertTrue(
                vm.isEmailFormatValid,
                "Expected '\(good)' to be accepted by email format check"
            )
        }
    }
    // 5. Phone validator uses NSDataDetector — accepts common formats
    func test_isPhoneFormatValid_acceptsRealisticPhoneFormats() {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        for good in [
            "5551234567", "555-123-4567", "(555) 123-4567", "+1 555 123 4567",
        ] {
            vm.phone = good
            XCTAssertTrue(
                vm.isPhoneFormatValid,
                "Expected '\(good)' to be accepted"
            )
        }
        for bad in ["abc", "phone number", "!!!!"] {
            vm.phone = bad
            XCTAssertFalse(
                vm.isPhoneFormatValid,
                "Expected '\(bad)' to be rejected"
            )
        }
    }
    // 6. Max-length cap rejects overflow without throwing
    func test_companyName_isClampedToMaxLength() {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        let overflow = String(
            repeating: "x",
            count: ClientFormViewModel.companyNameMax + 20
        )
        vm.companyName = overflow
        XCTAssertEqual(vm.companyName.count, ClientFormViewModel.companyNameMax)
    }
    // 7. Save() trims whitespace AND persists the new client via the repo
    func test_save_inCreateMode_persistsTrimmedValues() throws {
        let vm = ClientFormViewModel(mode: .create, repo: repo)
        vm.companyName = "  Acme Corp   "
        vm.email = "  hello@acme.com  "
        vm.phone = "  5551234567  "
        try vm.save()
        let clients = try repo.fetchAll()
        XCTAssertEqual(clients.count, 1)
        let saved = try XCTUnwrap(clients.first)
        XCTAssertEqual(saved.companyName, "Acme Corp")
        XCTAssertEqual(saved.email, "hello@acme.com")
        XCTAssertEqual(saved.phone, "5551234567")
    }
}
