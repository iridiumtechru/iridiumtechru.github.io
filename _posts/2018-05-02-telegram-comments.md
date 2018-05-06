---
layout: post
published: true
title: Комментарии в Jekyll блоге с использованием Telegram
---

Ленивый способ встроить комментарии в блог.

*После [создания]({{ site.url }}{% post_url 2018-03-25-begining %}) блога я успокоился и начал потихоньку писать тексты. Всё работает: не надо разворачивать допиливать напильником, подключать базы, разбираться в шаблонах или даже учить Ruby. Единственнное что меня коробило это отсутствие встроенных комментариев и я потихонечку собирал информацию. Вариантов несколько и они делятся на три группы: использовать свой хостинг, использовать сам github, использовать сервис сторонний. Первый вариант отпадает из-за отсутствия хостинга и желания его содержать. Второй вариант требует разрешения на коммит в репозиторий, либо использование issues в git-репозитории. Третий вариант мне подходит, но платить за использование я не хочу и слишком сложная настройка меня отталкивает. Появилась идея использовать Telegram для хранения комментариев, а отображать через Telegram API.*

### Настраиваем бота.

1. Добавляем бота [Journalist](https://telegram.me/JournalistBot){:target="_blank"}.
2. Создаем трансляцию у бота для нужного поста.
![New]({{"/assets/newtrans.png" | absolute_url}})
3. Получаем код для вставки виджета трансляции на сайт:
```<script id="journalist-broadcast-2075375252" async src="https://journali.st/broadcasts/2075375252-widget-4.js"></script>```
widget-4.js - означает количество постов в виджете.
4. Заходим в настройки бота: включаем автоматическую публикацию и создаем ключ приглашения.
![key]({{"/assets/transkey.png" | absolute_url}})
5. Создаем группу в Telegram и добавляем в эту группу бота. Пишем сообщением в группе ключ приглашения формата ```/join f184062899a8e6461bb6f9a19be8d8cf```. Бот ответит названием трансляции. Теперь все сообщения из группы будут пересылаться боту и будут видны по ссылкам трансляции.
6. Вставляем виджет трансляции в пост.
![key]({{"/assets/transwidget.png" | absolute_url}})
7. Добавляем публичную ссылку на группу для возможности оставлять комментарии.
8. Меняем css для соответствия виджета общему стилю блога. Используем свойство *!important*.

```css
.journalist-broadcast.journalist-broadcast-widget
{
  width: 100% !important;
  max-width: 100% !important;
  border: none !important;
}

.journalist-broadcast-header
{
  background-color: transparent !important;
}

.journalist-broadcast-post
{
  background-color: transparent !important;
}

.journalist-broadcast-post-info-author
{
  color: #895210 !important;
}

.journalist-broadcast-post-message-text
{
  color: #b5e853 !important;
}
```

## Выводы
#### Преимущества
1. Очень быстрое развертывание.
2. Не требуется ресурсов на содержание. Авторизация и хранение осуществляется через Telegram.
3. Каждая тема связана с отдельной группой и решается проблема с уведомлениями и управлением.

#### Недостатки
1. Есть зависимость от Telegram и Journalist. Бот в бете и если он отвалится всё останется в группах. Надеюсь Роскомнадзор не победит.
2. Нет возможности редактировать или удалять сообщения.
3. Нельзя оставить сообщения с формы, приходится заходить в Telegram. Возможно подключу еще бота или напишу его сам.
4. Нет автоматизации для интеграции в каждый пост. Нужно создавать группу, трансляцию, приглашать бота каждый пост.

## Ссылки
1. [Вдохновивший меня пост на хабре](https://habr.com/post/354642/){:target="_blank"}
2. [journali.st](https://journali.st/){:target="_blank"}

---
<div class="scroller">
<script id="journalist-broadcast-2075375252" async defer src="https://journali.st/broadcasts/2075375252-widget-10.js"></script>
</div>
---
<p class="center" align="center"><a href="https://t.me/joinchat/CgpznA8XI19iYApW9JWARw" target="_blank">Оставить комментарий через Telegram</a></p>

<!--

<div class="comment">
<div class="textarea" tabindex="0" role="textbox" aria-multiline="true" contenteditable="PLAINTEXT-ONLY" data-role="editable" aria-label="Start the discussion…" style="overflow: auto; word-wrap: break-word; max-height: 350px;"></div>
</div>

<div style="overflow:auto; height:400px;">

</div>
2123331793
-->