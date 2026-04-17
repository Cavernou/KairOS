import CoreML
import Foundation

@MainActor
struct InferenceEngine {
    private var modelLoader = ModelLoader()
    private let config = ALICEModelConfig()
    
    init() {
        do {
            try modelLoader.loadModel()
        } catch {
            print("Failed to load ALICE model: \(error)")
        }
    }
    
    func respond(to prompt: String) async -> String {
        // Try GGUF model first (chatwaifu)
        if let ggufEngine = modelLoader.getGGUFEngine() {
            print("🧠 Using GGUF model: \(modelLoader.modelName())")
            return await ggufEngine.respond(to: prompt)
        }
        
        // Fallback to Core ML model
        guard let model = modelLoader.getModel() else {
            return "ALICE LITE OFFLINE :: No model loaded"
        }
        
        print("🧠 Using Core ML model: \(modelLoader.modelName())")
        
        do {
            // Prepare input for the model
            let input = try prepareInput(prompt: prompt)
            
            // Run inference
            let output = try await model.prediction(from: input)
            
            // Process output
            return processOutput(output)
            
        } catch {
            return "ALICE LITE ERROR :: \(error.localizedDescription)"
        }
    }
    
    private func prepareInput(prompt: String) throws -> MLFeatureProvider {
        // Tokenize the input (simplified - real implementation would use proper tokenizer)
        let tokens = tokenize(prompt)
        let tokenArray = try MLMultiArray(shape: [1, NSNumber(value: config.maxTokens)], dataType: .double)
        
        for (index, token) in tokens.enumerated() {
            if index < config.maxTokens {
                tokenArray[[0, NSNumber(value: index)]] = NSNumber(value: Double(token))
            }
        }
        
        return try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": tokenArray,
            "temperature": NSNumber(value: config.temperature)
        ])
    }
    
    private func tokenize(_ text: String) -> [Int64] {
        let tokenizer = ALICETokenizer()
        let tokens = tokenizer.encode(text)
        return tokens.map { Int64($0) }
    }
    
    private func processOutput(_ output: MLFeatureProvider) -> String {
        guard let logits = output.featureValue(for: "logits")?.multiArrayValue else {
            return "ALICE LITE ERROR :: No output"
        }
        
        let tokenizer = ALICETokenizer()
        return tokenizer.decodeOutput(logits)
    }
}
