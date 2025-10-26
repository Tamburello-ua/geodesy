import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time  # Импортируем модуль time
import random # Импортируем модуль random

# --- Функция для извлечения деталей камеры с отдельной страницы ---
def extract_camera_details(detail_url):
    """
    Загружает HTML со страницы деталей камеры и извлекает данные
    из блоков 'Lens', 'Sensor', 'Image', 'Focusing', 'Exposure and ISO'.
    """
    details = {}
    print(f"Обработка URL: {detail_url}")
    try:
        response = requests.get(detail_url)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        cards = soup.find_all('div', class_='card card-icon-3 card-body justify-content-between')
        target_sections = ["Lens", "Sensor", "Image", "Focusing", "Exposure and ISO"]
        found_sections_count = 0
        current_section_title = None # Для отслеживания последнего найденного заголовка

        for card in cards:
            title_tag = card.find(['h2', 'span'], class_='h2')
            if not title_tag:
                 title_tag = card.find('span', class_='h2')

            if title_tag and title_tag.text.strip() in target_sections:
                current_section_title = title_tag.text.strip()
                details[current_section_title] = {}
                found_sections_count += 1
                print(f"  Найден раздел: {current_section_title}")

                data_rows = card.find_all('div', class_=re.compile(r'col-\d+|col-\w+-\d+'))

                for row in data_rows:
                     value_tag = row.find('span', class_='display-4')
                     key_tag = row.find('span', class_='h6')

                     if value_tag and key_tag:
                         key = key_tag.contents[0].strip()
                         value = ' '.join(value_tag.text.split())
                         details[current_section_title][key] = value
                         # print(f"    {key}: {value}")

            # Прекращаем поиск после раздела "Exposure and ISO"
            if current_section_title == "Exposure and ISO":
                 break

        if found_sections_count < len(target_sections):
             print(f"  Предупреждение: Не все целевые разделы найдены на {detail_url}. Найдены: {list(details.keys())}")


    except requests.exceptions.RequestException as e:
        print(f"  Ошибка при запросе к {detail_url}: {e}")
        return None
    except Exception as e:
        print(f"  Произошла ошибка при парсинге {detail_url}: {e}")
        return None

    return details if details else None

# --- Основная часть скрипта (парсинг списка устройств) ---

list_url = 'https://www.camerafv5.com/devices/manufacturers/xiaomi/'
all_device_data = []

try:
    list_response = requests.get(list_url)
    list_response.raise_for_status()
    list_soup = BeautifulSoup(list_response.text, 'html.parser')
    device_list_div = list_soup.find('div', id='device-list')

    if device_list_div:
        devices = device_list_div.find_all('a', class_='list-group-item')

        # --- Ограничение для теста (опционально) ---
        devices = devices[:20]
        # print(f"Ограничение: обрабатываем {len(devices)} устройств")
        # --- Конец ограничения ---

        total_devices = len(devices) # Общее количество устройств для прогресса
        for index, device_link in enumerate(devices): # Используем enumerate для индекса
            manufacturer_span = device_link.find('span', class_='device-manufacturer')
            name_span = device_link.find('span', class_='device-name')
            detail_page_url_relative = device_link.get('href')

            manufacturer = manufacturer_span.text.strip() if manufacturer_span else 'N/A'
            name = name_span.text.strip() if name_span else 'N/A'

            if detail_page_url_relative:
                if detail_page_url_relative.startswith('//'):
                    full_detail_url = 'https:' + detail_page_url_relative
                else:
                    from urllib.parse import urljoin
                    full_detail_url = urljoin(list_url, detail_page_url_relative)

                # --- Добавляем случайную паузу перед запросом деталей ---
                sleep_duration = random.uniform(5, 15)
                print(f"\n--- Пауза перед {manufacturer} {name} ({index + 1}/{total_devices}) на {sleep_duration:.2f} сек ---")
                time.sleep(sleep_duration)
                # --- Конец добавления паузы ---

                camera_details = extract_camera_details(full_detail_url)

                device_info = {
                    'Manufacturer': manufacturer,
                    'Device Name': name,
                    'List URL': full_detail_url,
                    'Details': camera_details
                }
                all_device_data.append(device_info)
            else:
                 print(f"Предупреждение: Не найден URL для {manufacturer} {name}")
                 all_device_data.append({
                    'Manufacturer': manufacturer,
                    'Device Name': name,
                    'List URL': 'N/A',
                    'Details': None
                 })
                 # --- Добавляем паузу даже если URL не найден (чтобы сохранить ритм) ---
                 sleep_duration = random.uniform(5, 15)
                 print(f"\n--- Пауза (URL не найден) на {sleep_duration:.2f} сек ---")
                 time.sleep(sleep_duration)
                 # --- Конец добавления паузы ---


    else:
        print(f"Не удалось найти div с id='device-list' на странице {list_url}")

except requests.exceptions.RequestException as e:
    print(f"Ошибка при запросе к {list_url}: {e}")
except Exception as e:
    print(f"Произошла ошибка при парсинге списка: {e}")

# --- Вывод или сохранение результатов ---
if all_device_data:
    # (Остальная часть вывода и сохранения остается прежней)
    # Вывод для примера (первые несколько записей)
    for i, data in enumerate(all_device_data[:3]): # Показываем первые 3
        print("\n--- Устройство ---")
        print(f"Производитель: {data['Manufacturer']}")
        print(f"Название: {data['Device Name']}")
        print(f"URL: {data['List URL']}")
        if data['Details']:
            print("Детали камеры:")
            for section, values in data['Details'].items():
                print(f"  {section}:")
                for key, value in values.items():
                    print(f"    {key}: {value}")
        else:
            print("Детали камеры: Не найдены или ошибка при извлечении")
        if i == 2 : print("\n...и так далее.")

    # --- Преобразование в Pandas DataFrame и сохранение в CSV/JSON (опционально) ---
    try:
        df_expanded = pd.json_normalize(all_device_data, sep='_')
        print("\n--- DataFrame (развернутый) ---")
        print(df_expanded.head())

        # Сохранение в CSV
        df_expanded.to_csv('xiaomi_devices_detailed.csv', index=False, encoding='utf-8')
        print("\nРазвернутые данные сохранены в xiaomi_devices_detailed.csv")

    except Exception as e:
         print(f"\nОшибка при создании/сохранении развернутого DataFrame: {e}")
         import json
         try:
             with open('xiaomi_devices_detailed.json', 'w', encoding='utf-8') as f:
                 json.dump(all_device_data, f, ensure_ascii=False, indent=4)
             print("\nДанные сохранены в xiaomi_devices_detailed.json")
         except Exception as json_e:
             print(f"Ошибка при сохранении в JSON: {json_e}")

else:
    print("Данные не найдены или не удалось их извлечь из списка.")