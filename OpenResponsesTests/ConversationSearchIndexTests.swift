import Foundation
import NaturalLanguage
import XCTest
@testable import OpenResponses

final class ConversationSearchIndexTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private let bread = UUID(), car = UUID(), breadMessage = UUID(), carMessage = UUID()

    private var messages: [SearchableMessage] {
        [SearchableMessage(conversationID: bread, messageID: breadMessage,
                           text: "My sourdough starter needs feeding before I bake two loaves of bread on Sunday."),
         SearchableMessage(conversationID: car, messageID: carMessage,
                           text: "The brake pads on my car squeal every time I stop at a traffic light.")]
    }

    func testPassagesSplitAtSentencesAndCapTheCount() {
        let sentence = "This sentence is about forty characters. "
        let passages = ConversationSearchIndex.passages(of: String(repeating: sentence, count: 200))
        XCTAssertEqual(passages.count, ConversationSearchIndex.maxPassagesPerMessage)
        XCTAssertTrue(passages.allSatisfy { $0.count <= ConversationSearchIndex.passageLength })
        XCTAssertEqual(ConversationSearchIndex.passages(of: "   "), [])
    }

    func testVectorsSurviveHalfPrecisionStorage() {
        let vector = (0..<512).map { Double($0 % 7) / 7 - 0.4 }
        let restored = ConversationSearchIndex.unpack(ConversationSearchIndex.pack(vector))
        XCTAssertEqual(restored.count, vector.count)
        XCTAssertGreaterThan(ConversationSearchIndex.cosine(vector.map(Float.init), restored), 0.999)
    }

    func testWordSearchWorksWithoutAnEmbeddingModel() async {
        let index = ConversationSearchIndex(directory: directory, useEmbeddings: false)
        let isSemantic = await index.isSemantic
        XCTAssertFalse(isSemantic)
        let hits = await index.search("Brake pads", in: messages)
        XCTAssertEqual(hits.map(\.conversationID), [car])
        let none = await index.search("sourdough brakes", in: messages)
        XCTAssertTrue(none.isEmpty, "every query word must appear when matching by words alone")
    }

    func testMeaningRanksTheRelatedConversationFirst() async throws {
        let index = ConversationSearchIndex(directory: directory, language: .english)
        guard await index.isSemantic else { throw XCTSkip("No English sentence embedding on this device") }
        let baking = await index.search("baking at home", in: messages)
        XCTAssertEqual(baking.first?.conversationID, bread)
        let repair = await index.search("vehicle maintenance", in: messages)
        XCTAssertEqual(repair.first?.conversationID, car)
    }

    func testEditedMessagesAreEmbeddedAgainAndDeletedOnesAreDropped() async throws {
        let index = ConversationSearchIndex(directory: directory, language: .english)
        guard await index.isSemantic else { throw XCTSkip("No English sentence embedding on this device") }
        await index.update(with: messages)
        let first = await index.cachedDigest(for: breadMessage)
        XCTAssertEqual(first, ConversationSearchIndex.digest(messages[0].text))

        let edited = [SearchableMessage(conversationID: bread, messageID: breadMessage, text: "Rye bread needs a longer proof.")]
        await index.update(with: edited)
        let second = await index.cachedDigest(for: breadMessage)
        XCTAssertEqual(second, ConversationSearchIndex.digest(edited[0].text))
        let count = await index.cachedMessageCount()
        XCTAssertEqual(count, 1, "the car message is no longer present, so its vectors are dropped")

        let reopened = ConversationSearchIndex(directory: directory, language: .english)
        await reopened.update(with: edited)
        let persisted = await reopened.cachedDigest(for: breadMessage)
        XCTAssertEqual(persisted, second, "the cache is read back from disk")
    }
}
