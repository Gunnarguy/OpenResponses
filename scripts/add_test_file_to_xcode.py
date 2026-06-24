import sys
import uuid
import re

def generate_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    if len(sys.argv) != 2:
        print("Usage: python add_test_file_to_xcode.py <filename>")
        sys.exit(1)

    filename = sys.argv[1]
    pbxproj_path = "OpenResponses.xcodeproj/project.pbxproj"

    with open(pbxproj_path, "r") as f:
        content = f.read()

    if filename in content:
        print(f"File {filename} is already in the project.")
        sys.exit(0)

    file_ref_id = generate_id()
    build_file_id = generate_id()

    print(f"File Reference ID: {file_ref_id}")
    print(f"Build File ID: {build_file_id}")

    # Add PBXBuildFile
    build_file_entry = f"		{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};\n"
    content = re.sub(
        r"(/\* Begin PBXBuildFile section \*/\n)",
        r"\g<1>" + build_file_entry,
        content
    )

    # Add PBXFileReference
    file_ref_entry = f"		{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
    content = re.sub(
        r"(/\* Begin PBXFileReference section \*/\n)",
        r"\g<1>" + file_ref_entry,
        content
    )

    # Add to PBXGroup
    # Find the OpenResponsesTests group. It usually looks like:
    # /* OpenResponsesTests */ = {
    #     isa = PBXGroup;
    #     children = (
    #         ...,
    group_pattern = r"(/\* OpenResponsesTests \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)"
    content = re.sub(
        group_pattern,
        r"\g<1>\t\t\t\t" + file_ref_id + f" /* {filename} */,\n",
        content
    )

    # Add to PBXSourcesBuildPhase for OpenResponsesTests
    # Find the sources build phase for the tests target.
    # It usually has a comment /* Sources */ and is part of the test target
    # We will just find the one that has other test files in it
    sources_pattern = r"(/\* Sources \*/ = \{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = \(\n)"

    # Actually there are two PBXSourcesBuildPhase, one for app, one for tests.
    # We should find the one for OpenResponsesTests. Let's find the ID of OpenResponsesTests build phase.
    # We can just look for the block containing "OpenResponsesTests.swift in Sources"
    content = re.sub(
        r"(/\* OpenResponsesTests\.swift in Sources \*/,\n)",
        r"\g<1>\t\t\t\t" + build_file_id + f" /* {filename} in Sources */,\n",
        content
    )

    with open(pbxproj_path, "w") as f:
        f.write(content)

    print(f"Successfully added {filename} to {pbxproj_path}")

if __name__ == "__main__":
    main()
