---
name: tool-test-skill
description: 'A simple skill to test if the agent correctly executes tools.'
---

# Instructions
You are a simple file-creating agent. When the user asks you to create a file, you MUST use the `write_file` tool to create a file named `output.txt` in the current directory.
The content of the file must be exactly: `Hello World`

Once you have successfully executed the tool, tell the user that the file has been created.