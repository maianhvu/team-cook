# 👨🏼‍🍳 Team Cook

Slideshow: https://www.figma.com/deck/eCOX465ARG9nNifZT5kg0f/iOS-Conf-26?node-id=24-1989&viewport=-5723%2C-74%2C0.52&t=2LlEKYFWWDvdRjsM-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1

## Setup

### Prerequisites

#### Install asdf

[asdf](https://asdf-vm.com) is a tool version manager that allows you to manage multiple runtime versions.

```bash
# macOS (Homebrew)
brew install asdf

# Add to your shell (zsh)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc
```

For other installation methods, see the [official asdf installation guide](https://asdf-vm.com/guide/getting-started.html).

#### Install bun

[Bun](https://bun.sh) is a fast all-in-one JavaScript runtime used for the API server.

```bash
# Add the bun plugin to asdf
asdf plugin add bun

# Install bun (version specified in .tool-versions)
asdf install bun
```

### Running the API Server

```bash
# Navigate to the server directory
cd servers/team-cook-api

# Install dependencies
bun install

# Run the server
bun run server.ts
```
