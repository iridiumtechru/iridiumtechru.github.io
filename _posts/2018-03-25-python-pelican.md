---
layout: post
published: false
title: Создание сайта(блога) на GitHub Pages с использованием pelican
---

### Поставить:

sudo apt install python3-venv

pyvenv [путь где будет лежать папка с виртуальным окружением]

в моем влучае:
pyvenv-3.5 ~/blogenv
- напрямую от версии питона. во всех источниках куча вариантов

активировать:
source ~/blogenv/bin/activate

в данном случае source важно. проверить что venv включился можно так:

pip -V будет указывать на ~/blogenv

Поставить пакеты.

sudo pip3 install pelican markdown

mkdir src

cd src

pelican-quickstart
'''

Windows:
python 3.4

Установить:
стоит из коробки

Создать env:
python -m venv blogenv

Активировать:
blogenv\Scripts\activate.bat

Появится префикс (blogenv) в терминале 

Потом по https://eax.me/pelican/

pip install pelican markdown
mkdir src
cd src
pelican-quickstart
pelican --relative-urls --ignore-cache -o .. content

попытался запустить develop_server.sh start 8000
но там был сгенерирован python3
