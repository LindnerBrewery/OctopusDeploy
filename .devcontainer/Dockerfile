FROM mcr.microsoft.com/powershell:lts-debian-11

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && chsh "${USERNAME}" -s "$(which pwsh)" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# Download the oh-my-posh binary
RUN mkdir /home/${USERNAME}/bin; \
    wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$(dpkg --print-architecture) -O /home/${USERNAME}/bin/oh-my-posh; \
    chmod +x /home/${USERNAME}/bin/oh-my-posh; \
    chown ${USERNAME}: /home/${USERNAME}/bin;

# add the oh-my-posh path to the PATH variable
ENV PATH "$PATH:/home/${USERNAME}/bin"

# Can be used to override the devcontainer prompt default theme:
RUN wget https://gist.githubusercontent.com/lindnerbrewery/bed217b6b9dd59696a2b732a3c918d2d/raw/my.omp.json -O /home/${USERNAME}/my.omp.json;
ENV POSH_THEMES_PATH "/home/${USERNAME}"
ENV POSH_THEME="/workspaces/oh-my-posh/themes/my.omp.json"


# Setup a neat little PowerShell experience
RUN pwsh -Command Install-Module posh-git -Scope AllUsers -Force; \
    pwsh -Command Install-Module Terminal-Icons -Scope AllUsers -Force;\
    pwsh -Command Install-Module Configuration -Scope AllUsers -Force;\
    pwsh -Command Install-Module Profiler -Scope AllUsers -Force;


# Deploy oh-my-posh prompt to Powershell:
#COPY Microsoft.PowerShell_profile.ps1 /home/${USERNAME}/.config/powershell/Microsoft.PowerShell_profile.ps1
# [Optional] Uncomment this section to install additional packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
