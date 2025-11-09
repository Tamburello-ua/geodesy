# convert_calibration.py
import numpy as np
import json

def convert_npz_to_json(npz_file_path, json_file_path):
    # Загружаем данные из .npz файла
    data = np.load(npz_file_path)
    
    # Извлекаем матрицу камеры и коэффициенты дисторсии
    camera_matrix = data['camera_matrix']
    dist_coeffs = data['dist_coeffs']
    
    # Преобразуем в списки для JSON
    calibration_data = {
        'cameraMatrix': camera_matrix.flatten().tolist(),
        'distortionCoefficients': dist_coeffs.flatten().tolist(),
        'imageWidth': int(data.get('image_width', 0)),
        'imageHeight': int(data.get('image_height', 0))
    }
    
    # Сохраняем в JSON
    with open(json_file_path, 'w') as f:
        json.dump(calibration_data, f, indent=2)
    
    print(f"Данные калибровки сохранены в {json_file_path}")
    print(f"Матрица камеры: {camera_matrix}")
    print(f"Коэффициенты дисторсии: {dist_coeffs}")

# Использование
if __name__ == "__main__":
    convert_npz_to_json('calibration_data.npz', 'assets/calibration_data.json')