---
layout: post
published: true
title: Шпаргалка по openssl/openssh/putty
---

Систематизируем знания по созданию и конвертации ключей при использовании различных инструментов.

------
*Требуется сгенерировать ключ для доступа по ssh. Всегда нахожу разные способы их сгенерировать и постоянно забываю чем они отличаются.*

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

x509 - [стандарт](https://ru.wikipedia.org/wiki/X.509).

rsa - [алгоритм](https://ru.wikipedia.org/wiki/RSA).

2048 - [длина ключа](https://ru.wikipedia.org/wiki/Ключ_(криптография)).

365 - время действия в днях.

~~Нужен для генерации сертификатов сайтов. Для ssh бесполезен.~~

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

По-умолчанию генерирует файлы `~/.ssh/id_rsa` и `~/.ssh/id_rsa.pub`. Ключ **-f** позволяет указать выходную папку и имя.

SHA256 - [цифровая подпись](https://ru.wikipedia.org/wiki/SHA-2)

### puttygen

Не установлен в систему в отличии от предыдущих. Установка:

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

Каталог со всеми сгенерированными ключами:

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
            -----BEGIN CERTIFICATE-----
            MIIDXTCCAkWgAwIBAgIJAOLR38z/XBbcMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
            BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
            aWRnaXRzIFB0eSBMdGQwHhcNMTgwMzI3MTAzMzAwWhcNMTkwMzI3MTAzMzAwWjBF
            MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
            ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
            CgKCAQEAx6QribExQCj56L5ME6hhZat60DehQ+3v4/84d8/9yPbVBdQm6/DMIk0g
            vpToGxqgZHbL2LuFpu8oF7Z2W+BExWwpZ6uLpahFVQ7WapNJDs2y8LwLQ9eB/HID
            IlTiafW31vG/RTz8mrRJDBj6D1tDEKCXO0ioOi1WW7hxsZjts6nzDOGordubmlpg
            CT6eR1t4/kQbFE6kvq0fqWHd81jFMhCoCok65o2Vc2GbFf4ol+/EcHbXVXVUOuu5
            MxKWcNkcd0QQqCZWddUIPTbHlCCHJRDlovBZ62cMcEMAGujH1u0CXu8RAlZfCBpO
            8DB8AhuLxXbTlPhkAyeTDwG/DJpD3QIDAQABo1AwTjAdBgNVHQ4EFgQUsrXkYnag
            ioktq8uY3FzCASCbFSUwHwYDVR0jBBgwFoAUsrXkYnagioktq8uY3FzCASCbFSUw
            DAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAJNsV75qsLTN5lFjevUTm
            q4BCvvY89t7l1ck0CuCws/JIP5F/Hp6rjthf50HQZaLyv6q058KUsA1jfU9/yo1O
            O4qLl+tNCLUGn6h/ielMf3yuPGToMn9FlFIoMv/LPBAKC4JRG3ftxnC3AKFaDATU
            tg3/IgKC6H6+TnCG65wGHXO0oS6ke8VD/uOQ4B5uzShOLqUdDXIMrcpcO7UcyeNv
            ZhrkN90LnVi5FVFo58h1TUpoapkfTr72UQ+DcF4Oj2GvHSuMT5OnBZEvu/U1tUGs
            jCxx+JzumByKk59sXUd1/8QDBZNPRlEuAlpb5Gz6pwXq1r5Ru5+1Tqscxkb3jTne
            SA==
            -----END CERTIFICATE-----
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
            ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4vf1NReESnbYBW7OSKQgE4WI6ZLoKXhQNfcC+eHxmFXXv8E8wYB/0KaKG9yhouDeX+uFeM6XA09lhF8Ju6B8AGsB+ZAc8hQyEHm8ryywAJ+CQAadcpy0w1gf43yLPnUwKhn59WagFMM+Wj60k2jOFAPxnXBqQINkLqqWwUx8otqPgWFOZ5fLt55aT6BjupoUqFZeeeooKH/B+W7GrEteqgjalAVTuRPwCmHfFlINjGweqEbK5vsPzBikrUoO0MuYV9Sj3Vv/XBE96RWz1qrxzLrSrC44+ZsTKgskYuxLs7OBo1ywm+0PHvfty0u9HccIm9mJ7LxKj5xcDmknMCTpb TECHRUMAIN@TECHRUMAIN-PC
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
            ---- BEGIN SSH2 PUBLIC KEY ----
            Comment: "rsa-key-20180326"
            AAAAB3NzaC1yc2EAAAABJQAAAQEA50+HtIazHOMaAcL6mxy/6uewc2SYGt1EMRAQ
            1J70l7PXyJbmKEjqfCh4EuFWAT6bCz3X01JIaoQXpZXTziPkGvKi4GEdTsELBbHm
            xyuCnfidkBf/OryGGmKkR6xkeNZXlx2Cn3pw/p63ApJ0k2f7xg7cJgWZUElBQMsr
            nTsEWvjwUZg/IfIFQEnDRgrBBsr50Rp5EsZiDsYmXCtY6of8G31EUag3FNMeL7nm
            mCKVwbe7w8+G9P1WPEIDuYPQyEe1vMZBgV/YnLWSEOgYhH1UpeH517s+H89tFj14
            KzUcJPsv362bhbAYCJHwXZ+WW3Vlbi7+bmPc2PnTAR4Hi9EoyQ==
            ---- END SSH2 PUBLIC KEY ----
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
            -----BEGIN ENCRYPTED PRIVATE KEY-----
            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
            81c=
            -----END ENCRYPTED PRIVATE KEY-----
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
            -----BEGIN RSA PRIVATE KEY-----
            Proc-Type: 4,ENCRYPTED
            DEK-Info: AES-128-CBC,995042B2BD09CBF0EEFB8880F3A26548

            FZ/uxWAb58oEjXdbBvYSUwUgpITYxHdhiStyM531MVyV59xyBCZWm2b5lGRPyMTi
            4tySmqTkALa4Ql3x0/pXb7JECfhEM+QhdWrQIcVu/lNNq+hWRORS1D3qL6g7acrE
            bTc/UnTu1CuVzYchASKDpYFVnP1vkuxmqWs3Q3v73JBi2nN99QxAtSLa8icAlPyD
            b72s8FIKB0TvRveguf4IAek2In2snpjuOZGJvpXkRfmEk3T+gGPCS2ylXIjVfCFD
            Z/vulucNRkXpTQbl70D/1GOILb4oG93dVRhLPAAcvRTCuTtQXsUOijOw5cN/ruF2
            2sgjbC5j7gEcUabf62RR9mV4KCT4lFwaDJJVS1q5SGl/W0ie+sSinrh1U/Zq58gR
            IbjYcibCTm/OyAbXZxT5l+R0G83PLva/dKI0bjx/lTmuFCGlLZ1VxUQHKWSkVSfr
            dP125mN/lCJYYh3bPFgnyNrunr1f+roQdwpLB3kMh7CdMZc/jL/gKdwEfmegtBlV
            fm/GhEQhjlDdeJIoLuu45cmqJgv8jTdDHRwZiJE4ovxP1ak+/aGuTnP7KuOlRLD8
            d7Oex8AWDLuE/jt9WorKmObgi/xoWWxPvsB4LbMjoRSbKC5aJdVRRzST6UU5AubZ
            nqJTfCQkFagft7yRgH4v4keA1Q6qhpBLApPObqSmat010C+FKuQKS0KvV5wlPxbX
            QVJvE4yat4fB5Ght4XbL9Cn4BR4TSWn1Dhlgy+zFzknfV9Zyx8bkbmERtdKrHT4G
            QN5Ch1LJOZ0jqrAu2zR+vi13NbghXrJd2I50BMWv1+Cu3K+GTnhysJ2WpiC6UnlO
            8n3ggtshu593VqvvCggMA8Uh1T0eVvQ8b4x+uQq8V1urhj4Tc+XZS18VBlLQXf6d
            6hpxyvMkw97PvaIdmmmwn1rDlYH25Z1sKMCCCrAmLUiukRsVwFUOYpkRu7kjR4jo
            rxBvBUgLvBvIY2NOpPnRkFvZRSyQYpW3rI/YF6bVWUU3mz7XJPwZHb9De29giL92
            h1JQycgO/8ItyXzIDIuHaSKibM5EIkIQDwHbC9jDxIb4lhoz54A5mZHVyHe+1tnU
            N2Tpj4lj2Vbyux5h9AuPd8Z8DOzVpTuMVirO9/EIkhCzBF8zpVqHkvzR5qfuY1iO
            LPE/tBm3jx756/kGSYnN1CwZPf3V96dVQzsgPkXSlPiz6ClDg3fmd+zqyCBI8PcA
            B/kxnjVhcfxPSZcmgwy6yVqvqIW+EDPycDeExuxtci/siP+/o+KMs/C6UH9PwFHe
            T5l3CJ3BbfZIEzhWhNzTVAyetWPwXjaUAEXUN+liRJv0qdGXOatXP//4KxuKjCRV
            CsjED8QuMLlALZbBM0hy9w+Ms4fbANB2AmJPoRmgXIUURAD7s3gjLlCyfpMo75/Y
            QX5JPyKgPbNxf7NT9GJXXgJpKeBGECEvCpqn0H/6lEKlnTw0fun/zaiYR3YQ/src
            8yc/G8JZyEVMtEc7DBQkjso/zOIjrAUzTr0kmXUF8ie8/4mjxCbGuSed/aHpvDLX
            MqfF1dWOSxtjGXOL3vSrnlX0OE3nD9W90IoVAvH7qkEf+XGtVIBbZF307aY/lPIz
            -----END RSA PRIVATE KEY-----
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
            PuTTY-User-Key-File-2: ssh-rsa
            Encryption: aes256-cbc
            Comment: rsa-key-20180326
            Public-Lines: 6
            AAAAB3NzaC1yc2EAAAABJQAAAQEA50+HtIazHOMaAcL6mxy/6uewc2SYGt1EMRAQ
            1J70l7PXyJbmKEjqfCh4EuFWAT6bCz3X01JIaoQXpZXTziPkGvKi4GEdTsELBbHm
            xyuCnfidkBf/OryGGmKkR6xkeNZXlx2Cn3pw/p63ApJ0k2f7xg7cJgWZUElBQMsr
            nTsEWvjwUZg/IfIFQEnDRgrBBsr50Rp5EsZiDsYmXCtY6of8G31EUag3FNMeL7nm
            mCKVwbe7w8+G9P1WPEIDuYPQyEe1vMZBgV/YnLWSEOgYhH1UpeH517s+H89tFj14
            KzUcJPsv362bhbAYCJHwXZ+WW3Vlbi7+bmPc2PnTAR4Hi9EoyQ==
            Private-Lines: 14
            XwyAR+efYjhDLZUdSwRExVKzacLMg5wwywvTndwUPh3WeqXcCujtWIrKFH3SpSEH
            iIUIt9AurgPmyBx5sGX9DBS3QaIFhG0ZIc3TZOA+E5BQO+C2m0/iKztSSbLUsDsn
            HGlD3b+3N3SPRorkkg3x0wOMYdAATBBizEp4Sz9/N8CCHwtBCB5/+MqWOVGx48D7
            J1sWOnh190qJn75ry+eBFgzTsQDLAyVfp0zUcjtnJHrVXtoylPR4Bhp42B+uomm4
            CBhTnbeH9v+6j+YsRlTMJ7Hj0auFH6v7mTeQ+LAhJd66pdawNr56YASW76N1BWuX
            b+g0KS/h7W8JAzcDYhzVLP9zXZ+5W2ki7lNv5SKwJ23ssTzZjGlQIZwbxMotWmOL
            I6KS0WwTeauMwvgYetizXKqcT9pKKzmYpwP9RaM/5eT4SH5UzmASJDWe/rW72Jb5
            Ov3nWsSPsS/Gi6ttNYhRnV0djAG+cR/3OrQYwuFSeyD1U/uH9PkinQQjOwjuPjvK
            NdhVWmcRqO53D2pADs8//ZubbonCERwqkeXpDI0ewduqVb3lWJYrvm1RvV5NuHHC
            vUoyxLO8h8bMcFow3/meYPN2+MpYFRxavG33zwi8dtufH0ZgUBmZ24NusDEe0qKd
            QQiUeiCcrfqwEWYdITSVCZyE8XKkyMuAsdsWdn/59bTJK0C6HtQjjEzTRbliwH26
            3aR1u0fftdIFZwHN8drsvJhehBG0WbiwpWVgyx5yK08+2aqJD9rAD+JBweO8ARiZ
            dE4Wn/sqMfCZbpkZnyG0iOkvGkiskN+LQU6XoOzOqacHsf2Q7qtpLgn6zWYCJfLI
            car9Ln6mVKCsWrgU/uiiX9tVCnX1QD6bIAyQgIFV5Z8gzX7aXLt8PhSqO1K+6MVE
            Private-MAC: 7673f1a69909796dbfe24cd8960ca7bf83c6f453
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

## Инструкция для Windows

Самым простым и распрастраненным вариантом является [Putty](https://www.putty.org/), а точнее puttygen. 

Также можно использовать порты Unix приложений, например в [MSYS2](https://www.msys2.org/).

Запускаем puttygen.exe, жмем **Generate**. Водим мышкой для генерации случайно последовательности.

![puttygen]({{"/assets/puttygen.png" | absolute_url}})

Вводим, если нужно, пароль для сертификата и сохраняем ключи. Также можно сохранить ключ в формате openssh через **Conversions -> Export OpenSSH Key**.

![generated]({{"/assets/generated.png" | absolute_url}})

Из сохраненного .ppk файла всегда можно извлечь всю информацию, загрузив его в puttygen.

## Выводы
1. openssl совсем не нужен, как и все примеры с его использованием для генерации ssh ключей.
2. ssh-keygen сохраняет публичный ключ в формате **authorized_keys** файла, puttygen сохраняет по [RFC 4716](https://tools.ietf.org/html/rfc4716#section-3).
3. Linux - ssh-keygen, Windows - puttygen.exe.

## Ссылки
1. [Linux puttygen](https://www.ssh.com/ssh/putty/linux/puttygen)
2. [Git ssh keys](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux)
3. [win ssh invalid format](https://stackoverflow.com/questions/42863913/key-load-public-invalid-format)