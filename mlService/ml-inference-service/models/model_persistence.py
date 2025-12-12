"""
Model Persistence and Loading System

This module provides comprehensive model persistence, versioning, and loading capabilities
for the AI/ML Analytics Engine. It supports both traditional ML models (scikit-learn)
and deep learning models (PyTorch/TensorFlow) with GPU support.

Requirements addressed:
- 6.5: Model persistence and loading for production use
- 2.3: Model versioning and metadata management
"""

import os
import json
import pickle
import joblib
import shutil
import hashlib
import datetime
from typing import Dict, Any, Optional, List, Union, Tuple
from pathlib import Path
import logging
from dataclasses import dataclass, asdict
import torch
import numpy as np
from sklearn.base import BaseEstimator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class ModelMetadata:
    """Model metadata structure for tracking model information"""
    model_id: str
    model_name: str
    model_type: str  # 'sklearn', 'pytorch', 'tensorflow', 'custom'
    version: str
    training_date: str
    performance_metrics: Dict[str, float]
    parameters: Dict[str, Any]
    data_hash: str
    file_path: str
    file_size: int
    gpu_compatible: bool = False
    framework_version: str = ""
    python_version: str = ""
    dependencies: Dict[str, str] = None
    
    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = {}


class ModelPersistenceManager:
    """
    Comprehensive model persistence and loading system with versioning support
    """
    
    def __init__(self, base_path: str = "models", backup_path: str = "models/backups"):
        """
        Initialize the model persistence manager
        
        Args:
            base_path: Base directory for storing models
            backup_path: Directory for model backups
        """
        self.base_path = Path(base_path)
        self.backup_path = Path(backup_path)
        self.registry_file = self.base_path / "model_registry.json"
        
        # Create directories if they don't exist
        self.base_path.mkdir(parents=True, exist_ok=True)
        self.backup_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize or load model registry
        self.registry = self._load_registry()
        
        logger.info(f"ModelPersistenceManager initialized with base_path: {self.base_path}")
    
    def _load_registry(self) -> Dict[str, Dict]:
        """Load the model registry from disk"""
        if self.registry_file.exists():
            try:
                with open(self.registry_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Error loading model registry: {e}")
                return {}
        return {}
    
    def _save_registry(self):
        """Save the model registry to disk"""
        try:
            with open(self.registry_file, 'w') as f:
                json.dump(self.registry, f, indent=2, default=str)
            logger.info("Model registry saved successfully")
        except Exception as e:
            logger.error(f"Error saving model registry: {e}")
            raise
    
    def _generate_model_id(self, model_name: str, version: str) -> str:
        """Generate unique model ID"""
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"{model_name}_v{version}_{timestamp}"
    
    def _calculate_data_hash(self, data: Any) -> str:
        """Calculate hash of training data for reproducibility tracking"""
        if hasattr(data, 'values'):  # pandas DataFrame
            data_str = str(data.values.tobytes())
        elif isinstance(data, np.ndarray):
            data_str = str(data.tobytes())
        else:
            data_str = str(data)
        
        return hashlib.md5(data_str.encode()).hexdigest()
    
    def _get_framework_versions(self) -> Dict[str, str]:
        """Get current framework versions"""
        versions = {}
        try:
            import sklearn
            versions['sklearn'] = sklearn.__version__
        except ImportError:
            pass
        
        try:
            import torch
            versions['torch'] = torch.__version__
        except ImportError:
            pass
        
        try:
            import tensorflow as tf
            versions['tensorflow'] = tf.__version__
        except ImportError:
            pass
        
        import sys
        versions['python'] = sys.version
        
        return versions
    
    def save_model(self, 
                   model: Any, 
                   model_name: str, 
                   version: str,
                   performance_metrics: Dict[str, float],
                   training_data: Any = None,
                   parameters: Dict[str, Any] = None,
                   model_type: str = None) -> str:
        """
        Save a model with metadata and versioning
        
        Args:
            model: The trained model to save
            model_name: Name of the model
            version: Version string
            performance_metrics: Dictionary of performance metrics
            training_data: Training data for hash calculation
            parameters: Model parameters and hyperparameters
            model_type: Type of model ('sklearn', 'pytorch', 'tensorflow', 'custom')
        
        Returns:
            model_id: Unique identifier for the saved model
        """
        try:
            # Generate model ID
            model_id = self._generate_model_id(model_name, version)
            
            # Determine model type if not provided
            if model_type is None:
                model_type = self._detect_model_type(model)
            
            # Create model directory
            model_dir = self.base_path / model_id
            model_dir.mkdir(exist_ok=True)
            
            # Determine file extension and save method
            if model_type == 'pytorch':
                file_path = model_dir / f"{model_id}.pth"
                torch.save(model, file_path)
                gpu_compatible = next(model.parameters()).is_cuda if hasattr(model, 'parameters') else False
            elif model_type == 'sklearn':
                file_path = model_dir / f"{model_id}.pkl"
                joblib.dump(model, file_path)
                gpu_compatible = False
            else:  # Custom or other types
                file_path = model_dir / f"{model_id}.pkl"
                with open(file_path, 'wb') as f:
                    pickle.dump(model, f)
                gpu_compatible = False
            
            # Calculate file size
            file_size = file_path.stat().st_size
            
            # Calculate data hash if training data provided
            data_hash = self._calculate_data_hash(training_data) if training_data is not None else ""
            
            # Get framework versions
            framework_versions = self._get_framework_versions()
            
            # Create metadata
            metadata = ModelMetadata(
                model_id=model_id,
                model_name=model_name,
                model_type=model_type,
                version=version,
                training_date=datetime.datetime.now().isoformat(),
                performance_metrics=performance_metrics or {},
                parameters=parameters or {},
                data_hash=data_hash,
                file_path=str(file_path),
                file_size=file_size,
                gpu_compatible=gpu_compatible,
                framework_version=framework_versions.get(model_type, ""),
                python_version=framework_versions.get('python', ""),
                dependencies=framework_versions
            )
            
            # Save metadata
            metadata_path = model_dir / f"{model_id}_metadata.json"
            with open(metadata_path, 'w') as f:
                json.dump(asdict(metadata), f, indent=2, default=str)
            
            # Update registry
            if model_name not in self.registry:
                self.registry[model_name] = {}
            
            self.registry[model_name][model_id] = {
                'version': version,
                'training_date': metadata.training_date,
                'performance_metrics': performance_metrics,
                'file_path': str(file_path),
                'metadata_path': str(metadata_path),
                'active': True
            }
            
            # Save registry
            self._save_registry()
            
            logger.info(f"Model saved successfully: {model_id}")
            return model_id
            
        except Exception as e:
            logger.error(f"Error saving model {model_name}: {e}")
            raise
    
    def _detect_model_type(self, model: Any) -> str:
        """Detect the type of model"""
        if hasattr(model, 'state_dict'):  # PyTorch model
            return 'pytorch'
        elif isinstance(model, BaseEstimator):  # Scikit-learn model
            return 'sklearn'
        elif hasattr(model, 'save'):  # TensorFlow/Keras model
            return 'tensorflow'
        else:
            return 'custom'
    
    def load_model(self, model_id: str) -> Tuple[Any, ModelMetadata]:
        """
        Load a model by its ID
        
        Args:
            model_id: Unique model identifier
        
        Returns:
            Tuple of (model, metadata)
        """
        try:
            # Find model in registry
            model_info = None
            model_name = None
            
            for name, models in self.registry.items():
                if model_id in models:
                    model_info = models[model_id]
                    model_name = name
                    break
            
            if model_info is None:
                raise ValueError(f"Model {model_id} not found in registry")
            
            # Load metadata
            metadata_path = Path(model_info['metadata_path'])
            if not metadata_path.exists():
                raise FileNotFoundError(f"Metadata file not found: {metadata_path}")
            
            with open(metadata_path, 'r') as f:
                metadata_dict = json.load(f)
            
            metadata = ModelMetadata(**metadata_dict)
            
            # Load model based on type
            model_path = Path(model_info['file_path'])
            if not model_path.exists():
                raise FileNotFoundError(f"Model file not found: {model_path}")
            
            if metadata.model_type == 'pytorch':
                # Determine device for PyTorch models
                device = torch.device('cuda' if torch.cuda.is_available() and metadata.gpu_compatible else 'cpu')
                # Use weights_only=False for compatibility with custom models
                model = torch.load(model_path, map_location=device, weights_only=False)
            elif metadata.model_type == 'sklearn':
                model = joblib.load(model_path)
            else:  # Custom or other types
                with open(model_path, 'rb') as f:
                    model = pickle.load(f)
            
            logger.info(f"Model loaded successfully: {model_id}")
            return model, metadata
            
        except Exception as e:
            logger.error(f"Error loading model {model_id}: {e}")
            raise
    
    def load_latest_model(self, model_name: str) -> Tuple[Any, ModelMetadata]:
        """
        Load the latest version of a model by name
        
        Args:
            model_name: Name of the model
        
        Returns:
            Tuple of (model, metadata)
        """
        if model_name not in self.registry:
            raise ValueError(f"Model {model_name} not found in registry")
        
        # Find the latest active model
        models = self.registry[model_name]
        active_models = {k: v for k, v in models.items() if v.get('active', True)}
        
        if not active_models:
            raise ValueError(f"No active models found for {model_name}")
        
        # Sort by training date to get the latest
        latest_model_id = max(active_models.keys(), 
                            key=lambda x: active_models[x]['training_date'])
        
        return self.load_model(latest_model_id)
    
    def list_models(self, model_name: str = None) -> Dict[str, List[Dict]]:
        """
        List all models or models for a specific name
        
        Args:
            model_name: Optional model name to filter by
        
        Returns:
            Dictionary of model information
        """
        if model_name:
            if model_name not in self.registry:
                return {model_name: []}
            return {model_name: list(self.registry[model_name].values())}
        
        return {name: list(models.values()) for name, models in self.registry.items()}
    
    def delete_model(self, model_id: str, create_backup: bool = True) -> bool:
        """
        Delete a model and optionally create a backup
        
        Args:
            model_id: Model ID to delete
            create_backup: Whether to create a backup before deletion
        
        Returns:
            True if successful
        """
        try:
            # Find model in registry
            model_info = None
            model_name = None
            
            for name, models in self.registry.items():
                if model_id in models:
                    model_info = models[model_id]
                    model_name = name
                    break
            
            if model_info is None:
                raise ValueError(f"Model {model_id} not found in registry")
            
            # Create backup if requested
            if create_backup:
                self.backup_model(model_id)
            
            # Delete model files
            model_path = Path(model_info['file_path'])
            metadata_path = Path(model_info['metadata_path'])
            
            if model_path.exists():
                model_path.unlink()
            
            if metadata_path.exists():
                metadata_path.unlink()
            
            # Remove model directory if empty
            model_dir = model_path.parent
            if model_dir.exists() and not any(model_dir.iterdir()):
                model_dir.rmdir()
            
            # Remove from registry
            del self.registry[model_name][model_id]
            
            # Remove model name from registry if no models left
            if not self.registry[model_name]:
                del self.registry[model_name]
            
            # Save registry
            self._save_registry()
            
            logger.info(f"Model deleted successfully: {model_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting model {model_id}: {e}")
            raise
    
    def backup_model(self, model_id: str) -> str:
        """
        Create a backup of a model
        
        Args:
            model_id: Model ID to backup
        
        Returns:
            Path to backup directory
        """
        try:
            # Find model in registry
            model_info = None
            
            for name, models in self.registry.items():
                if model_id in models:
                    model_info = models[model_id]
                    break
            
            if model_info is None:
                raise ValueError(f"Model {model_id} not found in registry")
            
            # Create backup directory
            backup_dir = self.backup_path / f"{model_id}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
            backup_dir.mkdir(exist_ok=True)
            
            # Copy model files
            model_path = Path(model_info['file_path'])
            metadata_path = Path(model_info['metadata_path'])
            
            if model_path.exists():
                shutil.copy2(model_path, backup_dir / model_path.name)
            
            if metadata_path.exists():
                shutil.copy2(metadata_path, backup_dir / metadata_path.name)
            
            logger.info(f"Model backup created: {backup_dir}")
            return str(backup_dir)
            
        except Exception as e:
            logger.error(f"Error backing up model {model_id}: {e}")
            raise
    
    def restore_model(self, backup_path: str) -> str:
        """
        Restore a model from backup
        
        Args:
            backup_path: Path to backup directory
        
        Returns:
            Restored model ID
        """
        try:
            backup_dir = Path(backup_path)
            if not backup_dir.exists():
                raise FileNotFoundError(f"Backup directory not found: {backup_path}")
            
            # Find metadata file
            metadata_files = list(backup_dir.glob("*_metadata.json"))
            if not metadata_files:
                raise FileNotFoundError("No metadata file found in backup")
            
            metadata_file = metadata_files[0]
            
            # Load metadata
            with open(metadata_file, 'r') as f:
                metadata_dict = json.load(f)
            
            metadata = ModelMetadata(**metadata_dict)
            original_model_id = metadata.model_id
            
            # Generate new model ID for restoration
            new_model_id = self._generate_model_id(metadata.model_name, f"{metadata.version}_restored")
            
            # Create new model directory
            model_dir = self.base_path / new_model_id
            model_dir.mkdir(exist_ok=True)
            
            # Copy files from backup
            for file_path in backup_dir.iterdir():
                if file_path.is_file():
                    new_file_name = file_path.name.replace(original_model_id, new_model_id)
                    shutil.copy2(file_path, model_dir / new_file_name)
            
            # Update metadata with new paths
            metadata.model_id = new_model_id
            metadata.file_path = str(model_dir / f"{new_model_id}.{Path(metadata.file_path).suffix[1:]}")
            
            # Save updated metadata
            new_metadata_path = model_dir / f"{new_model_id}_metadata.json"
            with open(new_metadata_path, 'w') as f:
                json.dump(asdict(metadata), f, indent=2, default=str)
            
            # Update registry
            if metadata.model_name not in self.registry:
                self.registry[metadata.model_name] = {}
            
            self.registry[metadata.model_name][new_model_id] = {
                'version': f"{metadata.version}_restored",
                'training_date': metadata.training_date,
                'performance_metrics': metadata.performance_metrics,
                'file_path': metadata.file_path,
                'metadata_path': str(new_metadata_path),
                'active': True
            }
            
            # Save registry
            self._save_registry()
            
            logger.info(f"Model restored successfully: {new_model_id}")
            return new_model_id
            
        except Exception as e:
            logger.error(f"Error restoring model from {backup_path}: {e}")
            raise
    
    def get_model_info(self, model_id: str) -> Dict[str, Any]:
        """
        Get detailed information about a model
        
        Args:
            model_id: Model ID
        
        Returns:
            Dictionary with model information
        """
        try:
            # Find model in registry
            model_info = None
            model_name = None
            
            for name, models in self.registry.items():
                if model_id in models:
                    model_info = models[model_id]
                    model_name = name
                    break
            
            if model_info is None:
                raise ValueError(f"Model {model_id} not found in registry")
            
            # Load metadata
            metadata_path = Path(model_info['metadata_path'])
            if metadata_path.exists():
                with open(metadata_path, 'r') as f:
                    metadata = json.load(f)
            else:
                metadata = {}
            
            return {
                'model_id': model_id,
                'model_name': model_name,
                'registry_info': model_info,
                'metadata': metadata
            }
            
        except Exception as e:
            logger.error(f"Error getting model info for {model_id}: {e}")
            raise
    
    def cleanup_old_models(self, model_name: str, keep_versions: int = 5) -> List[str]:
        """
        Clean up old model versions, keeping only the specified number of latest versions
        
        Args:
            model_name: Name of the model
            keep_versions: Number of versions to keep
        
        Returns:
            List of deleted model IDs
        """
        if model_name not in self.registry:
            return []
        
        models = self.registry[model_name]
        active_models = {k: v for k, v in models.items() if v.get('active', True)}
        
        if len(active_models) <= keep_versions:
            return []
        
        # Sort by training date
        sorted_models = sorted(active_models.items(), 
                             key=lambda x: x[1]['training_date'], 
                             reverse=True)
        
        # Keep the latest versions, delete the rest
        models_to_delete = sorted_models[keep_versions:]
        deleted_ids = []
        
        for model_id, _ in models_to_delete:
            try:
                self.delete_model(model_id, create_backup=True)
                deleted_ids.append(model_id)
            except Exception as e:
                logger.error(f"Error deleting old model {model_id}: {e}")
        
        logger.info(f"Cleaned up {len(deleted_ids)} old models for {model_name}")
        return deleted_ids


class ModelInferencePipeline:
    """
    Production-ready model inference pipeline with caching and error handling
    """
    
    def __init__(self, persistence_manager: ModelPersistenceManager):
        """
        Initialize the inference pipeline
        
        Args:
            persistence_manager: Model persistence manager instance
        """
        self.persistence_manager = persistence_manager
        self.loaded_models = {}  # Cache for loaded models
        self.model_metadata = {}  # Cache for model metadata
        
        logger.info("ModelInferencePipeline initialized")
    
    def load_model_for_inference(self, model_name: str, model_id: str = None) -> str:
        """
        Load a model for inference with caching
        
        Args:
            model_name: Name of the model
            model_id: Specific model ID (optional, uses latest if not provided)
        
        Returns:
            Model ID of the loaded model
        """
        try:
            # Use specific model ID or get latest
            if model_id is None:
                model, metadata = self.persistence_manager.load_latest_model(model_name)
                model_id = metadata.model_id
            else:
                model, metadata = self.persistence_manager.load_model(model_id)
            
            # Cache the model and metadata
            self.loaded_models[model_id] = model
            self.model_metadata[model_id] = metadata
            
            logger.info(f"Model loaded for inference: {model_id}")
            return model_id
            
        except Exception as e:
            logger.error(f"Error loading model for inference: {e}")
            raise
    
    def predict(self, model_id: str, input_data: Any, **kwargs) -> Dict[str, Any]:
        """
        Make predictions using a loaded model
        
        Args:
            model_id: Model ID
            input_data: Input data for prediction
            **kwargs: Additional arguments for prediction
        
        Returns:
            Dictionary with prediction results
        """
        try:
            if model_id not in self.loaded_models:
                raise ValueError(f"Model {model_id} not loaded. Call load_model_for_inference first.")
            
            model = self.loaded_models[model_id]
            metadata = self.model_metadata[model_id]
            
            # Make prediction based on model type
            if metadata.model_type == 'pytorch':
                model.eval()
                with torch.no_grad():
                    if isinstance(input_data, np.ndarray):
                        input_tensor = torch.tensor(input_data, dtype=torch.float32)
                        if metadata.gpu_compatible and torch.cuda.is_available():
                            input_tensor = input_tensor.cuda()
                    else:
                        input_tensor = input_data
                    
                    prediction = model(input_tensor)
                    
                    # Convert to numpy for consistent output
                    if hasattr(prediction, 'cpu'):
                        prediction = prediction.cpu().numpy()
                    
            elif metadata.model_type == 'sklearn':
                prediction = model.predict(input_data)
                
                # Get prediction probabilities if available
                if hasattr(model, 'predict_proba'):
                    probabilities = model.predict_proba(input_data)
                else:
                    probabilities = None
                    
            else:  # Custom models
                if hasattr(model, 'predict'):
                    prediction = model.predict(input_data)
                else:
                    raise ValueError(f"Model type {metadata.model_type} does not support prediction")
            
            # Prepare result
            result = {
                'prediction': prediction.tolist() if hasattr(prediction, 'tolist') else prediction,
                'model_id': model_id,
                'model_name': metadata.model_name,
                'model_version': metadata.version,
                'timestamp': datetime.datetime.now().isoformat()
            }
            
            # Add probabilities for sklearn models
            if metadata.model_type == 'sklearn' and 'probabilities' in locals():
                if probabilities is not None:
                    result['probabilities'] = probabilities.tolist()
            
            return result
            
        except Exception as e:
            logger.error(f"Error making prediction with model {model_id}: {e}")
            raise
    
    def batch_predict(self, model_id: str, input_data_batch: List[Any], **kwargs) -> List[Dict[str, Any]]:
        """
        Make batch predictions
        
        Args:
            model_id: Model ID
            input_data_batch: List of input data for batch prediction
            **kwargs: Additional arguments for prediction
        
        Returns:
            List of prediction results
        """
        try:
            results = []
            for input_data in input_data_batch:
                result = self.predict(model_id, input_data, **kwargs)
                results.append(result)
            
            return results
            
        except Exception as e:
            logger.error(f"Error making batch predictions with model {model_id}: {e}")
            raise
    
    def unload_model(self, model_id: str):
        """
        Unload a model from cache to free memory
        
        Args:
            model_id: Model ID to unload
        """
        if model_id in self.loaded_models:
            del self.loaded_models[model_id]
            del self.model_metadata[model_id]
            logger.info(f"Model unloaded from cache: {model_id}")
    
    def get_loaded_models(self) -> List[str]:
        """
        Get list of currently loaded model IDs
        
        Returns:
            List of model IDs
        """
        return list(self.loaded_models.keys())
    
    def clear_cache(self):
        """Clear all cached models"""
        self.loaded_models.clear()
        self.model_metadata.clear()
        logger.info("Model cache cleared")


# Convenience functions for easy usage
def save_model(model: Any, 
               model_name: str, 
               version: str,
               performance_metrics: Dict[str, float],
               base_path: str = "models",
               **kwargs) -> str:
    """
    Convenience function to save a model
    
    Args:
        model: The trained model
        model_name: Name of the model
        version: Version string
        performance_metrics: Performance metrics dictionary
        base_path: Base path for model storage
        **kwargs: Additional arguments for save_model
    
    Returns:
        Model ID
    """
    manager = ModelPersistenceManager(base_path)
    return manager.save_model(model, model_name, version, performance_metrics, **kwargs)


def load_model(model_name: str, 
               model_id: str = None,
               base_path: str = "models") -> Tuple[Any, ModelMetadata]:
    """
    Convenience function to load a model
    
    Args:
        model_name: Name of the model
        model_id: Specific model ID (optional)
        base_path: Base path for model storage
    
    Returns:
        Tuple of (model, metadata)
    """
    manager = ModelPersistenceManager(base_path)
    if model_id:
        return manager.load_model(model_id)
    else:
        return manager.load_latest_model(model_name)