# /review

Run a standalone code review.

## Usage
```
/review                    # Review staged git changes
/review path/to/file.ext   # Review specific file
/review src/               # Review all files in directory
```

## Behavior

1. Read `~/.claude-forge/SYSTEM.md`
2. Load the reviewer agent from `~/.claude-forge/agents/stable/reviewer.md`
3. Run the review pipeline
4. Present findings categorized by severity
