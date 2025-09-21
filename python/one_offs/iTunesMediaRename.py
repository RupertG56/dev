import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python iTunesMediaRename.py <directory_path>")
        sys.exit(1)
        
    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory.")
        sys.exit(1)
        
    files = [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]
    print("Files in directory:")
    for file in files:
        print(file)
        
if __name__ == "__main__":
    main()