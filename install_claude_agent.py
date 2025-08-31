#!/usr/bin/env python
"""Direct installer for the Claude agent."""

import shutil
import sys
from pathlib import Path

def install_claude_agent():
    """Install the Claude Code subagent for Hylang migrations."""
    source_dir = Path(__file__).parent / ".claude" / "agents"
    target_dir = Path.home() / ".claude" / "agents"
    agent_file = "hylang-migrate-assistant.md"
    
    # Create target directory if it doesn't exist
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if source agent file exists
    source_file = source_dir / agent_file
    if source_file.exists():
        # Copy agent file to target
        target_file = target_dir / agent_file
        shutil.copy2(source_file, target_file)
        print(f"✅ Successfully installed Claude agent to: {target_file}")
        print("\n📝 The hylang-migrate-assistant is now available!")
        print("   Use it in Claude Code to get expert help with:")
        print("   • Creating and managing migrations")
        print("   • Debugging migration issues")
        print("   • Schema design best practices")
        print("   • Hylang v1.1.0 migration syntax")
        print("\n💡 Tip: In Claude Code, type '/agents' to see and use the assistant!")
        return 0
    else:
        print(f"❌ Error: Agent file not found at {source_file}")
        print("   Make sure you're running from the hylang-migrations repository root")
        return 1

if __name__ == "__main__":
    sys.exit(install_claude_agent())