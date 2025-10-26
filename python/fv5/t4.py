import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time
import random
import json
from urllib.parse import urljoin # Импортируем urljoin для удобства

# --- Функция для извлечения деталей камеры с отдельной страницы ---
def extract_camera_details(detail_url):
    """
    Загружает HTML со страницы деталей камеры и извлекает данные
    из блоков 'Lens', 'Sensor', 'Image', 'Focusing', 'Exposure and ISO'.
    Возвращает словарь с деталями или None при ошибке.
    """
    details = {}
    print(f"Обработка URL: {detail_url}")
    try:
        # Устанавливаем таймаут для запроса (например, 10 секунд)
        response = requests.get(detail_url, timeout=10)
        response.raise_for_status() # Проверяем HTTP ошибки (4xx, 5xx)
        soup = BeautifulSoup(response.text, 'html.parser')

        # Находим все карточки с данными
        cards = soup.find_all('div', class_='card card-icon-3 card-body justify-content-between')
        target_sections = ["Lens", "Sensor", "Image", "Focusing", "Exposure and ISO"]
        found_sections_count = 0
        current_section_title = None

        for card in cards:
            # Ищем заголовок секции (может быть h2 или span)
            title_tag = card.find(['h2', 'span'], class_='h2')
            if not title_tag:
                 title_tag = card.find('span', class_='h2') # Специально для "Lens"

            if title_tag and title_tag.text.strip() in target_sections:
                current_section_title = title_tag.text.strip()
                details[current_section_title] = {}
                found_sections_count += 1
                # print(f"  Найден раздел: {current_section_title}") # Для отладки

                # Находим все колонки с данными внутри карточки
                data_rows = card.find_all('div', class_=re.compile(r'col-\d+|col-\w+-\d+'))

                for row in data_rows:
                     value_tag = row.find('span', class_='display-4')
                     key_tag = row.find('span', class_='h6')

                     if value_tag and key_tag:
                         # Получаем ключ (текст до возможного help-icon)
                         key = key_tag.contents[0].strip()
                         # Получаем значение, очищаем от лишних пробелов/переносов
                         value = ' '.join(value_tag.text.split())
                         # Добавляем пару ключ-значение в словарь секции
                         details[current_section_title][key] = value
                         # print(f"    {key}: {value}") # Для отладки

            # Если нашли последнюю нужную секцию, выходим из цикла по карточкам
            if current_section_title == target_sections[-1]:
                 break

        # Предупреждение, если не все секции найдены
        if found_sections_count < len(target_sections):
             print(f"  Предупреждение: Не все целевые разделы найдены на {detail_url}. Найдены: {list(details.keys())}")

    # Обработка сетевых ошибок
    except requests.exceptions.Timeout:
        print(f"  Ошибка: Таймаут при запросе к {detail_url}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"  Ошибка при запросе к {detail_url}: {e}")
        return None
    # Обработка других возможных ошибок (например, при парсинге)
    except Exception as e:
        print(f"  Произошла ошибка при парсинге {detail_url}: {e}")
        return None

    # Возвращаем словарь с деталями, или None если он пуст
    return details if details else None

# --- Основная часть скрипта (парсинг списка и запись в файл) ---

list_url = 'https://www.camerafv5.com/devices/manufacturers/xiaomi/'
output_filename = 'xiaomi_devices_detailed.jsonl' # Имя файла для сохранения

# Используем 'try...except' для перехвата критических ошибок (файл, сеть)
try:
    # Открываем файл для записи ПЕРЕД циклом в режиме 'w' (перезапись)
    with open(output_filename, 'w', encoding='utf-8') as outfile:
        print(f"Данные будут записываться в файл: {output_filename}")

        # 1. Получаем HTML страницы со списком устройств
        print(f"Загрузка списка устройств с {list_url}...")
        list_response = requests.get(list_url, timeout=15) # Таймаут для списка
        list_response.raise_for_status()
        print("Список загружен.")

        # 2. Парсим список устройств
        list_soup = BeautifulSoup(list_response.text, 'html.parser')
        device_list_div = list_soup.find('div', id='device-list')

        if not device_list_div:
            print(f"Критическая ошибка: Не удалось найти div с id='device-list' на странице {list_url}")
            # Выход, если не нашли основной контейнер
        else:
            devices = device_list_div.find_all('a', class_='list-group-item')
            total_devices = len(devices)
            print(f"Найдено устройств для обработки: {total_devices}")

            # --- Ограничение для теста (опционально) ---
            # devices = devices[:5]
            # total_devices = len(devices)
            # print(f"Ограничение: обрабатываем {total_devices} устройств")
            # --- Конец ограничения ---

            # 3. Итерация по списку устройств
            for index, device_link in enumerate(devices):
                # Извлекаем базовую информацию из списка
                manufacturer_span = device_link.find('span', class_='device-manufacturer')
                name_span = device_link.find('span', class_='device-name')
                detail_page_url_relative = device_link.get('href')

                manufacturer = manufacturer_span.text.strip() if manufacturer_span else 'N/A'
                name = name_span.text.strip() if name_span else 'N/A'
                full_detail_url = 'N/A'
                camera_details = None

                # 4. Получение URL деталей и извлечение данных
                if detail_page_url_relative:
                    # Формируем абсолютный URL
                    if detail_page_url_relative.startswith('//'):
                        full_detail_url = 'https:' + detail_page_url_relative
                    else:
                        full_detail_url = urljoin(list_url, detail_page_url_relative) # Используем urljoin

                    # --- Случайная пауза перед запросом ---
                    sleep_duration = random.uniform(5, 15)
                    print(f"\n--- Пауза перед {manufacturer} {name} ({index + 1}/{total_devices}) на {sleep_duration:.2f} сек ---")
                    time.sleep(sleep_duration)
                    # --- Конец паузы ---

                    # Вызываем функцию для получения деталей
                    camera_details = extract_camera_details(full_detail_url)

                else:
                    print(f"Предупреждение: Не найден URL для {manufacturer} {name} ({index + 1}/{total_devices})")
                    # --- Пауза (даже если URL не найден) ---
                    sleep_duration = random.uniform(5, 15)
                    print(f"\n--- Пауза (URL не найден) на {sleep_duration:.2f} сек ---")
                    time.sleep(sleep_duration)
                    # --- Конец паузы ---

                # 5. Формирование записи для файла
                device_info = {
                    'Manufacturer': manufacturer,
                    'Device Name': name,
                    'List URL': full_detail_url,
                    'Details': camera_details # будет None при ошибке или отсутствии URL
                }

                # 6. Запись данных одного устройства в файл .jsonl
                try:
                    json_line = json.dumps(device_info, ensure_ascii=False)
                    outfile.write(json_line + '\n')
                    outfile.flush() # Принудительная запись на диск
                    print(f"  Записаны данные для {manufacturer} {name}")
                except Exception as write_e:
                    # Ловим ошибку записи, если вдруг возникнет
                    print(f"  !!! Ошибка записи в файл для {manufacturer} {name}: {write_e}")

            print(f"\nОбработка {total_devices} устройств завершена.")

except requests.exceptions.Timeout:
    print(f"Критическая ошибка: Таймаут при запросе к списку устройств {list_url}")
except requests.exceptions.RequestException as e:
    print(f"Критическая ошибка при запросе к списку устройств {list_url}: {e}")
except IOError as e:
    print(f"Критическая ошибка при работе с файлом {output_filename}: {e}")
except Exception as e:
    print(f"Произошла непредвиденная ошибка во время выполнения: {e}")


# --- Загрузка и проверка данных из файла (опционально, после завершения скрипта) ---
print("\n--- Проверка содержимого файла ---")
try:
    data_loaded = []
    line_count = 0
    with open(output_filename, 'r', encoding='utf-8') as infile:
        for line in infile:
            line_count += 1
            try:
                data_loaded.append(json.loads(line))
            except json.JSONDecodeError as json_e:
                print(f"Ошибка декодирования JSON в строке {line_count}: {json_e}")
                print(f" > Содержимое строки: {line.strip()}") # Показываем проблемную строку

    print(f"Проверка: Успешно прочитано {line_count} строк и загружено {len(data_loaded)} JSON записей из {output_filename}")

    # Можно создать DataFrame из загруженных данных, если нужно
    # if data_loaded:
    #    try:
    #        df_loaded = pd.json_normalize(data_loaded, sep='_')
    #        print("\n--- DataFrame (первые 5 строк из файла .jsonl) ---")
    #        print(df_loaded.head())
    #    except Exception as df_e:
    #        print(f"Ошибка при создании DataFrame из загруженных данных: {df_e}")


except FileNotFoundError:
    print(f"Файл {output_filename} не найден для проверки.")
except Exception as e:
    print(f"Ошибка при проверке файла {output_filename}: {e}")