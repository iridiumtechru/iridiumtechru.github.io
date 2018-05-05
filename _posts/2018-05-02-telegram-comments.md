---
layout: post
published: false
title: Комментарии в Jekyll блоге с использованием Telegram
---

Ленивый способ встроить комментарии в блог.

*После [создания]({{ site.url }}{% post_url 2018-03-25-begining %}) блога я успокоился и начал потихоньку писать тексты. Всё работает: не надо разворачивать допиливать напильником, подключать базы, разбираться в шаблонах или даже учить Ruby. Единственнное что меня коробило это отсутствие встроенных комментариев и я потихонечку собирал информацию. Вариантов несколько и они делятся на три группы: использовать свой хостинг, использовать сам github, использовать сервис сторонний. Первый вариант отпадает из-за отсутствия хостинга и желания его содержать. Второй вариант требует разрешения на коммит в репозиторий, либо использование issues в git-репозитории. Третий вариант мне подходит, но платить за использование я не хочу и слишком сложная настройка меня отталкивает. Появилась идея использовать Telegram для хранения комментариев, а отображать через Telegram API.*

## Ссылки
1. [Вдохновивший меня пост на хабре](https://habr.com/post/354642/){:target="_blank"}
2. [journali.st](https://journali.st/){:target="_blank"}

<!--
<div class="comment">
<div class="textarea" tabindex="0" role="textbox" aria-multiline="true" contenteditable="PLAINTEXT-ONLY" data-role="editable" aria-label="Start the discussion…" style="overflow: auto; word-wrap: break-word; max-height: 350px;"></div>
</div>

<div style="overflow:auto; height:400px;">

</div>
-->

---

<div class="scroller">
<script id="journalist-broadcast-2123331793" async defer src="https://journali.st/broadcasts/2123331793-widget-10.js"></script>
</div>

---

<p class="center" align="center"><a href="https://t.me/joinchat/CgpznBAozvfWN_qQ-ekl_g" target="_blank">Оставить комментарий через Telegram</a></p>