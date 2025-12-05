#!/usr/bin/env python3
import os

def replace_path_in_files(directory):
    old_prefix = "/media/bro_grammer"
    new_prefix = "/mnt"

    # Traverse all files in the given directory
    for root, _, files in os.walk(directory):
        for filename in files:
            filepath = os.path.join(root, filename)

            # Only process text-like files
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    lines = f.readlines()

                modified = False
                new_lines = []
                for line in lines:
                    if line.startswith(old_prefix):
                        line = line.replace(old_prefix, new_prefix, 1)
                        modified = True
                    new_lines.append(line)

                if modified:
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.writelines(new_lines)
                    print(f"✔ Updated: {filepath}")
            except UnicodeDecodeError:
                # Skip binary or non-text files
                continue

if __name__ == "__main__":
    # dir_path = input("Enter directory path: ").strip()
    dir_path = "~/.config/cmus/playlists_1/"
    # if os.path.isdir(dir_path):
    #     replace_path_in_files(dir_path)
    # else:
    #     print("Invalid directory.")

