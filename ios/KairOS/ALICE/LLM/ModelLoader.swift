import CoreML
import Foundation

@MainActor
struct ModelLoader {
    private var mlModel: MLModel?
    private var ggufEngine: GGUFInferenceEngine?
    
    mutating func loadModel() throws {
        // Try GGUF model first (chatwaifu)
        if let ggufEngine = try? loadGGUFModel() {
            self.ggufEngine = ggufEngine
            print("✅ GGUF model loaded successfully")
            return
        }
        
        // Fallback to Core ML models
        guard let modelURL = Bundle.main.url(forResource: "ALICELite", withExtension: "mlmodelc") else {
            // Fallback to default lightweight model if ALICE Lite not found
            guard let fallbackURL = Bundle.main.url(forResource: "Phi3Mini", withExtension: "mlmodelc") else {
                throw ModelError.modelNotFound
            }
            mlModel = try MLModel(contentsOf: fallbackURL)
            print("⚠️ Using fallback Core ML model")
            return
        }
        
        mlModel = try MLModel(contentsOf: modelURL)
        print("✅ Core ML model loaded successfully")
    }
    
    func getModel() -> MLModel? {
        return mlModel
    }
    
    func getGGUFEngine() -> GGUFInferenceEngine? {
        return ggufEngine
    }
    
    func modelName() -> String {
        if let ggufEngine = ggufEngine {
            let info = ggufEngine.getModelInfo()
            return "\(info.name) (\(info.quantization))"
        }
        
        return (mlModel?.modelDescription.metadata[.description] as? String) ?? "FallbackLiteModel"
    }
    
    func isGGUFModel() -> Bool {
        return ggufEngine != nil
    }
    
    func loadGGUFModel() throws -> GGUFInferenceEngine? {
        // Try to load GGUF model from bundle first
        if let ggufURL = Bundle.main.url(forResource: "chatwaifu_v1.0-q4_k_m", withExtension: "gguf") {
            return GGUFInferenceEngine(modelPath: ggufURL.path)
        }
        
        // Fallback to documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ModelError.modelNotFound
        }
        
        let ggufPath = documentsURL.appendingPathComponent("chatwaifu_v1.0-q4_k_m.gguf").path
        
        if FileManager.default.fileExists(atPath: ggufPath) {
            return GGUFInferenceEngine(modelPath: ggufPath)
        }
        
        throw ModelError.modelNotFound
    }
    
    func getGGUFModelInfo() -> ModelInfo? {
        guard let ggufEngine = try? loadGGUFModel() else {
            return nil
        }
        return ggufEngine.getModelInfo()
    }
    
    enum ModelError: Error {
        case modelNotFound
        case modelLoadFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .modelNotFound:
                return "ALICE Lite model not found. Please ensure ALICE_2.0 folder has been processed."
            case .modelLoadFailed(let error):
                return "Failed to load model: \(error.localizedDescription)"
            }
        }
    }
}

struct ALICEModelConfig {
    let maxTokens: Int = 512
    let temperature: Float = 0.7
    let contextLength: Int = 1024
    
    // System prompt derived from ALICE 2.0
    let systemPrompt = """
    You are ALICE, the AI assistant for KairOS – a secure industrial communication terminal.
    Current user K‑number: {{K_NUMBER}}.
    Node trust score: {{TRUST_SCORE}}.
    You can use tools, but must ask for confirmation before sending messages, deleting files, or making calls.
    Maintain a utilitarian, no‑nonsense tone.
    """
}
