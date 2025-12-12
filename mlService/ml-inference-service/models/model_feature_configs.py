# models/model_feature_configs.py

# This dictionary defines the precise list of features, and their expected order,
# for each machine learning model. The feature names are in 'snake_case' as per your specs.
# The `_prepare_input_vector` function in main.py will handle converting incoming
# 'camelCase' features from the Java client to these 'snake_case' names.

MODEL_FEATURE_CONFIGS = {
    "emotional_state_classifier": [
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "eeg_theta",
        "eeg_delta",
        "heart_rate",
        "gsr",
        "skin_temp",
        "activity_level",
        "sleep_quality",
        "hour_of_day",
        "day_of_week"
    ],
    "stress_level_classifier": [
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "eeg_theta",
        "eeg_delta",
        "heart_rate",
        "gsr",
        "skin_temp",
        "activity_level",
        "sleep_quality",
        "hour_of_day",
        "day_of_week"
    ],
    "mood_score_regressor": [
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "eeg_theta",
        "eeg_delta",
        "heart_rate",
        "gsr",
        "skin_temp",
        "activity_level",
        "sleep_quality",
        "hour_of_day",
        "day_of_week"
    ],
    "user_normal_range_predictor": [
        "user_id",
        "age",
        "gender",
        "heart_rate",
        "gsr",
        "skin_temp",
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "time_of_day",
        "activity_type"
    ],
    "user_anomaly_detector": [
        "user_id",
        "age",
        "gender",
        "heart_rate",
        "gsr",
        "skin_temp",
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "time_of_day",
        "activity_type"
    ],
    "personalized_baseline_predictor": [
        "user_id",
        "age",
        "gender",
        "heart_rate",
        "gsr",
        "skin_temp",
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "time_of_day",
        "activity_type"
    ],
    "multi-task_user_baseline_neural_network": [
        "user_id",
        "age",
        "gender",
        "heart_rate",
        "gsr",
        "skin_temp",
        "eeg_alpha",
        "eeg_beta",
        "eeg_gamma",
        "time_of_day",
        "activity_type"
    ]
    # Add other models as defined in your full PDF spec if not included above.
}