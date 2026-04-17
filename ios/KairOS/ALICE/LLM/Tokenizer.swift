import Foundation
import CoreML

struct ALICETokenizer {
    private let vocab: [String: Int]
    private let reverseVocab: [Int: String]
    private let padToken = 0
    private let eosToken = 1
    private let unkToken = 2
    
    init() {
        // Load vocabulary from bundle or use default
        if let vocabURL = Bundle.main.url(forResource: "alice_vocab", withExtension: "json"),
           let data = try? Data(contentsOf: vocabURL),
           let vocabDict = try? JSONSerialization.jsonObject(with: data) as? [String: Int] {
            self.vocab = vocabDict
            self.reverseVocab = Dictionary(uniqueKeysWithValues: vocabDict.map { ($1, $0) })
        } else {
            // Fallback vocabulary for basic ASCII
            self.vocab = ALICETokenizer.createFallbackVocab()
            self.reverseVocab = Dictionary(uniqueKeysWithValues: self.vocab.map { ($1, $0) })
        }
    }
    
    func encode(_ text: String) -> [Int] {
        return text.unicodeScalars.map { scalar in
            let char = String(scalar)
            return vocab[char] ?? unkToken
        }
    }
    
    func decode(_ tokens: [Int]) -> String {
        return tokens.compactMap { token in
            guard token >= 0 && token < reverseVocab.count else { return nil }
            return reverseVocab[token]
        }.joined()
    }
    
    func encodeWithSpecialTokens(_ text: String) -> [Int] {
        var tokens = [padToken]
        tokens.append(contentsOf: encode(text))
        tokens.append(eosToken)
        return tokens
    }
    
    func decodeWithSpecialTokens(_ tokens: [Int]) -> String {
        // Filter out special tokens
        let filtered = tokens.filter { $0 != padToken && $0 != eosToken && $0 != unkToken }
        return decode(filtered)
    }
    
    func truncateAndPad(_ tokens: [Int], maxLength: Int) -> [Int] {
        var result = tokens
        
        // Truncate if too long
        if result.count > maxLength - 2 { // Account for special tokens
            result = Array(result.prefix(maxLength - 2))
        }
        
        // Add special tokens
        result.insert(padToken, at: 0)
        result.append(eosToken)
        
        // Pad if too short
        while result.count < maxLength {
            result.append(padToken)
        }
        
        return result
    }
    
    private static func createFallbackVocab() -> [String: Int] {
        var vocab: [String: Int] = [:]
        
        // Special tokens
        vocab["<pad>"] = 0
        vocab["<eos>"] = 1
        vocab["<unk>"] = 2
        
        // Basic ASCII characters
        var id = 3
        for i: UInt8 in (32...126) { // Printable ASCII
            let scalar = UnicodeScalar(i)
            let char = String(Character(scalar))
            vocab[char] = id
            id += 1
        }
        
        // Common KairOS-specific tokens
        vocab["K-"] = id
        id += 1
        
        // Numbers and common symbols
        for i in 0...9 {
            vocab[String(i)] = id
            id += 1
        }
        
        return vocab
    }
}

// MARK: - Tokenizer for Core ML Input
extension ALICETokenizer {
    func prepareInputForModel(_ text: String, maxLength: Int = 512) -> MLMultiArray? {
        let tokens = encodeWithSpecialTokens(text)
        let paddedTokens = truncateAndPad(tokens, maxLength: maxLength)
        
        guard let multiArray = try? MLMultiArray(shape: [NSNumber(value: 1), NSNumber(value: maxLength)], dataType: .double) else {
            return nil
        }
        
        for (index, token) in paddedTokens.enumerated() {
            multiArray[[0, NSNumber(value: index)]] = NSNumber(value: Double(token))
        }
        
        return multiArray
    }
    
    func decodeOutput(_ logits: MLMultiArray) -> String {
        guard logits.shape.count >= 2,
              let sequenceLength = logits.shape[1].intValue as Int? else {
            return ""
        }
        
        // Simple greedy decoding
        var tokens: [Int] = []
        
        for position in 0..<sequenceLength {
            let offset = position
            let value = logits[offset]
            let tokenValue = value.int64Value
            
            if tokenValue == 1 { break } // EOS token
            if tokenValue > 2 { tokens.append(Int(tokenValue)) } // Skip special tokens
        }
        
        return decodeWithSpecialTokens(tokens)
    }
}

// Legacy compatibility
typealias Tokenizer = ALICETokenizer

