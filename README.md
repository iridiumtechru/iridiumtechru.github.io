## Начало
В этом блоге будут публиковаться фрагменты кода, добытые путем долгих мучений. Почти весь код копипаста из интернета обработанная под определенные задачи. Код может быть неоптимальным и содержать ошибки. Просто он может сэконимть вам пару часов или дней.

## Первый блин
Всегда избегал virtualenv для python и видимо не зря. Куча разных вариантов его работы и никакой согласованности.
Решил использовать venv для python3 т.к. он новый. Просто новый.

Поставить:
'''bash
sudo apt install python3-venv
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

