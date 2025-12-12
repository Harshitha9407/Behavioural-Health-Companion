"""
Example Integration Script for Backend Engineers

This script demonstrates how to integrate the AI/ML models into your backend system.
Copy and modify this code for your specific use case.
"""

import numpy as np
import json
from datetime import datetime
from typing import Dict, List, Any, Optional
import sys
import os

# Add the model persistence module to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from model_persistence import ModelPersistenceManager, ModelInferencePipeline
except ImportError:
    print("❌ Error: model_persistence module not found")
    print("Please ensure model_persistence.py is in the same directory")
    sys.exit(1)


class MLModelService:
    """
    Production-ready ML Model Service for Backend Integration
    
    This class provides a clean interface for all AI/ML model operations
    with error handling, caching, and performance optimization.
    """
    
    def __init__(self, models_path: str = "production_models"):
        """
        Initialize the ML Model Service
        
        Args:
            models_path: Path to the production models directory
        """
        self.models_path = models_path
        self.manager = ModelPersistenceManager(base_path=models_path)
        self.pipeline = ModelInferencePipeline(self.manager)
        self.loaded_models = {}
        
        # Preload commonly used models for better performance
        self._preload_models()
    
    def _preload_models(self):
        """Preload frequently used models to improve response time"""
        common_models = [
            "emotional_state_classifier",
            "stress_level_classifier", 
            "mood_score_regressor",
            "user_anomaly_detector"
        ]
        
        print("🔄 Preloading models...")
        for model_name in common_models:
            try:
                model_id = self.pipeline.load_model_for_inference(model_name)
                self.loaded_models[model_name] = model_id
                print(f"✅ Preloaded: {model_name}")
            except Exception as e:
                print(f"⚠️  Failed to preload {model_name}: {e}")
        
        print(f"🚀 Service ready with {len(self.loaded_models)} preloaded models")
    
    def analyze_emotional_state(self, 
                              eeg_data: Dict[str, float],
                              physiological_data: Dict[str, float], 
                              behavioral_data: Dict[str, int]) -> Dict[str, Any]:
        """
        Complete emotional state analysis
        
        Args:
            eeg_data: {'alpha': float, 'beta': float, 'gamma': float, 'theta': float, 'delta': float}
            physiological_data: {'heart_rate': float, 'gsr': float, 'skin_temp': float}
            behavioral_data: {'activity_level': float, 'sleep_quality': float, 'hour_of_day': int, 'day_of_week': int}
        
        Returns:
            Dict with emotional analysis results
        """
        try:
            # Validate input data
            self._validate_emotional_input(eeg_data, physiological_data, behavioral_data)
            
            # Prepare input features (12 features)
            input_features = np.array([[
                eeg_data['alpha'], eeg_data['beta'], eeg_data['gamma'], 
                eeg_data['theta'], eeg_data['delta'],
                physiological_data['heart_rate'], physiological_data['gsr'], 
                physiological_data['skin_temp'],
                behavioral_data['activity_level'], behavioral_data['sleep_quality'],
                behavioral_data['hour_of_day'], behavioral_data['day_of_week']
            ]])
            
            # Get model predictions
            emotion_result = self._predict_with_model("emotional_state_classifier", input_features)
            stress_result = self._predict_with_model("stress_level_classifier", input_features)
            mood_result = self._predict_with_model("mood_score_regressor", input_features)
            
            # Interpret results
            emotion_classes = ['Happy', 'Sad', 'Anxious', 'Calm', 'Angry']
            stress_classes = ['Low', 'Medium', 'High']
            
            emotion_idx = emotion_result['prediction'][0]
            stress_idx = stress_result['prediction'][0]
            mood_score = float(mood_result['prediction'][0])
            
            return {
                'success': True,
                'data': {
                    'emotional_state': {
                        'prediction': emotion_classes[emotion_idx],
                        'confidence': float(max(emotion_result.get('probabilities', [[0]])[0])),
                        'probabilities': {
                            emotion_classes[i]: float(prob) 
                            for i, prob in enumerate(emotion_result.get('probabilities', [[0]*5])[0])
                        }
                    },
                    'stress_level': {
                        'prediction': stress_classes[stress_idx],
                        'confidence': float(max(stress_result.get('probabilities', [[0]])[0])),
                        'probabilities': {
                            stress_classes[i]: float(prob)
                            for i, prob in enumerate(stress_result.get('probabilities', [[0]*3])[0])
                        }
                    },
                    'mood_score': {
                        'score': mood_score,
                        'interpretation': self._interpret_mood_score(mood_score)
                    },
                    'timestamp': datetime.now().isoformat(),
                    'model_versions': {
                        'emotion_model': emotion_result.get('model_id', 'unknown'),
                        'stress_model': stress_result.get('model_id', 'unknown'),
                        'mood_model': mood_result.get('model_id', 'unknown')
                    }
                },
                'error': None
            }
            
        except Exception as e:
            return {
                'success': False,
                'data': None,
                'error': str(e)
            }
    
    def analyze_user_baseline(self,
                            user_id: int,
                            user_profile: Dict[str, Any],
                            current_measurements: Dict[str, float]) -> Dict[str, Any]:
        """
        Analyze user-specific baselines and detect anomalies
        
        Args:
            user_id: User identifier
            user_profile: {'age': int, 'gender': int}  # gender: 0=Female, 1=Male
            current_measurements: Physiological and EEG measurements
        
        Returns:
            Dict with user baseline analysis results
        """
        try:
            # Validate input data
            self._validate_user_input(user_id, user_profile, current_measurements)
            
            # Prepare input features (11 features)
            input_features = np.array([[
                user_id,
                user_profile['age'], user_profile['gender'],
                current_measurements['heart_rate'], current_measurements['gsr'], 
                current_measurements['skin_temp'],
                current_measurements['eeg_alpha'], current_measurements['eeg_beta'], 
                current_measurements['eeg_gamma'],
                current_measurements['time_of_day'], current_measurements['activity_type']
            ]])
            
            # Get predictions
            normal_result = self._predict_with_model("user_normal_range_predictor", input_features)
            anomaly_result = self._predict_with_model("user_anomaly_detector", input_features)
            baseline_result = self._predict_with_model("personalized_baseline_predictor", input_features)
            
            normal_score = float(normal_result['prediction'][0])
            is_anomaly = bool(anomaly_result['prediction'][0])
            baseline_score = float(baseline_result['prediction'][0])
            
            return {
                'success': True,
                'data': {
                    'user_id': user_id,
                    'normal_range_analysis': {
                        'score': normal_score,
                        'is_normal': normal_score < 0.3,  # Threshold for normality
                        'interpretation': self._interpret_normal_score(normal_score)
                    },
                    'anomaly_detection': {
                        'is_anomaly': is_anomaly,
                        'confidence': float(max(anomaly_result.get('probabilities', [[0]])[0])),
                        'risk_level': 'High' if is_anomaly else 'Low',
                        'probabilities': {
                            'normal': float(anomaly_result.get('probabilities', [[1, 0]])[0][0]),
                            'anomaly': float(anomaly_result.get('probabilities', [[0, 1]])[0][1])
                        }
                    },
                    'personalized_baseline': {
                        'score': baseline_score,
                        'interpretation': self._interpret_baseline_score(baseline_score)
                    },
                    'timestamp': datetime.now().isoformat(),
                    'model_versions': {
                        'normal_range_model': normal_result.get('model_id', 'unknown'),
                        'anomaly_model': anomaly_result.get('model_id', 'unknown'),
                        'baseline_model': baseline_result.get('model_id', 'unknown')
                    }
                },
                'error': None
            }
            
        except Exception as e:
            return {
                'success': False,
                'data': None,
                'error': str(e)
            }
    
    def batch_analyze_emotional_state(self, batch_data: List[Dict]) -> List[Dict[str, Any]]:
        """
        Process multiple emotional state analyses in batch for better performance
        
        Args:
            batch_data: List of dictionaries with eeg_data, physiological_data, behavioral_data
        
        Returns:
            List of analysis results
        """
        results = []
        for data in batch_data:
            result = self.analyze_emotional_state(
                data['eeg_data'],
                data['physiological_data'], 
                data['behavioral_data']
            )
            results.append(result)
        
        return results
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about available models"""
        try:
            models = self.manager.list_models()
            
            model_info = {}
            for model_name, versions in models.items():
                if versions:  # Check if versions list is not empty
                    latest_version = max(versions, key=lambda x: x['training_date'])
                    model_info[model_name] = {
                        'available': True,
                        'version': latest_version['version'],
                        'training_date': latest_version['training_date'],
                        'performance_metrics': latest_version['performance_metrics'],
                        'preloaded': model_name in self.loaded_models
                    }
            
            return {
                'success': True,
                'data': {
                    'total_models': len(model_info),
                    'preloaded_models': len(self.loaded_models),
                    'models': model_info
                },
                'error': None
            }
            
        except Exception as e:
            return {
                'success': False,
                'data': None,
                'error': str(e)
            }
    
    def _predict_with_model(self, model_name: str, input_data: np.ndarray) -> Dict[str, Any]:
        """Internal method to make predictions with error handling"""
        if model_name in self.loaded_models:
            model_id = self.loaded_models[model_name]
        else:
            model_id = self.pipeline.load_model_for_inference(model_name)
        
        return self.pipeline.predict(model_id, input_data)
    
    def _validate_emotional_input(self, eeg_data, physiological_data, behavioral_data):
        """Validate emotional state input data"""
        required_eeg = ['alpha', 'beta', 'gamma', 'theta', 'delta']
        required_physio = ['heart_rate', 'gsr', 'skin_temp']
        required_behavior = ['activity_level', 'sleep_quality', 'hour_of_day', 'day_of_week']
        
        for key in required_eeg:
            if key not in eeg_data:
                raise ValueError(f"Missing EEG data: {key}")
            if not (0 <= eeg_data[key] <= 1):
                raise ValueError(f"EEG {key} must be between 0 and 1")
        
        for key in required_physio:
            if key not in physiological_data:
                raise ValueError(f"Missing physiological data: {key}")
        
        if not (40 <= physiological_data['heart_rate'] <= 200):
            raise ValueError("Heart rate must be between 40 and 200 BPM")
        
        for key in required_behavior:
            if key not in behavioral_data:
                raise ValueError(f"Missing behavioral data: {key}")
        
        if not (0 <= behavioral_data['hour_of_day'] <= 23):
            raise ValueError("Hour of day must be between 0 and 23")
    
    def _validate_user_input(self, user_id, user_profile, current_measurements):
        """Validate user baseline input data"""
        if not isinstance(user_id, int) or user_id < 0:
            raise ValueError("User ID must be a non-negative integer")
        
        if 'age' not in user_profile or not (18 <= user_profile['age'] <= 80):
            raise ValueError("Age must be between 18 and 80")
        
        if 'gender' not in user_profile or user_profile['gender'] not in [0, 1]:
            raise ValueError("Gender must be 0 (Female) or 1 (Male)")
        
        required_measurements = [
            'heart_rate', 'gsr', 'skin_temp', 'eeg_alpha', 'eeg_beta', 
            'eeg_gamma', 'time_of_day', 'activity_type'
        ]
        
        for key in required_measurements:
            if key not in current_measurements:
                raise ValueError(f"Missing measurement: {key}")
    
    def _interpret_mood_score(self, score: float) -> str:
        """Interpret mood score"""
        if score >= 0.8:
            return "Excellent"
        elif score >= 0.6:
            return "Good"
        elif score >= 0.4:
            return "Fair"
        else:
            return "Poor"
    
    def _interpret_normal_score(self, score: float) -> str:
        """Interpret normal range score"""
        if score < 0.2:
            return "Well within normal range"
        elif score < 0.3:
            return "Within normal range"
        elif score < 0.5:
            return "Slightly outside normal range"
        else:
            return "Significantly outside normal range"
    
    def _interpret_baseline_score(self, score: float) -> str:
        """Interpret baseline score"""
        if score > 0:
            return "Above personal baseline"
        elif score < -0.5:
            return "Significantly below personal baseline"
        else:
            return "Near personal baseline"


# Example usage and testing
def main():
    """Example usage of the ML Model Service"""
    print("🚀 AI/ML Model Service - Example Integration")
    print("=" * 50)
    
    # Initialize service
    try:
        service = MLModelService(models_path=".")  # Current directory
        print("✅ Service initialized successfully")
    except Exception as e:
        print(f"❌ Failed to initialize service: {e}")
        return
    
    # Example 1: Emotional State Analysis
    print("\n📊 Example 1: Emotional State Analysis")
    print("-" * 40)
    
    eeg_data = {
        'alpha': 0.5, 'beta': 0.3, 'gamma': 0.2, 'theta': 0.4, 'delta': 0.6
    }
    physiological_data = {
        'heart_rate': 75.0, 'gsr': 0.5, 'skin_temp': 32.5
    }
    behavioral_data = {
        'activity_level': 0.7, 'sleep_quality': 0.8, 'hour_of_day': 14, 'day_of_week': 3
    }
    
    emotion_result = service.analyze_emotional_state(eeg_data, physiological_data, behavioral_data)
    
    if emotion_result['success']:
        data = emotion_result['data']
        print(f"✅ Emotional State: {data['emotional_state']['prediction']}")
        print(f"   Confidence: {data['emotional_state']['confidence']:.2f}")
        print(f"✅ Stress Level: {data['stress_level']['prediction']}")
        print(f"   Confidence: {data['stress_level']['confidence']:.2f}")
        print(f"✅ Mood Score: {data['mood_score']['score']:.3f} ({data['mood_score']['interpretation']})")
    else:
        print(f"❌ Error: {emotion_result['error']}")
    
    # Example 2: User Baseline Analysis
    print("\n👤 Example 2: User Baseline Analysis")
    print("-" * 40)
    
    user_profile = {'age': 35, 'gender': 1}  # 35-year-old male
    current_measurements = {
        'heart_rate': 72.0, 'gsr': 0.45, 'skin_temp': 32.2,
        'eeg_alpha': 0.5, 'eeg_beta': 0.3, 'eeg_gamma': 0.2,
        'time_of_day': 15, 'activity_type': 2
    }
    
    baseline_result = service.analyze_user_baseline(5, user_profile, current_measurements)
    
    if baseline_result['success']:
        data = baseline_result['data']
        print(f"✅ Normal Range: {data['normal_range_analysis']['interpretation']}")
        print(f"   Score: {data['normal_range_analysis']['score']:.3f}")
        print(f"✅ Anomaly Detection: {data['anomaly_detection']['risk_level']} Risk")
        print(f"   Confidence: {data['anomaly_detection']['confidence']:.2f}")
    else:
        print(f"❌ Error: {baseline_result['error']}")
    
    # Example 3: Model Information
    print("\n🔧 Example 3: Model Information")
    print("-" * 40)
    
    model_info = service.get_model_info()
    if model_info['success']:
        data = model_info['data']
        print(f"✅ Total Models: {data['total_models']}")
        print(f"✅ Preloaded Models: {data['preloaded_models']}")
        print("\nAvailable Models:")
        for model_name, info in data['models'].items():
            status = "🟢 Preloaded" if info['preloaded'] else "🟡 Available"
            print(f"  {status} {model_name} (v{info['version']})")
    else:
        print(f"❌ Error: {model_info['error']}")
    
    print("\n🎉 Integration example completed successfully!")
    print("\n💡 Next Steps:")
    print("1. Copy this code to your backend project")
    print("2. Modify the MLModelService class for your needs")
    print("3. Integrate with your REST API or service layer")
    print("4. Add proper logging and monitoring")
    print("5. Deploy to production!")


if __name__ == "__main__":
    main()