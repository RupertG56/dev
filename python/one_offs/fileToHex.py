import sys

def file_to_hex(filename, line_length=256):
    """Read a file and print its contents as hexadecimal."""
    try:
        with open(filename, 'rb') as f:
            data = f.read()
            hex_string = data.hex()
        
        with open(filename + '.hex.txt', 'w') as output:
            for i in range(0, len(hex_string), line_length):
                output.write(hex_string[i:i+line_length] + '\n')
        
        print(f"Hex output written to {filename}.hex.txt")
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fileToHex.py <filename>")
        sys.exit(1)
    
    file_to_hex(sys.argv[1], int(sys.argv[2]))