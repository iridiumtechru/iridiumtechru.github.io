---
layout: post
published: true
title: Как сгенерировать сертификаты (openssl/openssh/putty)
---

Систематизируем знания по созданию и конвертации ключей при использовании различных инструментов.

------
*Требуется сгенерировать ключ для доступа по ssh. Всегда нахожу разные способы их сгенерировать и постоянно забываю чем они отличаются.*

Шпаргалка по `openssl openssh и putty`.

## Инструкция для Linux

### openssl

<details>
    <summary>
        <code class="highlighter-rouge">
            openssl req -x509 -newkey rsa:2048 -keyout openssl-key.pem -out openssl.pub -days 365
        </code>
    </summary>
    <pre class="highlight">
        <code>
            Generating a 2048 bit RSA private key...............+++
            ..........................................+++
            writing new private key to 'openssl-key.pem'
            Enter PEM pass phrase:
            Verifying - Enter PEM pass phrase:
            -----
            You are about to be asked to enter information that will be incorporated
            into your certificate request.What you are about to enter is what is called a Distinguished Name or a DN.There are quite a few fields but you can leave some blankFor some fields there will be a default value,
            If you enter '.', the field will be left blank.
            -----
            Country Name (2 letter code) [AU]:
            State or Province Name (full name) [Some-State]:
            Locality Name (eg, city) []:
            Organization Name (eg, company) [Internet Widgits Pty Ltd]:
            Organizational Unit Name (eg, section) []:
            Common Name (e.g. server FQDN or YOUR name) []:
            Email Address []:
        </code>
    </pre>
</details>

~~Нужен для генерации сертификатов сайтов.~~

### ssh-keygen

<details>
    <summary>
        <code class="highlighter-rouge">
            ssh-keygen -f ssh-key
        </code>
    </summary>
    <pre class="highlight">
        <code>
            Enter passphrase (empty for no passphrase):
            Enter same passphrase again:
            Your identification has been saved in ./ssh-key.
            Your public key has been saved in ./ssh-key.pub.
            The key fingerprint is:
            SHA256:Aexx4t1BfpFvMkPaOrhBPjt7n7qkNHh6clfkm53eEpg techru@techru-GA-770TA-UD3
            The key's randomart image is:
            +---[RSA 2048]----+
            |     ..  .. ..   |
            |      +.... o.   |
            |     o =...=..   |
            |      o o.o.* o  |
            |       oS. + B   |
            |       .= o E .  |
            |      . +=.o + o |
            |      .+*+o o.+. |
            |      .+o=o+o....|
            +----[SHA256]-----+
        </code>
    </pre>
</details>
По-умолчанию генерирует файлы `~/.ssh/id_rsa` и `~/.ssh/id_rsa.pub`

Я сгенерировал в текущую папку с именем **ssh-key**

### puttygen

Для начал установим его

```sudo apt install putty-tools```

Генерируем приватный ключ(очень долго):

<details>
    <summary>
        <code class="highlighter-rouge">
            puttygen -t rsa -b 2048 -C "email@host.com" -o putty-key.ppk
        </code>
    </summary>
    <pre class="highlight">
        <code>
            ++++++++++++++++++++++++++++++++++
            ++++
            +++++
            Enter passphrase to save key:
            Re-enter passphrase to verify:
        </code>
    </pre>
</details>

И генерируем из него публичный:

`puttygen -L putty-key.ppk > putty-key.pub`

Я генерировал всё в один каталог. Его содержимое:

```bash
-rw-rw-r-- techru 1834 openssl-key.pem
-rw-rw-r-- techru 1229 openssl.pub
-rw------- techru 1766 ssh-key
-rw-r--r-- techru  408 ssh-key.pub
-rw------- techru 1454 putty-key.ppk
-rw-rw-r-- techru  396 putty-key.pub
```

Каждый ключ состоит из публичной и приватной части.

### Pub Keys
<details>
    <summary>
        <code class="highlighter-rouge">
            openssl
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

<details>
    <summary>
        <code class="highlighter-rouge">
            openssh
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

<details>
    <summary>
        <code class="highlighter-rouge">
            puttygen
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

### Private Keys
<details>
    <summary>
        <code class="highlighter-rouge">
            openssl
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

<details>
    <summary>
        <code class="highlighter-rouge">
            openssh
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

<details>
    <summary>
        <code class="highlighter-rouge">
            puttygen
        </code>
    </summary>
    <pre class="highlight">
        <code>

        </code>
    </pre>
</details>

## Экстракция и конвертация

Приватный в публичный.

* openssl

* openssh

* puttygen

Конвертировать уже имеющийся ключ.

1. openssl -> openssh

2. openssl -> putty

3. openssh -> openssl

4. openssh -> putty

5. putty -> openssl

6. putty -> openssh

## Выводы

## Ссылки
1. [Linux puttygen](https://www.ssh.com/ssh/putty/linux/puttygen)
2. [Git ssh keys](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux)
3. [win ssh invalid format](https://stackoverflow.com/questions/42863913/key-load-public-invalid-format)