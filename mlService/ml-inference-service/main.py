import os
import json
import re # Import regex for camelCase to snake_case conversion
from datetime import datetime, timezone
from typing import List, Union, Dict, Any, Tuple

import numpy as np
from fastapi import FastAPI, HTTPException, Path

# Assuming these are in a 'models' directory relative to main.py
from models.model_persistence import ModelPersistenceManager, ModelInferencePipeline
from models.model_feature_configs import MODEL_FEATURE_CONFIGS


# --- 1. FastAPI App Initialization ---
app = FastAPI(title="ML Inference Service for Biometric Companion")

# --- 2. Initialize Model Management ---
# Ensure the base_path is correct for where your 'production_models' directory is located
MODEL_MANAGER = ModelPersistenceManager(base_path="./production_models")
INFERENCE_PIPELINE = ModelInferencePipeline(MODEL_MANAGER)


# --- Helper for Case Conversion ---
def camel_to_snake_case(name: str) -> str:
    """Converts a camelCase string to snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

# --- 4. Helper Function to Prepare Input Vector ---
def _prepare_input_vector(model_name: str, raw_features_dict: Dict[str, Any]) -> np.ndarray:
    """
    Prepares the input feature vector for a specific model by selecting and ordering
    features based on predefined lists in MODEL_FEATURE_CONFIGS.
    Handles camelCase to snake_case conversion for incoming feature names.

    Args:
        model_name (str): The name of the model (e.g., "Stress Level Classifier").
        raw_features_dict (Dict[str, Any]): The raw dictionary of features received
                                              from the client (expected to be camelCase keys).

    Returns:
        np.ndarray: A NumPy array containing only the features expected by the model,
                    in the correct order, and reshaped for single-sample inference.

    Raises:
        HTTPException: For various input validation errors.
    """
    expected_feature_names_snake_case = MODEL_FEATURE_CONFIGS.get(model_name)
    if not expected_feature_names_snake_case:
        # Raise 500 if the model config is missing, as it's a server-side configuration error
        raise HTTPException(status_code=500, detail=f"Server configuration error: No feature configuration found for model '{model_name}'. "
                                                    "Please check models/model_feature_configs.py.")

    # Convert all incoming camelCase keys to snake_case for consistent lookup
    processed_features_dict = {camel_to_snake_case(k): v for k, v in raw_features_dict.items()}

    input_vector_values = []
    for feature_name_snake_case in expected_feature_names_snake_case:
        if feature_name_snake_case not in processed_features_dict:
            # Raise 400 if a required feature is missing from the client input
            raise HTTPException(status_code=400, detail=f"Missing required feature '{feature_name_snake_case}' for model '{model_name}'. "
                                                        f"Expected features for this model: {expected_feature_names_snake_case}")

        val = processed_features_dict[feature_name_snake_case]
        
        # Basic type validation and conversion for numerical features
        if isinstance(val, (int, float)):
            input_vector_values.append(val)
        elif isinstance(val, str):
            try:
                input_vector_values.append(float(val))
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Feature '{feature_name_snake_case}' has non-numerical string value '{val}'. "
                                                            f"All expected features must be numerical for model '{model_name}'.")
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported type for feature '{feature_name_snake_case}' with value '{val}' (type: {type(val).__name__}). "
                                                        f"Expected features for model '{model_name}' must be numerical (int/float/numerical string).")

    # Reshape for single sample inference: (1, n_features)
    # This also implicitly checks that the number of gathered features matches the expected count
    # defined in MODEL_FEATURE_CONFIGS. If not, array conversion will likely fail, or the
    # model will complain.
    return np.array(input_vector_values).reshape(1, -1)


# --- 5. The Main Inference Endpoint ---
@app.post("/api/v1/analyze/{model_name}", response_model=Dict[str, Any])
async def perform_inference(
    request_body: Dict[str, Any], # FastAPI parses the entire JSON body into this dictionary
    model_name: str = Path(..., title="The exact name of the ML model to execute")
) -> Dict[str, Any]:
    """
    Performs inference using the specified ML model with the provided input features.
    Expects a flat JSON object where keys are feature names (camelCase from Java DTO)
    and values are feature data. Features are filtered and ordered based on the model's
    configuration in 'models/model_feature_configs.py' (snake_case).
    """
    try:
        # First, prepare the input data using the model's specific feature configuration
        input_data_array = _prepare_input_vector(model_name, request_body)
        
        # Load the model (or retrieve from cache)
        model_id = INFERENCE_PIPELINE.load_model_for_inference(model_name)

        # Perform the actual prediction using the prepared input
        prediction_output = INFERENCE_PIPELINE.predict(model_id, input_data_array)

        # Initialize probabilities to None (which will deserialize to null in Java)
        probabilities_result: Union[List[List[float]], None] = None 

        # Process prediction output to separate prediction and probabilities
        if isinstance(prediction_output, tuple) and len(prediction_output) == 2:
            prediction_result, raw_probabilities = prediction_output
            # Ensure probabilities are always a list of lists if present (e.g., [[0.1, 0.9]])
            if isinstance(raw_probabilities, np.ndarray):
                if raw_probabilities.ndim == 1: # Single-dimension array of probabilities for one sample
                    probabilities_result = [raw_probabilities.tolist()]
                else: # Multi-dimensional (e.g., multiple samples or already a list of lists)
                    probabilities_result = raw_probabilities.tolist()
            elif isinstance(raw_probabilities, list):
                if len(raw_probabilities) > 0 and not isinstance(raw_probabilities[0], list):
                    probabilities_result = [raw_probabilities] # Wrap single list into list of lists
                else:
                    probabilities_result = raw_probabilities
            else: # If it's a scalar probability (e.g., binary classifier 0.9), wrap it
                probabilities_result = [[float(raw_probabilities)]] 
        else:
            prediction_result = prediction_output
            probabilities_result = None # No probabilities returned by the model

        # Ensure prediction_result is always wrapped in a list for Java's List<Object>
        final_prediction_list: List[Any]
        if isinstance(prediction_result, np.ndarray):
            if prediction_result.size == 1:
                final_prediction_list = [prediction_result.item()] # Convert single element array to scalar
            else:
                final_prediction_list = prediction_result.tolist()
        elif not isinstance(prediction_result, list): # If it's a scalar Python value (int, float, str)
            final_prediction_list = [prediction_result] # Wrap scalar into a list
        else: # Already a list
            final_prediction_list = prediction_result


        response_data = {
            "modelId": model_id,
            "modelName": model_name,
            "prediction": final_prediction_list,
            "probabilities": probabilities_result,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "error": None
        }
        
        return response_data
        
    except HTTPException:
        # Re-raise HTTPExceptions directly, as they are already formatted
        raise
    except ValueError as e:
        # Catch value errors that weren't explicitly converted to HTTPException in _prepare_input_vector
        raise HTTPException(status_code=400, detail=f"Invalid input: {e}")
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Model file for '{model_name}' not found or could not be loaded.")
    except Exception as e:
        import traceback
        traceback.print_exc() # Print full traceback to Python console for debugging
        raise HTTPException(status_code=500, detail=f"Internal ML service error during inference for model {model_name}: {e}")

# --- 6. Health Check Endpoint ---
@app.get("/api/v1/health")
async def health_check():
    """
    Basic health check endpoint to confirm the ML service is running.
    """
    return {"status": "ML service is up and running"}

# --- Optional: Run the app directly for development ---
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)