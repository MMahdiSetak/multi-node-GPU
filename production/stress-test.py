import torch
print(torch.cuda.is_available())  # Should return True
print(torch.cuda.current_device())  # Current device index
print(torch.cuda.device_count())  # Number of GPUs
print(torch.cuda.get_device_name(torch.cuda.current_device()))  # Name of the GPU


import torch
import torchvision.models as models
from torchvision.transforms import ToTensor
from PIL import Image
import time

def stress_test_large_model():
    # Check if CUDA is available
    if torch.cuda.is_available():
        device = torch.device("cuda")
        print("Using GPU: CUDA")
    else:
        device = torch.device("cpu")
        print("CUDA not available. Using CPU.")

    # Load a large pre-trained model (e.g., ResNet50)
    print("Loading ResNet50 model...")
    model = models.resnet50(weights=None)
    model = model.to(device)
    model.eval()  # Set model to evaluation mode

    # Create a large dummy input tensor (e.g., simulating a 4K image)
    print("Creating a large dummy input tensor...")
    dummy_input = torch.rand(1, 3, 3840, 2160).to(device)  # 4K resolution input

    # Perform inference as a stress test
    print("Running inference...")
    start_time = time.time()
    num_iterations = 2000  # Run multiple iterations to sustain load

    with torch.no_grad():
        for _ in range(num_iterations):
            output = model(dummy_input)
    
    end_time = time.time()

    # Print results
    print(f"Inference completed in {end_time - start_time:.4f} seconds")
    print(f"Output shape: {output.shape}")

if __name__ == "__main__":
    stress_test_large_model()
