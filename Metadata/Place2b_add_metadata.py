import sys
from mutagen.wave import WAVE
from mutagen.id3 import ID3, TALB, COMM, TXXX
from mutagen.mp3 import MP3

def add_metadata(file_path, album, description, comment):
    try:
        # Проверяем расширение файла
        if file_path.lower().endswith('.wav'):
            audio = WAVE(file_path)
            # Добавляем BWF-совместимые теги
            if not audio.tags:
                audio.add_tags()
            audio.tags['TALB'] = album  # Album
            audio.tags['TXXX:DESCRIPTION'] = description  # Description
            audio.tags['COMM'] = comment  # Comment
            audio.save()
        elif file_path.lower().endswith('.mp3'):
            audio = MP3(file_path, ID3=ID3)
            # Добавляем ID3-теги
            audio.tags.add(TALB(encoding=3, text=album))  # Album
            audio.tags.add(TXXX(encoding=3, desc='DESCRIPTION', text=description))  # Description
            audio.tags.add(COMM(encoding=3, lang='eng', desc='comment', text=comment))  # Comment
            audio.save()
        else:
            print(f"Формат файла {file_path} не поддерживается")
    except Exception as e:
        print(f"Ошибка при обработке {file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Использование: python add_metadata.py <file_path> <album> <description> <comment>")
        sys.exit(1)
    
    file_path, album, description, comment = sys.argv[1:5]
    add_metadata(file_path, album, description, comment)