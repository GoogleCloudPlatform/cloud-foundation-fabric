parent = "organizations/1234567890"
name   = "Folder Boundaries"
boundary_configs = {
  boundaries = {
    all-projects = {
      display_name = "All Projects"
    }
  }
}
capability_configs = {
  agent-all = {
    display_name = "All Projects Agents"
    boundaries   = ["all-projects"]
  }
}
