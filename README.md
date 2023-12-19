# zsh-fullpath-git-completion

This plugin replaces the incremental file completion inside git repositories so that it always returns full relative paths of the relevant files.
This is achieved by overriding a few low level zsh functions providing these completions originally.

# Installation

Just add the plugin to your preferred plugin manager. It should probably be loaded after initializing the completion system.

# Acknowledgements
- ZSH for providing the original git completions (see [https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_git](https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_git))
- This thread upon which my modifications are mainly based on: https://www.zsh.org/mla/workers/2020/msg00557.html
