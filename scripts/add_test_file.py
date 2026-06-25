import uuid
import re
import sys

def generate_pbx_uuid():
    """Generates a 24-character hex string representing a pseudo-UUID for PBXProj."""
    return uuid.uuid4().hex[:24].upper()

def update_pbxproj(file_path, target_file_name, target_group_name, build_phase_name):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if target_file_name in content:
            print(f"File {target_file_name} already exists in project.")
            return

        file_ref_uuid = generate_pbx_uuid()
        build_file_uuid = generate_pbx_uuid()

        file_ref_string = f"\t\t{file_ref_uuid} /* {target_file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {target_file_name}; sourceTree = \"<group>\"; }};\n"
        build_file_string = f"\t\t{build_file_uuid} /* {target_file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {target_file_name} */; }};\n"

        # 1. Insert PBXBuildFile
        build_file_section_end = content.find("/* End PBXBuildFile section */")
        if build_file_section_end == -1:
            raise Exception("Could not find PBXBuildFile section")
        content = content[:build_file_section_end] + build_file_string + content[build_file_section_end:]

        # 2. Insert PBXFileReference
        file_ref_section_end = content.find("/* End PBXFileReference section */")
        if file_ref_section_end == -1:
            raise Exception("Could not find PBXFileReference section")
        content = content[:file_ref_section_end] + file_ref_string + content[file_ref_section_end:]

        # 3. Add to Group
        group_pattern = re.compile(rf"/\* {target_group_name} \*/ = {{\s*isa = PBXGroup;\s*children = \(\s*([^)]+)\);", re.MULTILINE)
        group_match = group_pattern.search(content)
        if not group_match:
            raise Exception(f"Could not find PBXGroup for {target_group_name}")

        children_str = group_match.group(1)
        new_children_str = children_str + f"\t\t\t\t{file_ref_uuid} /* {target_file_name} */,\n"
        content = content[:group_match.start(1)] + new_children_str + content[group_match.end(1):]

        # 4. Add to Sources Build Phase
        build_phase_pattern = re.compile(rf"/\* {build_phase_name} \*/ = {{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = [0-9]+;\s*files = \(\s*([^)]+)\);", re.MULTILINE)

        # We might match the main app's sources phase first, we want the test target one.
        # It's tricky to distinguish by name alone if they are both "Sources".
        # Let's look for a Sources build phase that contains an existing test file.
        # "OpenResponsesTests.swift in Sources"

        sources_phase_start = content.find("/* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;")
        found = False
        while sources_phase_start != -1:
            phase_end = content.find("};", sources_phase_start)
            phase_content = content[sources_phase_start:phase_end]
            if "OpenResponsesTests.swift in Sources" in phase_content:
                files_start = content.find("files = (", sources_phase_start) + len("files = (\n")
                new_file_line = f"\t\t\t\t{build_file_uuid} /* {target_file_name} in Sources */,\n"
                content = content[:files_start] + new_file_line + content[files_start:]
                found = True
                break
            sources_phase_start = content.find("/* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;", phase_end)

        if not found:
             raise Exception("Could not find appropriate PBXSourcesBuildPhase")


        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Successfully added {target_file_name} to project.")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    update_pbxproj("OpenResponses.xcodeproj/project.pbxproj", "AppleDateUtilitiesTests.swift", "OpenResponsesTests", "Sources")
