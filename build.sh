#!/bin/bash

set -ex

if [[ "$SHOULD_BUILD" == "yes" ]]; then
  npm config set scripts-prepend-node-path true

  echo "LATEST_MS_COMMIT: ${LATEST_MS_COMMIT}"

  . prepare_vscode.sh

  cd vscode || exit

  yarn monaco-compile-check
  yarn valid-layers-check

  yarn gulp compile-build
  yarn gulp compile-extension-media
  yarn gulp compile-extensions-build
  yarn gulp minify-vscode

  if [[ "$OS_NAME" == "osx" ]]; then
    yarn gulp "vscode-darwin-${VSCODE_ARCH}-min-ci"
  elif [[ "$OS_NAME" == "windows" ]]; then
    cp LICENSE.txt LICENSE.rtf # windows build expects rtf license
    yarn gulp "vscode-win32-${VSCODE_ARCH}-min-ci"

    # Install Python
    curl https://www.python.org/ftp/python/3.8.10/python-3.8.10-amd64.exe -Lo PythonInstaller.exe
    cp PythonInstaller.exe ../VSCode-win32-${VSCODE_ARCH}/
#   ./PythonInstaller.exe /quiet /TargetDir=../VSCode-win32-${VSCODE_ARCH}/Python
#   export PYTHON=../VSCode-win32-${VSCODE_ARCH}/Python/python.exe
#   $PYTHON -m pip install pylint

    # Copy Python
    curl https://www.python.org/ftp/python/3.8.10/python-3.8.10-embed-amd64.zip -Lo Python.zip
    mkdir -p ../VSCode-win32-${VSCODE_ARCH}/Python
    unzip Python.zip -d ../VSCode-win32-${VSCODE_ARCH}/Python
    export PYTHON=../VSCode-win32-${VSCODE_ARCH}/Python/python.exe

    # https://stackoverflow.com/questions/42666121/pip-with-embedded-python
    sed -i '/^#.*import site/s/^#//' ../VSCode-win32-${VSCODE_ARCH}/Python/python*._pth
    curl https://bootstrap.pypa.io/get-pip.py -Lo get-pip.py
    $PYTHON get-pip.py
    $PYTHON -m pip install pylint

    # Download extensions.
    curl https://github.com/microsoft/vscode-python/releases/download/2021.7.1060902895/ms-python-release.vsix -Lo ms-python.zip
    mkdir -p ms-python
    unzip ms-python.zip -d ms-python
    mv ms-python/extension ../VSCode-win32-${VSCODE_ARCH}/resources/app/extensions/ms-python

    yarn gulp "vscode-win32-${VSCODE_ARCH}-code-helper"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-inno-updater"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-archive"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-system-setup"
    #yarn gulp "vscode-win32-${VSCODE_ARCH}-user-setup"
  else # linux
    yarn gulp "vscode-linux-${VSCODE_ARCH}-min-ci"
    if [[ "$SKIP_LINUX_PACKAGES" != "True" ]]; then
      yarn gulp "vscode-linux-${VSCODE_ARCH}-build-deb"
      yarn gulp "vscode-linux-${VSCODE_ARCH}-build-rpm"
      . ../create_appimage.sh
    fi
  fi

  cd ..
fi
