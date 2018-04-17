---
layout: post
published: false
title: Сборка ffmpeg с libx264 (windows, ios, osx, android)
---

Как собрать библиотеку с поддержкой кодека h264 на большинстве платформ.

## Зачем?

*Библиотеку ffmpeg я использую для воспроизведения потока с камер. Понадобилось сделать SIP телефонию с поддержкой h264. Для этого нужно было пересобрать все имеющиеся библиотеки. Все файлы для сборки либо потерялись, либо были нерабочими. Пришлось пройти этот ад снова.*

## Исходники
*Я использовал версию 2.8, которая лежала у меня с незапамятных времен. Можно использовать версию старше.*

Добываем исходники, либо [архивом](https://github.com/FFmpeg/FFmpeg/archive/release/2.8.zip), либо git:

`git clone -b release/2.8 https://github.com/FFmpeg/FFmpeg.git`

## Cборка x264
Первым делом собираем libx264. Если не требуется переходим сразу к сборке [FFmpeg](#ffmpeg)

### Windows
1. Ставим VS Studio [2015](https://www.visualstudio.com/ru/vs/older-downloads/) или выше. Минимальная версия [VS2013 u2](https://stackoverflow.com/questions/23099999/windows-how-to-build-x264-lib-instead-of-dll){:target="_blank"}.
2. Ставим [MSYS2](https://www.msys2.org/){:target="_blank"}.
3. Открываем консоль разработчика. **Пуск/Visual Studio (Version)/Developer Command Promt**. В ней будут доступны пути до компилятора и компоновщика.
4. Из открытой консоли открываем консоль MSYS2. 
- `C:\msys64\msys2_shell.cmd -mingw64 -full-path`

### iOS

### OSX

### Android

<a name="ffmpeg"></a>
## Cборка FFmpeg

### Windows

### iOS

### OSX

### Android

## Ссылки
1. [FFmpeg](https://ffmpeg.org/)
2. [VS build FFmpeg](https://blogs.gnome.org/rbultje/2012/09/27/microsoft-visual-studio-support-in-ffmpeg-and-libav/)
3. 
<!--
<div class="comment">
<div class="textarea" tabindex="0" role="textbox" aria-multiline="true" contenteditable="PLAINTEXT-ONLY" data-role="editable" aria-label="Start the discussion…" style="overflow: auto; word-wrap: break-word; max-height: 350px;"></div>
</div>
-->