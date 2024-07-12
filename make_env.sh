#!/bin/sh

echo "UID=$(id -u $USER)" > .env
echo "GID=$(id -g $USER)" >> .env
echo "UNAME=$USER" >> .env
