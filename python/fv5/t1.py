import requests
from bs4 import BeautifulSoup
import pandas as pd # Добавляем импорт pandas

# URL страницы
url = 'https://www.camerafv5.com/devices/manufacturers/xiaomi/' # Укажите здесь нужный URL

# Список для хранения данных
device_data = []

try:
    # Отправляем GET-запрос к странице
    response = requests.get(url)
    response.raise_for_status() # Проверяем, успешен ли запрос

    # Используем BeautifulSoup для парсинга HTML
    soup = BeautifulSoup(response.text, 'html.parser')

    # Находим основной div со списком устройств
    device_list_div = soup.find('div', id='device-list')

    if device_list_div:
        # Находим все ссылки (<a>) внутри этого div, которые содержат информацию об устройстве
        # Используем 'list-group-item' класс для точности
        devices = device_list_div.find_all('a', class_='list-group-item')

        for device in devices:
            manufacturer_span = device.find('span', class_='device-manufacturer')
            name_span = device.find('span', class_='device-name')
            device_url = device.get('href') # Получаем значение атрибута href

            # Извлекаем текст, если теги найдены
            manufacturer = manufacturer_span.text.strip() if manufacturer_span else 'N/A'
            name = name_span.text.strip() if name_span else 'N/A'

            # Добавляем префикс к URL, если он относительный
            if device_url and device_url.startswith('//'):
                full_url = 'https:' + device_url
            else:
                 full_url = device_url if device_url else 'N/A' # Или оставляем как есть, если абсолютный

            # Добавляем найденные данные в список
            device_data.append({
                'Manufacturer': manufacturer,
                'Device Name': name,
                'URL': full_url
            })

    else:
        print(f"Не удалось найти div с id='device-list' на странице {url}")

except requests.exceptions.RequestException as e:
    print(f"Ошибка при запросе к {url}: {e}")
except Exception as e:
    print(f"Произошла ошибка при парсинге: {e}")

# --- Вывод данных (например, в DataFrame pandas) ---
if device_data:
    df = pd.DataFrame(device_data)
    print(df)

    # Опционально: сохранить в CSV
    df.to_csv('xiaomi_devices.csv', index=False, encoding='utf-8')
    print("\nДанные сохранены в xiaomi_devices.csv")
else:
    print("Данные не найдены или не удалось их извлечь.")