import sys

def extract_log(version):
    try:
        with open("CHANGELOG.md", "r", encoding="utf-8") as file:
            lines = file.readlines()
    except FileNotFoundError:
        print("Error: not found CHANGELOG.md")
        return

    found = False
    changelog_lines = []

    for line in lines:
        if line.startswith(f"## {version}"):
            found = True
            continue
        elif line.startswith("## ") and found:
            break
        if found:
            changelog_lines.append(line)

    while changelog_lines and not changelog_lines[-1].strip():
        changelog_lines.pop()

    output = "".join(changelog_lines).strip()

    output_file = f"CHANGELOG_{version}.md"
    with open(output_file, "w", encoding="utf-8") as file:
        file.write(output)

    print(f"Changelog for {version} saved to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_log.py <version>")
        sys.exit(1)

    version = sys.argv[1]
    extract_log(version)