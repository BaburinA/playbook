#!/bin/bash

# Проверяем, существует ли пользователь ansible-ib
if id "ansible-ib" &>/dev/null; then
  echo "Пользователь ansible-ib существует"

  # Проверяем, состоит ли пользователь в группе wheel
  if groups ansible-ib | grep -qw "wheel"; then
    echo "Пользователь ansible-ib состоит в группе wheel"
    
    # Удаляем пользователя из группы wheel
    sudo gpasswd -d ansible-ib wheel

    if [ $? -eq 0 ]; then
      echo "Пользователь ansible-ib удалён из группы wheel"
    else
      echo "Ошибка при удалении пользователя из группы wheel"
      exit 1
    fi
  else
    echo "Пользователь ansible-ib не состоит в группе wheel"
  fi
else
  echo "Пользователь ansible-ib не существует"
fi

# Проверяем, есть ли уже нужная строка в sudoers
if sudo grep -q "^ansible-ib ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
  echo "Строка уже существует в /etc/sudoers"
  exit 0
fi

# Добавляем строку через visudo для безопасности
echo "ansible-ib ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo -f /dev/stdin >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Строка успешно добавлена в /etc/sudoers"
else
  echo "Ошибка при добавлении строки в /etc/sudoers"
  exit 1
fi
