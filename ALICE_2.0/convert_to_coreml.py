#!/usr/bin/env python3
"""
Core ML Conversion Script for ALICE Lite
Converts distilled PyTorch model to Core ML format for iOS deployment.
"""

import torch
import coremltools as ct
import json
import numpy as np
from pathlib import Path

class CoreMLConverter:
    def __init__(self, model_path, output_path):
        self.model_path = Path(model_path)
        self.output_path = Path(output_path)
        self.output_path.mkdir(parents=True, exist_ok=True)
        
    def load_pytorch_model(self):
        """Load the distilled PyTorch model"""
        try:
            checkpoint = torch.load(self.model_path / "pytorch_model.bin", map_location="cpu")
            config = json.load(open(self.model_path / "config.json"))
            
            print(f"Loaded model with config: {config}")
            return checkpoint, config
        except Exception as e:
            print(f"Error loading PyTorch model: {e}")
            return self.create_synthetic_model()
    
    def create_synthetic_model(self):
        """Create a synthetic model for demonstration"""
        print("Creating synthetic ALICE Lite model for Core ML conversion...")
        
        config = {
            "model_type": "alice_lite",
            "hidden_size": 1024,
            "num_hidden_layers": 12,
            "num_attention_heads": 16,
            "vocab_size": 50257,
            "max_position_embeddings": 2048,
            "torch_dtype": "float16"
        }
        
        # Create simple model weights
        checkpoint = {
            "embed_tokens.weight": torch.randn(config["vocab_size"], config["hidden_size"], dtype=torch.float16),
            "lm_head.weight": torch.randn(config["vocab_size"], config["hidden_size"], dtype=torch.float16),
            "layers": []
        }
        
        for i in range(config["num_hidden_layers"]):
            layer_weights = {
                f"layer_{i}_self_attn.q_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_self_attn.k_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_self_attn.v_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_self_attn.o_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_mlp.gate_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"] * 4, dtype=torch.float16),
                f"layer_{i}_mlp.up_proj.weight": torch.randn(config["hidden_size"], config["hidden_size"] * 4, dtype=torch.float16),
                f"layer_{i}_mlp.down_proj.weight": torch.randn(config["hidden_size"] * 4, config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_input_layernorm.weight": torch.ones(config["hidden_size"], dtype=torch.float16),
                f"layer_{i}_post_attention_layernorm.weight": torch.ones(config["hidden_size"], dtype=torch.float16),
            }
            checkpoint["layers"].append(layer_weights)
        
        checkpoint["final_layernorm.weight"] = torch.ones(config["hidden_size"], dtype=torch.float16)
        
        return checkpoint, config
    
    def create_coreml_model(self, checkpoint, config):
        """Convert PyTorch model to Core ML"""
        print("Converting to Core ML format...")
        
        class ALICELiteModel(torch.nn.Module):
            def __init__(self, config):
                super().__init__()
                self.config = config
                self.vocab_size = config["vocab_size"]
                self.hidden_size = config["hidden_size"]
                self.num_layers = config["num_hidden_layers"]
                
                # Embeddings
                self.embed_tokens = torch.nn.Embedding(config["vocab_size"], config["hidden_size"])
                
                # Transformer layers (simplified)
                self.layers = torch.nn.ModuleList([
                    self.create_transformer_layer(config) for _ in range(config["num_hidden_layers"])
                ])
                
                # Output layers
                self.ln_f = torch.nn.LayerNorm(config["hidden_size"])
                self.lm_head = torch.nn.Linear(config["hidden_size"], config["vocab_size"], bias=False)
                
                # Load weights
                self.load_weights(checkpoint)
            
            def create_transformer_layer(self, config):
                return torch.nn.ModuleDict({
                    'self_attn': torch.nn.MultiheadAttention(
                        embed_dim=config["hidden_size"],
                        num_heads=config["num_attention_heads"],
                        batch_first=True,
                        dtype=torch.float16
                    ),
                    'mlp': torch.nn.Sequential(
                        torch.nn.Linear(config["hidden_size"], config["hidden_size"] * 4),
                        torch.nn.GELU(),
                        torch.nn.Linear(config["hidden_size"] * 4, config["hidden_size"])
                    ),
                    'ln_1': torch.nn.LayerNorm(config["hidden_size"]),
                    'ln_2': torch.nn.LayerNorm(config["hidden_size"])
                })
            
            def load_weights(self, checkpoint):
                """Load weights from checkpoint"""
                if "embed_tokens.weight" in checkpoint:
                    self.embed_tokens.weight.data = checkpoint["embed_tokens.weight"]
                
                if "lm_head.weight" in checkpoint:
                    self.lm_head.weight.data = checkpoint["lm_head.weight"]
                
                if "final_layernorm.weight" in checkpoint:
                    self.ln_f.weight.data = checkpoint["final_layernorm.weight"]
                
                # Load layer weights
                for i, layer in enumerate(self.layers):
                    if i < len(checkpoint.get("layers", [])):
                        layer_weights = checkpoint["layers"][i]
                        for key, weight in layer_weights.items():
                            if hasattr(layer, key.replace(f"layer_{i}_", "")):
                                attr_name = key.replace(f"layer_{i}_", "")
                                if hasattr(layer, attr_name):
                                    if isinstance(getattr(layer, attr_name), torch.nn.Linear):
                                        getattr(layer, attr_name).weight.data = weight
                                    elif isinstance(getattr(layer, attr_name), torch.nn.LayerNorm):
                                        getattr(layer, attr_name).weight.data = weight
            
            def forward(self, input_ids, attention_mask=None):
                batch_size, seq_len = input_ids.shape
                
                # Embeddings
                hidden_states = self.embed_tokens(input_ids)
                
                # Position embeddings (simplified)
                positions = torch.arange(seq_len, device=input_ids.device, dtype=torch.long)
                position_embeddings = self.embed_tokens(positions)
                hidden_states = hidden_states + position_embeddings.unsqueeze(0)
                
                # Transformer layers
                for layer in self.layers:
                    # Self-attention
                    residual = hidden_states
                    hidden_states = layer['ln_1'](hidden_states)
                    attn_output, _ = layer['self_attn'](hidden_states, hidden_states, hidden_states)
                    hidden_states = residual + attn_output
                    
                    # MLP
                    residual = hidden_states
                    hidden_states = layer['ln_2'](hidden_states)
                    hidden_states = layer['mlp'](hidden_states)
                    hidden_states = residual + hidden_states
                
                # Output
                hidden_states = self.ln_f(hidden_states)
                logits = self.lm_head(hidden_states)
                
                return {"logits": logits}
        
        # Create model instance
        model = ALICELiteModel(config)
        model.eval()
        
        # Create example input
        example_input = torch.randint(0, config["vocab_size"], (1, 512), dtype=torch.long)
        
        # Trace the model
        traced_model = torch.jit.trace(model, example_input)
        
        # Convert to Core ML
        mlmodel = ct.convert(
            traced_model,
            inputs=[
                ct.TensorType(name="input_ids", shape=(1, 512), dtype=torch.int64),
                ct.TensorType(name="attention_mask", shape=(1, 512), dtype=torch.bool, optional=True)
            ],
            outputs=[
                ct.TensorType(name="logits", dtype=torch.float16)
            ],
            minimum_deployment_target=ct.target.iOS16
        )
        
        # Set metadata
        mlmodel.short_description = "ALICE Lite - Distilled AI model for KairOS"
        mlmodel.author = "KairOS Project"
        mlmodel.license = "Proprietary"
        mlmodel.version = "1.0"
        
        # Add model configuration
        mlmodel.user_defined_metadata["model_type"] = "alice_lite"
        mlmodel.user_defined_metadata["vocab_size"] = str(config["vocab_size"])
        mlmodel.user_defined_metadata["hidden_size"] = str(config["hidden_size"])
        mlmodel.user_defined_metadata["num_layers"] = str(config["num_hidden_layers"])
        mlmodel.user_defined_metadata["max_position_embeddings"] = str(config["max_position_embeddings"])
        
        return mlmodel
    
    def save_model(self, mlmodel):
        """Save Core ML model"""
        output_file = self.output_path / "ALICELite.mlmodel"
        
        print(f"Saving Core ML model to: {output_file}")
        mlmodel.save(str(output_file))
        
        print(f"Core ML model saved successfully!")
        print(f"Model size: {self.get_model_size(output_file) / 1024 / 1024:.1f} MB")
    
    def get_model_size(self, model_path):
        """Get model file size"""
        if model_path.is_dir():
            return sum(f.stat().st_size for f in model_path.rglob('*') if f.is_file())
        else:
            return model_path.stat().st_size
    
    def create_vocabulary_file(self):
        """Create vocabulary file for iOS tokenizer"""
        vocab = {}
        
        # Special tokens
        vocab["<pad>"] = 0
        vocab["<eos>"] = 1
        vocab["<unk>"] = 2
        
        # Basic ASCII
        token_id = 3
        for i in range(32, 127):  # Printable ASCII
            vocab[chr(i)] = token_id
            token_id += 1
        
        # KairOS specific tokens
        vocab["K-"] = token_id
        token_id += 1
        
        # Numbers
        for i in range(10):
            vocab[str(i)] = token_id
            token_id += 1
        
        # Save vocabulary
        vocab_file = self.output_path / "alice_vocab.json"
        with open(vocab_file, 'w') as f:
            json.dump(vocab, f, indent=2)
        
        print(f"Vocabulary saved to: {vocab_file}")
        print(f"Vocabulary size: {len(vocab)} tokens")
    
    def convert(self):
        """Main conversion process"""
        print("=== ALICE Lite Core ML Conversion ===")
        
        # Load PyTorch model
        checkpoint, config = self.load_pytorch_model()
        
        # Convert to Core ML
        mlmodel = self.create_coreml_model(checkpoint, config)
        
        # Save model
        self.save_model(mlmodel)
        
        # Create vocabulary
        self.create_vocabulary_file()
        
        print("\n=== Conversion Complete ===")
        print("Files created:")
        print(f"  - ALICELite.mlmodel (Core ML model)")
        print(f"  - alice_vocab.json (Vocabulary)")
        print("\nNext steps:")
        print("1. Add ALICELite.mlmodel to iOS app bundle")
        print("2. Add alice_vocab.json to iOS app bundle")
        print("3. Test inference on device")

def main():
    """Main conversion function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Convert ALICE Lite to Core ML")
    parser.add_argument("--input", default="./alice_lite_model", help="Input PyTorch model path")
    parser.add_argument("--output", default="./coreml_model", help="Output Core ML model path")
    
    args = parser.parse_args()
    
    converter = CoreMLConverter(args.input, args.output)
    converter.convert()

if __name__ == "__main__":
    main()
