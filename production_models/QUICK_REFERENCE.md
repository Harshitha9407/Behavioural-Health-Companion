# Quick Reference Card - AI/ML Models

## 🚀 **30-Second Setup**

```bash
# 1. Copy models
cp -r production_models/ /your/backend/path/

# 2. Install dependencies  
pip install scikit-learn joblib numpy pandas

# 3. Test models
python -c "from model_persistence import *; print('✅ Ready!')"
```

---

## ⚡ **Essential Code Snippets**

### **Basic Prediction**
```python
from model_persistence import ModelPersistenceManager, ModelInferencePipeline
import numpy as np

# Initialize
manager = ModelPersistenceManager(base_path="production_models")
pipeline = ModelInferencePipeline(manager)

# Predict emotion
model_id = pipeline.load_model_for_inference("emotional_state_classifier")
input_data = np.array([[0.5, 0.3, 0.2, 0.4, 0.6, 75.0, 0.5, 32.5, 0.7, 0.8, 14, 3]])
result = pipeline.predict(model_id, input_data)

# Get result
emotion_classes = ['Happy', 'Sad', 'Anxious', 'Calm', 'Angry']
predicted_emotion = emotion_classes[result['prediction'][0]]
confidence = max(result['probabilities'][0])
```

### **Complete Analysis Function**
```python
def analyze_user_state(eeg_data, physio_data, behavior_data):
    manager = ModelPersistenceManager(base_path="production_models")
    pipeline = ModelInferencePipeline(manager)
    
    # Prepare input (12 features for emotional models)
    input_features = np.array([[
        eeg_data['alpha'], eeg_data['beta'], eeg_data['gamma'], 
        eeg_data['theta'], eeg_data['delta'],
        physio_data['heart_rate'], physio_data['gsr'], physio_data['skin_temp'],
        behavior_data['activity_level'], behavior_data['sleep_quality'],
        behavior_data['hour_of_day'], behavior_data['day_of_week']
    ]])
    
    # Get predictions
    emotion_model = pipeline.load_model_for_inference("emotional_state_classifier")
    stress_model = pipeline.load_model_for_inference("stress_level_classifier")
    mood_model = pipeline.load_model_for_inference("mood_score_regressor")
    
    emotion_result = pipeline.predict(emotion_model, input_features)
    stress_result = pipeline.predict(stress_model, input_features)
    mood_result = pipeline.predict(mood_model, input_features)
    
    # Interpret results
    emotions = ['Happy', 'Sad', 'Anxious', 'Calm', 'Angry']
    stress_levels = ['Low', 'Medium', 'High']
    
    return {
        'emotion': emotions[emotion_result['prediction'][0]],
        'emotion_confidence': max(emotion_result['probabilities'][0]),
        'stress': stress_levels[stress_result['prediction'][0]], 
        'stress_confidence': max(stress_result['probabilities'][0]),
        'mood_score': float(mood_result['prediction'][0]),
        'timestamp': emotion_result['timestamp']
    }
```

---

## 📊 **Model Quick Reference**

| Model Name | Input Features | Output | Use Case |
|------------|----------------|--------|----------|
| `emotional_state_classifier` | 12 | 5 classes + probs | Emotion detection |
| `stress_level_classifier` | 12 | 3 classes + probs | Stress assessment |
| `mood_score_regressor` | 12 | Score 0-1 | Mood rating |
| `user_normal_range_predictor` | 11 | Score 0-1 | Personal baselines |
| `user_anomaly_detector` | 11 | Binary + probs | Anomaly detection |

---

## 📥 **Input Data Templates**

### **Emotional State Input (12 features)**
```python
emotional_input = np.array([[
    0.5,   # eeg_alpha (0-1)
    0.3,   # eeg_beta (0-1)  
    0.2,   # eeg_gamma (0-1)
    0.4,   # eeg_theta (0-1)
    0.6,   # eeg_delta (0-1)
    75.0,  # heart_rate (40-200 BPM)
    0.5,   # gsr (0-1)
    32.5,  # skin_temp (25-40°C)
    0.7,   # activity_level (0-1)
    0.8,   # sleep_quality (0-1)
    14,    # hour_of_day (0-23)
    3      # day_of_week (0-6)
]])
```

### **User Baseline Input (11 features)**
```python
user_input = np.array([[
    5,     # user_id
    35,    # age (18-80)
    1,     # gender (0=F, 1=M)
    72.0,  # heart_rate (40-200)
    0.45,  # gsr (0-1)
    32.2,  # skin_temp (25-40)
    0.5,   # eeg_alpha (0-1)
    0.3,   # eeg_beta (0-1)
    0.2,   # eeg_gamma (0-1)
    15,    # time_of_day (0-23)
    2      # activity_type (0-4)
]])
```

---

## 🎯 **Output Interpretation**

### **Emotional State Classifier**
```python
# result['prediction'][0] values:
# 0 = Happy, 1 = Sad, 2 = Anxious, 3 = Calm, 4 = Angry
# result['probabilities'][0] = [prob_happy, prob_sad, prob_anxious, prob_calm, prob_angry]
```

### **Stress Level Classifier**  
```python
# result['prediction'][0] values:
# 0 = Low Stress, 1 = Medium Stress, 2 = High Stress
# result['probabilities'][0] = [prob_low, prob_medium, prob_high]
```

### **Mood Score Regressor**
```python
# result['prediction'][0] = float between 0.0-1.0
# 0.0-0.3 = Poor mood, 0.3-0.6 = Fair mood, 0.6-0.8 = Good mood, 0.8-1.0 = Excellent mood
```

### **User Anomaly Detector**
```python
# result['prediction'][0] values:
# 0 = Normal, 1 = Anomaly
# result['probabilities'][0] = [prob_normal, prob_anomaly]
```

---

## ⚠️ **Common Errors & Fixes**

| Error | Cause | Fix |
|-------|-------|-----|
| `Model not found` | Missing model files | Check `production_models/` directory |
| `Expected 12 features, got X` | Wrong input size | Use correct input template |
| `Can't load model` | Missing dependencies | `pip install scikit-learn joblib` |
| `Permission denied` | File permissions | `chmod 755 production_models/` |

---

## 🔧 **Debugging Commands**

```python
# List available models
manager = ModelPersistenceManager(base_path="production_models")
print(list(manager.list_models().keys()))

# Check model info
info = manager.get_model_info("emotional_state_classifier_v1.0_...")
print(info['metadata'])

# Test prediction with debug
try:
    result = pipeline.predict(model_id, input_data)
    print(f"✅ Success: {result}")
except Exception as e:
    print(f"❌ Error: {e}")
```

---

## 📞 **Need Help?**

1. **Check model registry**: `cat production_models/model_registry.json`
2. **Run test suite**: `python test_production_models.py`
3. **Validate input**: Use input validation functions in main guide
4. **Check logs**: Enable debug logging for detailed error info

---

## 🎉 **Ready to Deploy!**

✅ **8 production-ready models**  
✅ **Comprehensive error handling**  
✅ **Performance optimized**  
✅ **Full documentation**  

**Your AI/ML backend integration is ready to go!**