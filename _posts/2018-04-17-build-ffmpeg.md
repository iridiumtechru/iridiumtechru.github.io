---
layout: post
published: true
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
Первым делом собираем libx264. Если не требуется переходим сразу к сборке [FFmpeg](#ffmpegbuild)

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
<details>
<summary>
<code><strong style="color:#a83232">build_x264.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
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
</code></pre></div></div>
</details>
<br>

### OSX
1. Алгоритм сборки для OSX совпадает с iOS. Немного отличается скрипт и рабочая папка **[LIBX264_ROOT]/Projects/OSX/**
2. На моей машине для i386 сразу создавалась FAT-либка. Я просто копировал ее в **[LIBX264_ROOT]/lib/osx/**

<a name="264osx"></a>
<details>
<summary>
<code><strong style="color:#a83232">build_x264.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
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
</code></pre></div></div>
</details>
<br>

### Android
1. Ставим [Cygwin](https://www.cygwin.com/){:target="_blank"} (~~Mingw,MSYS2~~).
2. Ставим [Android NDK](https://developer.android.com/ndk/guides/){:target="_blank"}. Раньше качался отдельно, сейчас только через SDK Manager в Android Studio.
3. Открываем консоль Cygwin.
4. Переходим в папку с исходниками `cd /cygdrive/{disk letter}/{path to x264}/`.
5. Создаем папку `mkdir -p Projects/Android`.
6. `cd Projects/Android`
7. Создаем [build_x264.sh](#264android). Копируем в него скрипт.
8. Правим переменные *NDK, SYSROOT, TOOLCHAIN, ARCH*.
9. Запускаем сборку библиотек: `sh ./build_x264.sh`.

<a name="264android"></a>
<details>
<summary>
<code><strong style="color:#a83232">build_x264.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
#!/bin/sh

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
</code></pre></div></div>
</details>
<br>

<a name="ffmpegbuild"></a>
## Cборка FFmpeg

### Windows
1. Ставим VS Studio [2015](https://www.visualstudio.com/ru/vs/older-downloads/) или выше. Минимальная версия [VS2013 u2](https://stackoverflow.com/questions/23099999/windows-how-to-build-x264-lib-instead-of-dll){:target="_blank"}.
2. Ставим [MSYS2](https://www.msys2.org/){:target="_blank"}.
3. Открываем консоль разработчика. **Пуск/Visual Studio (Version)/Developer Command Promt**. В ней будут доступны пути до компилятора и компоновщика.
4. Из открытой консоли открываем консоль MSYS2. 
- `C:\msys64\msys2_shell.cmd -mingw64 -full-path`
- mingw32 или mingw64 в зависимости от архитектуры
- full-path - позволяет увидеть путь до компилятора (можно раскомментировать строчку set MSYS2_PATH_TYPE=inherit в msys2_shell.cmd)

5. Переходим в папку с исходниками ffmpeg.
6. ```bash
./configure --toolchain=msvc --disable-shared --disable-doc --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-ffserver 
    --disable-avdevice --disable-symver --enable-libx264 --enable-gpl --prefix=${PWD}/installed
    --extra-cflags="-IC:\\x264\\installed\\include"
    --extra-ldflags="-LC:\\x264\\installed\\lib"
```
    - **--disable-shared** - статические библиотеки, **--disable-static** - динамические.
    - **--disable-asm** - если будет ругаться на ассемблерные вставки. Я собирал без него на vs2015. Если использовать vs2010, то придется потанцевать с yasm(nasm), [c99conv, c99wrap](https://blogs.gnome.org/rbultje/2012/09/27/microsoft-visual-studio-support-in-ffmpeg-and-libav/){:target="_blank"}. 
    - **--arch=x86_64** - если требуется собрать x64 архитектуру. Должен быть MSYS64 и libx264 с x64 архитектурой.
    - **--prefix** - укажет папку куда выполнится **make install**.
    - **--extra-ldflags** - не работает на win7. ругается на линковку **libx264.a**. Нужно перенести libx264 в корень ffmpeg, либо в temp папку, которую создает **configure** в корне при выполнении.

7. ```bash
make
make install
```
    - если не использовать **--prefix** собраные либы будут лежать в подпапках рядом с исходниками.

### iOS

1. Переходим в папку с исходниками ffmpeg. Это будет корень **FFMPEG_ROOT**.
2. Сборка будет происходить в папке **[FFMPEG_ROOT]/Projects/iOS/**. Создаем папку `mkdir -p Projects/iOS`.
3. Переходим в папку проекта.
4. Создаем [build_ffmpeg.sh](#ffmpegios). Копируем в него скрипт.
5. Правим пути до libx264 (если требуется).
6. Запускаем сборку библиотек: `sh ./build_ffmpeg.sh`.
7. Файлы будут лежать в **[FFMPEG_ROOT]/Projects/iOS/Temp**.
8. Запускаем сборку [FAT-либок](https://en.wikipedia.org/wiki/Universal_binary){:target="_blank"}. `sh ./build_ffmpeg.sh lipo`
9. FAT-либка будут лежать в **[build_ffmpeg]/lib/ios**.

<a name="ffmpegios"></a>
<details>
<summary>
<code><strong style="color:#a83232">build_ffmpeg.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
#!/bin/sh

# ffmpeg_build.sh

FFMPEG_SOURCE=ffmpeg-2.8
ARCHS="arm64 armv7s armv7" #x86_64 i386

CONFIGURE_FLAGS="--enable-cross-compile\
                 --disable-debug\
                 --disable-programs \
                 --disable-doc\
                 --disable-bzlib \
                 --enable-pic"

# folders
CWD=$(pwd)
TEMP_DIR=$CWD/Temp
mkdir -p $TEMP_DIR
cd ../..
WORK_DIR=$(pwd)
FAT=$WORK_DIR/lib/ios
mkdir -p $FAT

chmod +x ./configure
chmod +x ./version.sh

# absolute path to x264 library
X264="$WORK_DIR/../x264/Project/iOS/Temp"

echo "temp dir=$TEMP_DIR"
echo "work dir=$WORK_DIR"
echo "x264 dir=$X264"

if [ "$X264" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

#echo "$CONFIGURE_FLAGS"

COMPILE="y"
LIPO="y"
DEPLOYMENT_TARGET="7.0"

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
    # install dependences
    if [ ! `which yasm` ]
    then
        echo 'Yasm not found'
        if [ ! `which brew` ]
        then
            echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
                || exit 1
        fi
        echo 'Trying to install Yasm...'
        brew install yasm || exit 1
    fi
    if [ ! `which gas-preprocessor.pl` ]
    then
        echo 'gas-preprocessor.pl not found. Trying to install...'
        (curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
            -o /usr/local/bin/gas-preprocessor.pl \
            && chmod +x /usr/local/bin/gas-preprocessor.pl) \
            || exit 1
    fi

    # arch loop
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$TEMP_DIR/$ARCH"
        #cd "$TEMP_DIR/$ARCH"

        CFLAGS="-arch $ARCH"
        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
        else
            PLATFORM="iPhoneOS"
            CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
            if [ "$ARCH" = "arm64" ]
            then
                EXPORT="GASPP_FIX_XCODE5=1"
            fi
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"

        # force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
        if [ "$ARCH" = "arm64" ]
        then
            AS="gas-preprocessor.pl -arch aarch64 -- $CC"
        else
            AS="$CC"
        fi

        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"
        if [ "$X264" ]
        then
            CFLAGS="$CFLAGS -I$X264/$ARCH/include"
            LDFLAGS="$LDFLAGS -L$X264/$ARCH/lib"
        fi
        if [ "$FDK_AAC" ]
        then
            CFLAGS="$CFLAGS -I$FDK_AAC/include"
            LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
        fi

        # build
        ./configure \
            --target-os=darwin \
            --arch=$ARCH \
            --cc="$CC" \
            --as="$AS" \
            $CONFIGURE_FLAGS \
            --extra-cflags="$CFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$TEMP_DIR/$ARCH" \
        || exit 1

        make clean
        make -j3 install || exit 1
        
    done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    #mkdir -p $FAT
    set - $ARCHS
    #CWD=`pwd`
    #cd $THIN/$1/lib
    #echo "==== $1"
    THIN=$TEMP_DIR

    echo "$THIN"
    cd $THIN/$1/lib/
    for LIB in *.a
    do
        cd $WORK_DIR
        
        echo lipo -create `find $THIN -name $LIB` -output $FAT/$LIB 1>&2
        lipo -create `find $THIN -name $LIB` -output $FAT/$LIB || exit 1
    done

    cd $WORK_DIR
    cp -rf $THIN/$1/include $WORK_DIR
fi
</code></pre></div></div>
</details>
<br>

### OSX
1. Переходим в папку с исходниками ffmpeg. Это будет корень **FFMPEG_ROOT**.
2. Сборка будет происходить в папке **[FFMPEG_ROOT]/Projects/OSX/**. Создаем папку `mkdir -p Projects/OSX`.
3. Переходим в папку проекта.
4. Создаем [build_ffmpeg.sh](#ffmpegosx). Копируем в него скрипт.
5. Правим пути до libx264 (если требуется).
6. Запускаем сборку библиотек: `sh ./build_ffmpeg.sh`.
7. Файлы будут лежать в **[FFMPEG_ROOT]/Projects/OSX/Temp**.
8. Запускаем сборку [FAT-либок](https://en.wikipedia.org/wiki/Universal_binary){:target="_blank"}. `sh ./build_ffmpeg.sh lipo`
9. FAT-либка будут лежать в **[build_ffmpeg]/lib/osx**.

<a name="ffmpegosx"></a>
<details>
<summary>
<code><strong style="color:#a83232">build_ffmpeg.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
#!/bin/sh

FFMPEG_SOURCE=ffmpeg-2.8
ARCHS="x86_64 i386" #

CONFIGURE_FLAGS="--enable-cross-compile\
                 --disable-debug\
                 --disable-programs \
                 --disable-doc\
                 --disable-bzlib \
                 --disable-asm \
                 --disable-vda \
                 --enable-pic"

# folders
CWD=$(pwd)
TEMP_DIR=$CWD/Temp
mkdir -p $TEMP_DIR
cd ../..
WORK_DIR=$(pwd)
FAT=$WORK_DIR/lib/osx
mkdir -p $FAT

chmod +x ./configure
chmod +x ./version.sh

# absolute path to x264 library
X264="$WORK_DIR/../x264/Project/OSX/Temp"

echo "temp dir=$TEMP_DIR"
echo "work dir=$WORK_DIR"
echo "x264 dir=$X264"

if [ "$X264" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

#echo "$CONFIGURE_FLAGS"

COMPILE="y"
LIPO="y"
DEPLOYMENT_TARGET="7.0"

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
    # install dependences
    if [ ! `which yasm` ]
    then
        echo 'Yasm not found'
        if [ ! `which brew` ]
        then
            echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
                || exit 1
        fi
        echo 'Trying to install Yasm...'
        brew install yasm || exit 1
    fi
    if [ ! `which gas-preprocessor.pl` ]
    then
        echo 'gas-preprocessor.pl not found. Trying to install...'
        (curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
            -o /usr/local/bin/gas-preprocessor.pl \
            && chmod +x /usr/local/bin/gas-preprocessor.pl) \
            || exit 1
    fi

    # arch loop
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$TEMP_DIR/$ARCH"

        CFLAGS="-arch $ARCH"
        PLATFORM="macosx"
        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"

        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"
        if [ "$X264" ]
        then
            CFLAGS="$CFLAGS -I$X264/$ARCH/include"
            LDFLAGS="$LDFLAGS -L$X264/$ARCH/lib"
        fi
        if [ "$FDK_AAC" ]
        then
            CFLAGS="$CFLAGS -I$FDK_AAC/include"
            LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
        fi

        # 
        ./configure \
            --target-os=darwin \
            --arch=$ARCH \
            --cc="$CC" \
            --as="$AS" \
            $CONFIGURE_FLAGS \
            --extra-cflags="$CFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$TEMP_DIR/$ARCH" \
        || exit 1

        make clean
        make -j3 install || exit 1
        
    done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    #mkdir -p $FAT
    set - $ARCHS
    THIN=$TEMP_DIR

    echo "$THIN"
    cd $THIN/$1/lib/
    for LIB in *.a
    do
        cd $WORK_DIR
        
        echo lipo -create `find $THIN -name $LIB` -output $FAT/$LIB 1>&2
        lipo -create `find $THIN -name $LIB` -output $FAT/$LIB || exit 1
    done

    cd $WORK_DIR
    cp -rf $THIN/$1/include $WORK_DIR
fi
</code></pre></div></div>
</details>
<br>

### Android
1. Ставим [Cygwin](https://www.cygwin.com/){:target="_blank"} (~~Mingw,MSYS2~~).
2. Ставим [Android NDK](https://developer.android.com/ndk/guides/){:target="_blank"}. ~~Раньше качался отдельно, сейчас только через SDK Manager в Android Studio.~~
3. Открываем консоль Cygwin.
4. Переходим в папку с исходниками `cd /cygdrive/{disk letter}/{path to ffmpeg}/`.
5. Создаем папку `mkdir -p Projects/Android`.
6. `cd Projects/Android`
7. Создаем [build_ffmpeg.sh](#ffmpegandroid). Копируем в него скрипт.
8. Правим переменные *NDK, SYSROOT, TOOLCHAIN, ARCH*.
9. Запускаем сборку библиотек: `sh ./build_ffmpeg.sh`.

<a name="ffmpegandroid"></a>
<details>
<summary>
<code><strong style="color:#a83232">build_ffmpeg.sh</strong></code>
</summary>
<div class="language-bash highlighter-rouge">
<div class="highlight">
<pre class="highlight"><code>
#!/bin/sh

FFMPEG_SOURCE=ffmpeg-2.8

# start cygwin
# cd /cygdrive/{disk letter}/{path to iridium}/libs/$FFMPEG_SOURCE/Projects/Android
# ./{this file}

NDK=C:/Users/UserName/AppData/Local/Android/sdk/ndk-bundle
SYSROOT=$NDK/platforms/android-16/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64

ARCH=armv7-a
FARCH=armeabi-v7a
WORK_DIR=$(pwd)
#TEMP_DIR=$WORK_DIR/temp
TEMP_DIR=D:/Work/iridium/trunk/Android/libs/ffmpeg-2.8/Projects/Android/temp
ROOT_DIR=$WORK_DIR/../..
PREFIX=$TEMP_DIR/$FARCH

export TMPDIR=D:/tmp

X264_DIR=D:/Work/iridium/trunk/Android/libs/x264/Projects/Android/temp/armeabi-v7a
X264_CFLAGS="-I$X264_DIR/include"
X264_LDFLAGS="-L$X264_DIR/lib"

delete()
{
   echo "================== Deleting libs"
   rm ./lib/android/*.a
}

copy_libs()
{
   echo "================== Copy libs"
   #cp lib/osx/x86_32/usr/local/lib/*.a lib/android
   OUT_DIR=$ROOT_DIR/lib/android/$FARCH
   mkdir -p $OUT_DIR
   cp $PREFIX/lib/*.a $OUT_DIR
}

build_armv7()
{
   ./configure \
    --prefix=$PREFIX \
    --enable-static \
    --disable-shared \
    --disable-doc \
    --disable-programs \
    --disable-avdevice \
    --disable-bzlib \
    --disable-doc \
    --disable-symver \
    --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
    --target-os=linux \
    --arch=arm \
    --cpu=cortex-a8 \
    --enable-cross-compile \
    --sysroot=$SYSROOT \
    --enable-gpl \
    --enable-libx264 \
    --extra-cflags="-Os -fpic -march=$ARCH -mfloat-abi=softfp -mfpu=vfpv3 -marm $X264_CFLAGS" \
    --extra-ldflags="$X264_LDFLAGS" \
    $ADDITIONAL_CONFIGURE_FLAG || exit 1
	
    make clean
	make
	make install
}

cd ../..

build_armv7
</code></pre></div></div>
</details>
<br>
## Ссылки
1. [FFmpeg](https://ffmpeg.org/){:target="_blank"}
2. [VS build FFmpeg](https://blogs.gnome.org/rbultje/2012/09/27/microsoft-visual-studio-support-in-ffmpeg-and-libav/){:target="_blank"}
3. [build ios script](https://github.com/kewlbear/x264-ios){:target="_blank"}

---
<div class="scroller">
<script id="journalist-broadcast-1576506797" async src="https://journali.st/broadcasts/1576506797-widget-10.js"></script>
</div>
---
<p class="center" align="center"><a href="https://t.me/joinchat/CgpznA9h0V7BY1E6JbKJMA" target="_blank">Оставить комментарий через Telegram</a></p>