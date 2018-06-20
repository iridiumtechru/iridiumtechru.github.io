---
layout: post
published: false
title: Реализация видео в VoIP приложении с использованием ffmpeg
---

Использование видео кодеков ffmpeg на С++.

## Зачем?
Обычно в SIP софтфонах используются специализированые библиотеки (pjsip, linphone), но я когдато принял решение делать самостоятельную реализацию и однажды пришло время передавать видео.

### Инициализация кодеков

* Подключим заголовки

```cpp
extern "C" {
#ifndef __STDC_CONSTANT_MACROS
#define __STDC_CONSTANT_MACROS
#endif
#include <stdint.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavformat/rtpdec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
#include "libavutil/opt.h"
}
```

* Функция открытия кодека

```cpp
int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, AVDictionary **options);
```

>avctx - контекст кодека. Создается для кодера и под декодера отдельно.
>
>codec - кодер или декордер. ищется в списке поддерживаемых.
>
>options - опции для инициализации контекста.

- Создание декодера

```cpp
AVCodec* decoder = avcodec_find_decoder(AV_CODEC_ID_H264);
AVCodecContext* context = avcodec_alloc_context3(decoder);
avcodec_open2(context, decoder, NULL);
```

- Сразу все работать не будет нужно указать параметры контексту.

```cpp
/**
   Context init
*/
void InitContext(AVCodecContext** out_context_ptr, AVCodec* in_codec, int bitrate, int width, int height)
{
   AVCodecContext* context = avcodec_alloc_context3(in_codec);

   l_pContext->codec_type = AVMEDIA_TYPE_VIDEO;
   l_pContext->codec_id = in_pCodec->id;

   l_pContext->bit_rate = bitrate; // default bitrate = 90000

   l_pContext->strict_std_compliance = FF_COMPLIANCE_UNOFFICIAL;
   l_pContext->workaround_bugs = FF_BUG_AUTODETECT;

   l_pContext->pix_fmt = AV_PIX_FMT_YUV420P;

   // 176 × 144, 352 × 288, 704 × 288, 704 × 576, 1408 × 1152
   l_pContext->width     = width;
   l_pContext->height    = height;

   *in_pCodecContext = l_pContext;
}

AVCodec* decoder = avcodec_find_decoder(AV_CODEC_ID_H264);

if(!decoder)
    return false;

AVCodecContext* context = NULL;
InitContext(&context, decoder, 90000, 352, 288);
if(context && (avcodec_open2(context, decoder, NULL) < 0)
    return true;// initalize ok
```
> FF_COMPLIANCE_UNOFFICIAL - позволяет кодерам генерировать нестандартные данные (не по стандарту).

> FF_BUG_AUTODETECT - позволяет автоматически искать ошибки в данных.

> bit_rate - [битрейт](https://ru.wikipedia.org/wiki/Битрейт){:target="_blank"} задается приблизительно если он динамический (vbr) или жестко если постоянный (cbr). Битрейт определяется кодером.


### Декодирование пакета

### Кодирование пакета

## Выводы

## Ссылки