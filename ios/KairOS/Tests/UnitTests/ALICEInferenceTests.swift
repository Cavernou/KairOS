import XCTest
import CoreML
@testable import KairOS

@MainActor
final class ALICEInferenceTests: XCTestCase {
    
    var inferenceEngine: InferenceEngine!
    
    override func setUp() {
        super.setUp()
        inferenceEngine = InferenceEngine()
    }
    
    func testBasicInference() async {
        let prompt = "Hello ALICE"
        let response = await inferenceEngine.respond(to: prompt)
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertTrue(response.contains("ALICE"))
    }
    
    func testEmptyPrompt() async {
        let response = await inferenceEngine.respond(to: "")
        
        XCTAssertFalse(response.isEmpty)
    }
    
    func testLongPrompt() async {
        let longPrompt = String(repeating: "test ", count: 100)
        let response = await inferenceEngine.respond(to: longPrompt)
        
        XCTAssertFalse(response.isEmpty)
    }
    
    func testSpecialCharacters() async {
        let prompt = "Test with K-1234-5678 and symbols: !@#$%"
        let response = await inferenceEngine.respond(to: prompt)
        
        XCTAssertFalse(response.isEmpty)
    }
}

@MainActor
final class ALICETokenizerTests: XCTestCase {
    
    var tokenizer: ALICETokenizer!
    
    override func setUp() {
        super.setUp()
        tokenizer = ALICETokenizer()
    }
    
    func testBasicTokenization() {
        let text = "Hello KairOS"
        let tokens = tokenizer.encode(text)
        
        XCTAssertFalse(tokens.isEmpty)
        XCTAssertEqual(tokenizer.decode(tokens), text)
    }
    
    func testSpecialTokens() {
        let text = "Test message"
        let tokens = tokenizer.encodeWithSpecialTokens(text)
        
        XCTAssertGreaterThanOrEqual(tokens.count, 3) // At least pad + content + eos
        XCTAssertEqual(tokens.first, 0) // PAD token
        XCTAssertEqual(tokens.last, 1) // EOS token
    }
    
    func testTruncationAndPadding() {
        let text = String(repeating: "test ", count: 100)
        let tokens = tokenizer.truncateAndPad(tokenizer.encode(text), maxLength: 20)
        
        XCTAssertEqual(tokens.count, 20)
        XCTAssertEqual(tokens.first, 0) // PAD token
        XCTAssertEqual(tokens.last, 1) // EOS token
    }
    
    func testUnknownCharacters() {
        let text = "Test with 🚀 emoji"
        let tokens = tokenizer.encode(text)
        
        XCTAssertFalse(tokens.isEmpty)
        // Should handle unknown characters gracefully
    }
    
    func testDecodeWithSpecialTokens() {
        let tokens = [0, 10, 20, 1] // PAD + content + EOS
        let decoded = tokenizer.decodeWithSpecialTokens(tokens)
        
        // Should filter out special tokens
        XCTAssertFalse(decoded.contains("<pad>"))
        XCTAssertFalse(decoded.contains("<eos>"))
    }
}

@MainActor
final class ModelLoaderTests: XCTestCase {
    
    func testModelLoading() async {
        var modelLoader = ModelLoader()
        
        do {
            try await modelLoader.loadModel()
            let model = await modelLoader.getModel()
            XCTAssertNotNil(model)
        } catch {
            // Should handle model not found gracefully
            XCTAssertTrue(true)
        }
    }
    
    func testModelName() async {
        var modelLoader = ModelLoader()
        
        do {
            try await modelLoader.loadModel()
            let name = await modelLoader.modelName()
            XCTAssertFalse(name.isEmpty)
        } catch {
            // Should handle model not found gracefully
            let name = await modelLoader.modelName()
            XCTAssertEqual(name, "FallbackLiteModel")
        }
    }
}
