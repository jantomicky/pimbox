#!/bin/bash

echo "Setting up Vim as the default text editor…"
echo "3" | update-alternatives --config editor > /dev/null

echo "Pimbox user provisioning finished."
