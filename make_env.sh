#!/bin/sh

echo "UID=$(id -u $USER)" > .env
echo "GID=$(id -g $USER)" >> .env
