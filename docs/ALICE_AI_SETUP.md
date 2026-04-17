# ALICE AI Implementation Instructions

## Current Status
The iOS ALICE AI implementation has been updated to support real Core ML inference when a model is available, with simulation as a fallback.

## Requirements for Full ALICE AI Functionality

### 1. Convert ALICE 2.0 to Core ML

The conversion script exists at `ALICE_2.0/convert_to_coreml.py` but requires Python dependencies:

```bash
# Create virtual environment
python3 -m venv alice_env
source alice_env/bin/activate

# Install dependencies
pip install torch coremltools

# Run conversion
cd ALICE_2.0
python3 convert_to_coreml.py --input . --output ../ios/KairOS/ALICE/LLM/Model
```

This will generate:
- `ALICELite.mlmodel` (Core ML model file)
- `alice_vocab.json` (Vocabulary file)

### 2. Add Model to iOS App

After conversion, add the generated files to the iOS app:
1. Copy `ALICELite.mlmodel` to `ios/KairOS/ALICE/LLM/Model/`
2. Copy `alice_vocab.json` to `ios/KairOS/ALICE/LLM/Model/`
3. Add these files to the Xcode project
4. Ensure they are included in the app bundle

### 3. Update Model Path

Update the model initialization in the iOS app to point to the correct path:
```swift
let engine = GGUFInferenceEngine(modelPath: Bundle.main.path(forResource: "ALICELite", ofType: "mlmodel"))
```

### 4. Test on Device

Test the inference on iPhone simulator or device:
- Target response time: < 2 seconds for 512 input tokens
- If too slow, reduce context window to 1024 tokens
- If still too slow, consider further pruning or quantization

## Current Implementation

The `GGUFInferenceEngine.swift` has been updated to:
- Try to load a Core ML model (.mlmodel or .mlpackage)
- Perform actual inference using MLModel.prediction()
- Fall back to simulation if model not available
- Display appropriate logging messages

## Known Limitations

1. **Placeholder Model**: The current `chatwaifu_model.gguf` is only 645 bytes and is a placeholder
2. **Python Dependencies**: Conversion script requires torch and coremltools
3. **Tokenization Loop**: Current implementation is simplified - needs proper autoregressive generation loop
4. **Sampling**: Uses greedy sampling - should add temperature and top-k/p sampling for better results

## Next Steps

1. Obtain actual ALICE 2.0 model weights
2. Run conversion script with proper Python environment
3. Add generated Core ML model to iOS app bundle
4. Test inference performance on target device
5. Implement proper autoregressive token generation loop
6. Add configurable sampling parameters
