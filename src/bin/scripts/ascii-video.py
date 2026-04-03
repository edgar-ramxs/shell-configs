#!/usr/bin/env python3
import subprocess
import sys
import os
from PIL import Image
import time

# Diferentes conjuntos de caracteres ASCII
CHAR_SETS = {
    'simple': ['@', '#', 'S', '%', '?', '*', '+', ';', ':', ',', '.', ' '],
    
    'detallado': ['$', '@', 'B', '%', '8', '&', 'W', 'M', '#', '*', 'o', 'a', 'h', 'k', 
                  'b', 'd', 'p', 'q', 'w', 'm', 'Z', 'O', '0', 'Q', 'L', 'C', 'J', 'U', 
                  'Y', 'X', 'z', 'c', 'v', 'u', 'n', 'x', 'r', 'j', 'f', 't', '/', '\\', 
                  '|', '(', ')', '1', '{', '}', '[', ']', '?', '-', '_', '+', '~', '<', 
                  '>', 'i', '!', 'l', 'I', ';', ':', ',', '"', '^', '`', '.', ' '],
    
    'bloques': ['█', '▓', '▒', '░', '▪', '▫', '●', '○', '◘', '◙', '•', '·', ' '],
    
    'standard': [' ', '.', ':', '-', '=', '+', '*', '#', '%', '@'],
    
    'denso': ['@', '@', '#', '#', '8', '8', '&', '&', 'o', 'o', ':', ':', '.', '.', ' ', ' '],
    
    'completo': ['█', '▓', '▒', '░', '@', '#', 'M', 'W', 'N', 'K', 'D', 'O', 'Q', 'P', 
                 'X', 'R', 'H', 'B', 'A', 'G', '$', '&', '%', '8', '0', 'U', '9', '6', 
                 '5', '4', '3', '2', '1', '?', '*', '+', '=', ';', ':', ',', '.', ' '],
    
    'sombras': ['▓', '▒', '░', 'M', 'W', 'H', 'Q', 'B', 'N', 'K', 'A', 'G', '&', '%', 
                '$', '8', '0', 'o', 'a', 'h', 'k', 'd', 'p', 'q', 'w', 'm', '*', 'o', 
                '+', '=', ';', ':', ',', '.', ' ']
}

def video_to_ascii(video_path, width=120, fps=15, charset='simple'):
    """
    Convierte y reproduce un video como arte ASCII en la terminal
    """
    # Seleccionar conjunto de caracteres
    if charset not in CHAR_SETS:
        print(f"Conjunto '{charset}' no válido. Usando 'simple'")
        charset = 'simple'
    
    ascii_chars = CHAR_SETS[charset]
    
    # Crear directorio temporal para frames
    temp_dir = "/tmp/ascii_frames"
    os.makedirs(temp_dir, exist_ok=True)
    
    print(f"Usando conjunto de caracteres: '{charset}' ({len(ascii_chars)} caracteres)")
    print("Extrayendo frames del video...")
    
    # Extraer frames con ffmpeg
    cmd = [
        'ffmpeg', '-i', video_path,
        '-vf', f'fps={fps},scale={width}:-1',
        '-y',
        f'{temp_dir}/frame_%04d.jpg'
    ]
    
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # Obtener lista de frames
    frames = sorted([f for f in os.listdir(temp_dir) if f.endswith('.jpg')])
    
    if not frames:
        print("Error: No se pudieron extraer frames")
        return
    
    print(f"Reproduciendo {len(frames)} frames...")
    print("Presiona Ctrl+C para detener\n")
    time.sleep(2)
    
    try:
        for frame in frames:
            # Limpiar pantalla
            os.system('clear' if os.name != 'nt' else 'cls')
            
            # Cargar imagen
            img = Image.open(f"{temp_dir}/{frame}").convert('L')
            
            # Convertir a ASCII
            ascii_art = []
            for y in range(0, img.height, 2):  # Paso de 2 para compensar proporción
                line = ""
                for x in range(img.width):
                    pixel = img.getpixel((x, y))
                    char_index = pixel * len(ascii_chars) // 256
                    line += ascii_chars[char_index]
                ascii_art.append(line)
            
            # Mostrar frame
            print('\n'.join(ascii_art))
            
            # Esperar según FPS
            time.sleep(1.0 / fps)
            
    except KeyboardInterrupt:
        print("\n\nReproducción detenida")
    finally:
        # Limpiar archivos temporales
        print("Limpiando archivos temporales...")
        subprocess.run(['rm', '-rf', temp_dir])

def show_charsets():
    """Muestra los conjuntos de caracteres disponibles"""
    print("\n" + "="*70)
    print("CONJUNTOS DE CARACTERES DISPONIBLES")
    print("="*70)
    for name, chars in CHAR_SETS.items():
        preview = ''.join(chars[:20]) + ('...' if len(chars) > 20 else '')
        print(f"\n  {name:12s} ({len(chars):2d} chars): {preview}")
    print("\n" + "="*70)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("="*70)
        print("REPRODUCTOR DE VIDEO ASCII")
        print("="*70)
        print("\nUso: python3 ascii_video_player.py <video> [ancho] [fps] [conjunto]")
        print("\nParámetros:")
        print("  video     : Ruta al archivo de video")
        print("  ancho     : Ancho en caracteres (default: 120)")
        print("  fps       : Frames por segundo (default: 15)")
        print("  conjunto  : Tipo de caracteres (default: simple)")
        
        show_charsets()
        
        print("\nEjemplos:")
        print("  python3 ascii_video_player.py video.mp4")
        print("  python3 ascii_video_player.py video.mp4 100 15 sombras")
        print("  python3 ascii_video_player.py video.mp4 150 20 bloques")
        print("  python3 ascii_video_player.py video.mp4 80 10 detallado")
        print("="*70)
        sys.exit(1)
    
    video = sys.argv[1]
    width = int(sys.argv[2]) if len(sys.argv) > 2 else 120
    fps = int(sys.argv[3]) if len(sys.argv) > 3 else 15
    charset = sys.argv[4] if len(sys.argv) > 4 else 'simple'
    
    if not os.path.exists(video):
        print(f"Error: El archivo {video} no existe")
        sys.exit(1)
    
    video_to_ascii(video, width, fps, charset)