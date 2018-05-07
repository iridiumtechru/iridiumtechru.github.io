---
layout: post
published: false
title: Сборка ffmpeg с libx264 (windows, ios, osx, android)
---

<!--<style>
strong {color:#f4bf75}
</style>-->
Как собрать библиотеку с поддержкой кодека h264 на большинстве платформ.

## Зачем?

*Библиотеку ffmpeg я использую для воспроизведения потока с камер. Понадобилось сделать SIP телефонию с поддержкой h264. Для этого нужно было пересобрать все имеющиеся библиотеки. Все файлы для сборки либо потерялись, либо были нерабочими. Пришлось пройти этот ад снова.*

## Исходники

### FFmpeg
*Я использовал версию 2.8, которая лежала у меня с незапамятных времен. Можно использовать версию старше.*

1. [http](https://github.com/FFmpeg/FFmpeg/archive/release/2.8.zip):
2. `git clone -b release/2.8 https://github.com/FFmpeg/FFmpeg.git`

### x264

1. [ftp](ftp://ftp.videolan.org/pub/x264/snapshots/last_x264.tar.bz2)
2. `git clone http://git.videolan.org/git/x264.git`

## Cборка x264
Первым делом собираем libx264. Если не требуется переходим сразу к сборке [FFmpeg](#ffmpeg)

### Windows
1. Ставим VS Studio [2015](https://www.visualstudio.com/ru/vs/older-downloads/) или выше. Минимальная версия [VS2013 u2](https://stackoverflow.com/questions/23099999/windows-how-to-build-x264-lib-instead-of-dll){:target="_blank"}.
2. Ставим [MSYS2](https://www.msys2.org/){:target="_blank"}.
3. Открываем консоль разработчика. **Пуск/Visual Studio (Version)/Developer Command Promt**. В ней будут доступны пути до компилятора и компоновщика.
4. Из открытой консоли открываем консоль MSYS2. 
- `C:\msys64\msys2_shell.cmd -mingw64 -full-path`
- mingw32 или mingw64 в зависимости от архитектуры
- full-path - позволяет увидеть путь до компилятора (можно раскомментировать строчку set MSYS2_PATH_TYPE=inherit в msys2_shell.cmd)

5. Переходим в папку с исходниками libx264.
6. ```bash
CC=cl ./configure --enable-static --prefix=${PWD}/installed
make
make install
```

### iOS

1. Переходим в папку с исходниками libx264. Это будет корень **LIBX264_ROOT**.
2. Сборка будет происходить в папке **[LIBX264_ROOT]/Projects/iOS/**. Создаем папку `mkdir -p Projects/iOS`.
3. Переходим в папку проекта.
4. Создаем [build_x264.sh](#264ios). Копируем в него скрипт.
5. Запускаем сборку библиотек: `sh ./build_x264.sh`.
6. Файлы будут лежать в **[LIBX264_ROOT]/Projects/iOS/Temp**.
7. Запускаем сборку [FAT-либок](https://en.wikipedia.org/wiki/Universal_binary){:target="_blank"}. `sh ./build_x264.sh lipo`
8. FAT-либка будут лежать в **[LIBX264_ROOT]/lib/ios**.

<a name="264ios"></a>
{% spoilerblock build_x264.sh %}
#!/bin/sh

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli"

ARCHS="arm64 armv7 armv7s" #x86_64 i386

# folders
CWD=$(pwd)
TEMP_DIR=$CWD/Temp
mkdir -p $TEMP_DIR
# Go to ROOT
cd ../..
WORK_DIR=$(pwd)
# output dir
FAT=$WORK_DIR/lib/ios
mkdir -p $FAT

COMPILE="y"
LIPO="y"

#echo "temp dir=$TEMP_DIR"
#echo "work dir=$WORK_DIR"

# make this files executable
chmod +x $WORK_DIR/version.sh
chmod +x $WORK_DIR/tools/gas-preprocessor.pl
chmod +x $WORK_DIR/config.sub
chmod +x $WORK_DIR/config.guess

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then
    #CWD=$PWD
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$TEMP_DIR/$ARCH"
        
        CFLAGS="-arch $ARCH"
        ASFLAGS=

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CPU=
            if [ "$ARCH" = "x86_64" ]
            then
                CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
                HOST=
            else
                CFLAGS="$CFLAGS -mios-simulator-version-min=5.0"
            HOST="--host=i386-apple-darwin"
            fi
        else
            PLATFORM="iPhoneOS"
            if [ $ARCH = "arm64" ]
            then
                HOST="--host=aarch64-apple-darwin"
            XARCH="-arch aarch64"
            else
                HOST="--host=arm-apple-darwin"
            XARCH="-arch arm"
            fi
            CFLAGS="$CFLAGS -fembed-bitcode -mios-version-min=7.0"
            ASFLAGS="$CFLAGS"
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"
        if [ $PLATFORM = "iPhoneOS" ]
        then
            export AS="$WORK_DIR/tools/gas-preprocessor.pl $XARCH -- $CC"
        else
            export -n AS
        fi
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"

        CC=$CC ./configure \
            $CONFIGURE_FLAGS \
            $HOST \
            --extra-cflags="$CFLAGS" \
            --extra-asflags="$ASFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$TEMP_DIR/$ARCH" || exit 1

        make clean
        make -j3 install || exit 1

    done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    
    set - $ARCHS
    THIN=$TEMP_DIR
    echo "$THIN"

    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $WORK_DIR
        echo lipo -create `find $THIN -name $LIB` -output $FAT/$LIB 1>&2
        lipo -create `find $THIN -name $LIB` -output $FAT/$LIB
    done

    cd $WORK_DIR
    #cp -rf $THIN/$1/include $WORK_DIR
fi
{% endspoilerblock %}
<br>

### OSX
1. Алгоритм сборки для OSX совпадает с iOS. Немного отличается скрипт и рабочая папка **[LIBX264_ROOT]/Projects/OSX/**
2. На моей машине для i386 сразу создавалась FAT-либка. Я просто копировал ее в **[LIBX264_ROOT]/lib/osx/**

<a name="264osx"></a>
{% spoilerblock build_x264.sh %}
#!/bin/sh

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli --disable-asm"

ARCHS="x86_64 i386" #

# directiries
CWD=$(pwd)
TEMP_DIR=$CWD/Temp
mkdir -p $TEMP_DIR
cd ../..
WORK_DIR=$(pwd)
FAT=$WORK_DIR/lib/osx
mkdir -p $FAT

COMPILE="y"
LIPO="y"

echo "temp dir=$TEMP_DIR"
echo "work dir=$WORK_DIR"

chmod +x $WORK_DIR/version.sh
chmod +x $WORK_DIR/tools/gas-preprocessor.pl
chmod +x $WORK_DIR/config.sub
chmod +x $WORK_DIR/config.guess

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then
    #CWD=$PWD
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$TEMP_DIR/$ARCH"
        
        CFLAGS="-arch $ARCH"
        ASFLAGS=
        
        PLATFORM="macosx"
        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"
        
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"

        CC=$CC ./configure \
            $CONFIGURE_FLAGS \
            $HOST \
            --extra-cflags="$CFLAGS" \
            --extra-asflags="$ASFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$TEMP_DIR/$ARCH" || exit 1

        make clean
        make -j3 install || exit 1

    done
fi

# TODO i386 makes fat lib. need only cp Temp/i386/lib/*.a $WORK_DIR/lib/osx
if [ "$LIPO" ]
then
    echo "building fat binaries..."
    cp Temp/i386/lib/*.a $WORK_DIR/lib/osx

    #set - $ARCHS
    #THIN=$TEMP_DIR
    #echo "$THIN"

    #cd $THIN/$1/lib
    #for LIB in *.a
    #do
    #    cd $WORK_DIR
    #    echo lipo -create `find $THIN -name $LIB` -output $FAT/$LIB 1>&2
    #    lipo -create `find $THIN -name $LIB` -output $FAT/$LIB
    #done

    #cd $WORK_DIR
    #cp -rf $THIN/$1/include $WORK_DIR
fi
{% endspoilerblock %}
<br>

### Android
1. 

<a name="264android"></a>
{% spoilerblock build_x264.sh %}
#!/bin/sh

# start cygwin
# cd /cygdrive/{disk letter}/{path to x264}/Projects/Android
# ./{this file}

NDK=C:/Users/UserName/AppData/Local/Android/sdk/ndk-bundle
SYSROOT=$NDK/platforms/android-16/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64

ARCH=armeabi-v7a
WORK_DIR=$(pwd)
TEMP_DIR=$WORK_DIR/temp
ROOT_DIR=$WORK_DIR/../..
PREFIX=$TEMP_DIR/$ARCH

delete()
{
   echo "================== Deleting libs"
   rm ./lib/android/*.a
}

copy_libs()
{
   echo "================== Copy libs"
   OUT_DIR=$ROOT_DIR/lib/android/$ARCH
   mkdir -p $OUT_DIR
   cp $PREFIX/lib/*.a $OUT_DIR
}

build_armv7()
{
   ./configure \
    --prefix=$PREFIX \
    --enable-static \
    --enable-pic \
    --host=arm-linux \
    --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
    --sysroot=$SYSROOT
	
    make clean
	make
	make install
}

cd ../..

echo $(pwd)

build_armv7
copy_libs 
{% endspoilerblock %}
<br>

<a name="ffmpeg"></a>
## Cборка FFmpeg

### Windows

### iOS

### OSX

### Android

## Ссылки
1. [FFmpeg](https://ffmpeg.org/){:target="_blank"}
2. [VS build FFmpeg](https://blogs.gnome.org/rbultje/2012/09/27/microsoft-visual-studio-support-in-ffmpeg-and-libav/){:target="_blank"}
3. [build ios script](https://github.com/kewlbear/x264-ios){:target="_blank"}