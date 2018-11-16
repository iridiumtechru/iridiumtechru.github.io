---
layout: post
published: true
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
>codec - энкодер или декордер. ищется в списке поддерживаемых.
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
> FF_COMPLIANCE_UNOFFICIAL - позволяет энкодерам генерировать данные не по стандарту.

> FF_BUG_AUTODETECT - позволяет автоматически искать ошибки в данных.

> bit_rate - [битрейт](https://ru.wikipedia.org/wiki/Битрейт){:target="_blank"} задается приблизительно, если он динамический (vbr), или жестко, если постоянный (cbr). Битрейт определяется энкодерам.

- Создание rtp демуксера.

Можно разбирать rtp пакеты самому, но я использовал встроенные функции.

```cpp
    AVStream* st = (AVStream*)av_mallocz(sizeof(AVStream));
    st->start_time = AV_NOPTS_VALUE;
    st->duration = AV_NOPTS_VALUE;
    st->index = 0;
    st->codec = decoder_context;

    // демуксер RTP пакетов
    rtp_demuxer = ff_rtp_parse_open(NULL, st, payload_type, 0);

    // поиск хендлера
    const char* handler_name = "";
    switch(l_eCID)
    {
    case AV_CODEC_ID_H263P:
    {
        handler_name = "H263-1998";
        rtp_demuxer->handler = ff_rtp_handler_find_by_name(handler_name, AVMEDIA_TYPE_VIDEO);
        break;
    }
    case AV_CODEC_ID_H264:
    {
        handler_name = "H264";
        rtp_demuxer->handler = ff_rtp_handler_find_by_name(handler_name, AVMEDIA_TYPE_VIDEO);
        break;
    }
```

### Декодирование пакета

Пакеты сохраняются в массив и обрабатываются в главном потоке.

```cpp
for(int i = 0; i < packets.size(); i++)
{
    int got_frame  = 0;
    raw_rtp_packet_t* rtp_packet = packets.at(i);

    AVPacket packet;
    memset(&packet, 0, sizeof(packet));
    av_init_packet(&packet);

    // парсим rtp пакет
    if(m_rtp_demuxer && -1 != ff_rtp_parse_packet(rtp_demuxer, &packet, &rtp_packet->data, rtp_packet->size))
    {
        // проверим изменения метки времени. и обработаем данные уже помещенные в буфер
         if(last_ts && rtp_demuxer->timestamp != last_ts)
         {
            AVPacket frame_packet;
            memset(&frame_packet, 0, sizeof(AVPacket));
            av_init_packet(&frame_packet);

            frame_packet.data = m_jitter_buf->GetDataPtr();
            frame_packet.size = m_jitter_buf->Size();
            
            int decoded_data_size = avcodec_decode_video2(m_decoder_context, m_frame, &got_frame, &frame_packet);
            
            // пробуем декодировать фрейм
            if(m_frame && 0 < decoded_data_size)
            {
               if(got_frame)
               {
                   // обработка изображения
                   // ...
                   //sws_scale(m_pSWSContext, m_pFrame->data, m_pFrame->linesize, 0, m_decoder_context->height, l_aSource, l_aStride);
               }
            }

            av_frame_unref(m_frame);
            av_free_packet(&frame_packet);
            m_jitter_buffer->Clear();           // очищаем буфер
         }

         if(m_rtp_demuxer->seq != m_last_ts + 1)
            printf("Packets is mixed %d %d", m_rtp_demuxer->seq, m_last_seq);
         m_last_seq = m_pRTPDemuxer->seq;

         // один фрейм может состоять из нескольких пакетов. добавим пакет в буфер 
         m_jitter_buffer->Add(packet.data, packet.size);
         // сохраняем timestamp
         m_last_ts = rtp_demuxer->timestamp;
      }

      av_free_packet(&packet);
    }
}
```

### Кодирование пакета

Изображения приходят в "сыром" виде с камеры или другого устройства. Вероятно в отдельном потоке.

```cpp
#define RTP_VIDEO_PAYLOAD_SIZE   1368 // MTU
#define FPS 25

void SendFrame(unsigned int in_u32Width, unsigned int in_u32Height, unsigned int in_u32Pitch, void* in_pBuffer)
{
    m_lock->Lock();
    av_image_alloc(m_packet_frame->data, m_packet_frame->linesize, m_encoder_context->width, m_encoder_context->height, m_encoder_context->pix_fmt, 32);

    AVFrame* picture_frame = av_frame_alloc();

    // заполняем фрейм пришедшими данными
    avpicture_fill((AVPicture*)picture_frame, (u8*)in_pBuffer, l_eFmt, in_u32Width, in_u32Height);
    picture_frame->width = m_encoder_context->width;
    picture_frame->height = m_encoder_context->height;
    picture_frame->format = l_eFmt;

    // скалирование изображения под формат передачи
    sws_scale(m_pSWSContext2, picture_frame->data, picture_frame->linesize, 0, in_u32Height, m_packet_frame->data, m_packet_frame->linesize);

    m_packet_frame->width = m_decoder_width;
    m_packet_frame->height = m_decoder_height;
    m_packet_frame->format = AV_PIX_FMT_YUV420P;
    m_packet_frame->pts = m_encoder_pts++;        // инкрементируем счетчик кадров

    AVPacket packet;
    av_init_packet(&packet);
    packet.data = NULL;
    packet.size = 0;

    int got_packet = 0;
    int l_s32Encoded = avcodec_encode_video2(m_encoder_context, &packet, m_packet_frame, &got_packet);
    if(0 < l_s32Encoded)
    {
        if(got_packet)
        {
            int whole_size = packet.size;                       // размер всего фрейма
            unsigned int delta_ts = m_bitrate / FPS;            // время между кадрами
            unsigned char* marker = 0;                          // конец пакета для rtp
            unsigned char* data = (unsigned char*)packet.data;  // указатель на данные фрейма
            u8* end = data + whole_size;                        // указатель на конец данных фрейма

            u8 packet_buf[RTP_VIDEO_PAYLOAD_SIZE * 2];          // буфер для одного пакета
            memset(packet_buf, 0 , sizeof(packet_buf));
            size_t size = 0;                                    // размер данных помещенных в буфер пакетизатором
            size_t shift = 0;                                   // смещение в буфере фрейма до следующего пакета

            do
            {
                if(m_encoder_context->codec_id == AV_CODEC_ID_H263)
                    shift = h263_rfc2190_packetization(data, whole_size, packet_buf, &size);
                else if(m_encoder_context->codec_id == AV_CODEC_ID_H263P)
                    shift = h263_rfc4629_packetization(data, whole_size, packet_buf, &size);
                else if(m_encoder_context->codec_id == AV_CODEC_ID_H264)
                    shift = h264_rfc6185_packetization(data, whole_size, packet_buf, &size);
                else
                    break;

                // если пакет последний в последовательности
                marker = (whole_size == shift) ? 1 : 0;

                if(size)
                {
                    // отправляем пакет по rtp
                    // ...
                    // m_device->SendVideoPacket(packet_buf, size, marker, delta_ts);
                }

                if(!shift)
                {
                    printf("Bad shift size");
                    shift = whole_size;
                }

                delta_ts = 0;       // все последующие пакеты этого фрейма идут с тем же timestamp
                data += shift;
                whole_size = end - data;
            } while(whole_size > 0);

            av_free_packet(&packet);
        }
    }

    av_freep(&m_packet_frame->data[0]);
    av_frame_unref(m_packet_frame);
    av_frame_free(&picture_frame);
    m_lock->UnLock();
}

```

- Пакетизаторы были честно выдраны из pjsip и адаптированы под себя.

```cpp
size_t h263_rfc2190_packetization(unsigned char* data_buf, size_t buf_size, unsigned char* out_data, size_t* out_size)
{
   size_t size = (buf_size < RTP_VIDEO_PAYLOAD_SIZE) ? buf_size : RTP_VIDEO_PAYLOAD_SIZE;

   out_data[0] = 0x00;
   out_data[1] = 0x70;
   out_data[2] = 0x00;
   out_data[3] = 0x00;

   memcpy(out_data + 4, data_buf, size);
   *out_size = size + 4;

   return size;
}
```

```cpp
size_t h263_rfc4629_packetization(unsigned char* data_buf, size_t buf_size, unsigned char* out_data, size_t* out_size)
{
   size_t size = (buf_size < RTP_VIDEO_PAYLOAD_SIZE) ? buf_size : RTP_VIDEO_PAYLOAD_SIZE;

   if(data_buf[0] == 0x00 && data_buf[1] == 0x00)
   {
      memcpy(out_data, data_buf, size);
      out_data[0] = 0x04;
      *out_size = size;
   }
   else
   {
      out_data[0] = 0x00;
      out_data[1] = 0x00;

      memcpy(out_data + 2, data_buf, size);
      *out_size = size + 2;
   }

   return size;
}
```

```cpp
#define TYPE_FU_A             0x1C        // код FU-A заголовка для h264 пакетизатора
#define TYPE_STAP_A           0x18        // код STAP-A заголовка для h264 пакетизатора
#define HEADER_SIZE_FU_A      2           // размер FU-A заголовка
#define HEADER_SIZE_STAP_A    3           // размер STAP-A заголовка
#define MAX_NALS_IN_AGGR      32          // максимальное количество NAL заголовков в пакете

static u8* find_next_nal_unit(u8* start, u8* end)
{
   u8 *p = start;

   // Simply lookup "0x000001" pattern
   while(p <= end - 3 && (p[0] || p[1] || p[2] != 1))
      ++p;

   if(p > end - 3)
      // No more NAL unit in this bitstream
      return NULL;

   // Include 8 bits leading zero
   if(p > start && *(p - 1) == 0)
      return (p - 1);

   return p;
}

size_t h264_rfc6185_packetization(unsigned char* data_buf, size_t buf_size, unsigned char* out_data, size_t* out_size)
{
   u8* p = data_buf;
   u8* nal_octet = NULL;
   u8* nal_start = NULL;
   u8* nal_end = NULL;
   u8* end = data_buf + buf_size;

   u8 NRI, TYPE;
   u32 l_u32Size = 0;

   unsigned int nal_cnt = 0;

   if(buf_size > 4)
      nal_start = find_next_nal_unit(p, p + 4);
   if(nal_start)
   {
      // Get NAL unit octet pointer
      while(*nal_start++ == 0);
      nal_octet = nal_start;
   }
   else
      nal_start = p; // This NAL unit is being fragmented

   // Get end of NAL unit
   p = nal_start + RTP_VIDEO_PAYLOAD_SIZE + 1;
   if(p > end)
      p = end;

   nal_end = find_next_nal_unit(nal_start, p);
   if(!nal_end)
      nal_end = p;

   if(!nal_octet || nal_end - nal_start > RTP_VIDEO_PAYLOAD_SIZE)
   {
      if(nal_octet)
      {
         // We have NAL unit octet, so this is the first fragment
         NRI = (*nal_octet & 0x60) >> 5;
         TYPE = *nal_octet & 0x1F;

         // Skip nal_octet in nal_start to be overriden by FU header
         ++nal_start;
      }
      else
      {
         // Not the first fragment, get NRI and NAL unit type from the previous fragment.
         p = nal_start - RTP_VIDEO_PAYLOAD_SIZE;
         NRI = (*p & 0x60) >> 5;
         TYPE = *(p + 1) & 0x1F;
      }

      p = nal_start - HEADER_SIZE_FU_A;
      *p = (NRI << 5) | TYPE_FU_A;
      ++p;
      *p = TYPE;

      l_u32Size = (nal_end - nal_start + HEADER_SIZE_FU_A);

      if(nal_octet)
         *p |= (1 << 7); // S bit flag = start of fragmentation
      if(l_u32Size <= RTP_VIDEO_PAYLOAD_SIZE)
         *p |= (1 << 6); // E bit flag = end of fragmentation

      l_u32Size = (l_u32Size > RTP_VIDEO_PAYLOAD_SIZE) ? RTP_VIDEO_PAYLOAD_SIZE : l_u32Size;
      memcpy(out_data, nal_start - HEADER_SIZE_FU_A, l_u32Size);
      *out_size = l_u32Size;

      return ((nal_start - HEADER_SIZE_FU_A) + l_u32Size) - data_buf;
   }
   else
   {
      if((nal_end != end) && (nal_end - nal_start + HEADER_SIZE_STAP_A) < RTP_VIDEO_PAYLOAD_SIZE)
      {
         int total_size;
         //unsigned int nal_cnt = 1;
         nal_cnt = 1;
         u8* nal[MAX_NALS_IN_AGGR];
         size_t nal_size[MAX_NALS_IN_AGGR];
         u8 NRI;

         // Init the first NAL unit in the packet
         nal[0] = nal_start;
         nal_size[0] = nal_end - nal_start;
         total_size = (int)nal_size[0] + HEADER_SIZE_STAP_A;
         NRI = (*nal_octet & 0x60) >> 5;

         while(nal_cnt < MAX_NALS_IN_AGGR) 
         {
            u8* tmp_end = NULL;

            // Find start address of the next NAL unit
            p = nal[nal_cnt - 1] + nal_size[nal_cnt - 1];
            while(*p++ == 0);
            nal[nal_cnt] = p;

            // Find end address of the next NAL unit
            tmp_end = p + (RTP_VIDEO_PAYLOAD_SIZE - total_size);
            if(tmp_end > end)
               tmp_end = end;
            p = find_next_nal_unit(p + 1, tmp_end);
            if(p)
               nal_size[nal_cnt] = p - nal[nal_cnt];
            else
               break;

            // Update total payload size (2 octet NAL size + NAL)
            total_size += (2 + (int)nal_size[nal_cnt]);
            if(total_size <= RTP_VIDEO_PAYLOAD_SIZE) 
            {
               u8 tmp_nri;

               // Get maximum NRI of the aggregated NAL units
               tmp_nri = (*(nal[nal_cnt] - 1) & 0x60) >> 5;
               if(tmp_nri > NRI)
                  NRI = tmp_nri;
            }
            else
               break;

            ++nal_cnt;
         }

         // Only use STAP-A when we found more than one NAL units
         if(nal_cnt > 1)
         {
            unsigned int i;

            // Init STAP-A NAL header (F+NRI+TYPE)
            p = nal[0] - HEADER_SIZE_STAP_A;
            *p++ = (NRI << 5) | TYPE_STAP_A;

            // Append all populated NAL units into payload (SIZE+NAL)
            for(i = 0; i < nal_cnt; ++i) {
               // Put size (2 octets in network order)
               *p++ = (u8)(nal_size[i] >> 8);
               *p++ = (u8)(nal_size[i] & 0xFF);

               // Append NAL unit, watchout memmove()-ing bitstream!
               if(p != nal[i])
                  memmove(p, nal[i], nal_size[i]);
               p += nal_size[i];
            }

            // 
            u8* payload = nal[0] - HEADER_SIZE_STAP_A;
            l_u32Size = p - payload;
            memcpy(out_data, payload, l_u32Size);
            *out_size = l_u32Size;
            return (u32)(nal[nal_cnt - 1] + nal_size[nal_cnt - 1] - data_buf);;
         }
      }
   }
   
   // Single NAL unit packet
   l_u32Size = nal_end - nal_start;
   memcpy(out_data, nal_start, l_u32Size);
   *out_size = l_u32Size;
   return (u32)(nal_end - data_buf);
}
```

- Флаги и настройки контекста h264

Для работы кодека h264 опытным путем добыты дополнительные настройки. Без этих флагов изображение течет и ломается.

```cpp

AVCodecContext* m_decoder_context;
AVCodecContext* m_encoder_context;

AVCodecID codec_id = AV_CODEC_ID_H264;
int bitrate = 90000;
int w = 352;
int h = 288;
decoder = avcodec_find_decoder(codec_id);
encoder = avcodec_find_encoder(codec_id);

InitContext(&m_decoder_context, decoder, bitrate, w, h);
InitContext(&m_encoder_context, encoder, bitrate, w, h);

if(m_decoder_context)
{
    if(codec_id == AV_CODEC_ID_H264)
    {
        m_decoder_context->flags |= CODEC_FLAG_UNALIGNED;       // обрабатывает невыровнянные кадры
                
        if(decoder->capabilities & CODEC_CAP_TRUNCATED)         // обрабатывает "битые" кадры
            m_decoder_context->flags |= CODEC_FLAG_TRUNCATED;

        m_decoder_context->time_base= av_make_q(1, bitrate);     
    }
}

if(m_encoder_context)
{
    int level = 13;
    m_encoder_context->time_base= av_make_q(1, FPS);      // фпс
    m_encoder_context->gop_size = 10;                     // частота опорных кадров
    
    if(codec_id == AV_CODEC_ID_H264)
    {
        m_encoder_context->max_b_frames = 0;            // не отправлять B фреймы
        m_encoder_context->level = level;               // уровень качества
        m_encoder_context->refs = 1;                    // количество кадров "ссылок"
        m_encoder_context->thread_count = 0;            // количество потоков для кодирования. можно увеличить выставив thread_type
        //m_encoder_context->thread_type = FF_THREAD_SLICE;

        // https://ru.wikipedia.org/wiki/H.264
        added = av_opt_set(m_encoder_context->priv_data, "profile", "baseline", 0);      // профиль базовый для мобильных устройств
        added = av_opt_set(m_encoder_context->priv_data, "preset", "fast", 0);           // скорость кодирования. обратна пропорциональна качеству
        added = av_opt_set(m_encoder_context->priv_data, "tune", "zerolatency", 0);      // минимальная задержка. обязательно для sip 
    }
}
```

Также могут быть проблемы с размером буфера на UDP сокете. Если размер фрейма большой, то при получении по UDP весь фрейм может не поместиться в системный буфер и часть пакетов будут сброшены.
При этом изображение будет искажаться.
```cpp
int val = 65535;
if(setsockopt(socket, SOL_SOCKET, SO_RCVBUF, (const char*)&val, sizeof(val)) != SOCKET_ERROR)
    status = true;
```

<!-- ## Выводы -->


## Ссылки
1. [pjsip](https://github.com/pjsip/pjproject){:target="_blank"}
2. [linphone](https://github.com/BelledonneCommunications/linphone){:target="_blank"}

---
<div class="scroller">
<script id="journalist-broadcast-1339301542" async src="https://journali.st/broadcasts/1339301542-widget-10.js"></script>
</div>
---
<p class="center" align="center"><a href="https://t.me/joinchat/CgpznA-nVf4YYX44zBkupQ" target="_blank">Оставить комментарий через Telegram</a></p>